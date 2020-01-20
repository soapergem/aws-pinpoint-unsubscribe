import boto3
from boto3.dynamodb.conditions import Attr

# set this to something if you want to use a profile
AWS_PROFILE_NAME = None
AWS_REGION = "us-east-1"


def get_dynamo_client():
    session = boto3.Session(profile_name=AWS_PROFILE_NAME, region_name=AWS_REGION)
    client = session.client("dynamodb")
    return client


def get_dynamo_resource():
    session = boto3.Session(profile_name=AWS_PROFILE_NAME, region_name=AWS_REGION)
    resource = session.resource("dynamodb")
    return resource


def import_and_create_segment(app_id, segment_name, role_arn, s3_url):
    session = boto3.Session(profile_name=AWS_PROFILE_NAME, region_name=AWS_REGION)
    client = session.client("pinpoint")
    response = client.create_import_job(
        ApplicationId=app_id,
        ImportJobRequest={
            "DefineSegment": True,
            "Format": "CSV",
            "RegisterEndpoints": True,
            "RoleArn": role_arn,
            "S3Url": s3_url,
            "SegmentName": segment_name,
        },
    )
    return response.get("ImportJobResponse", {}).get("Id")


def get_opt_outs_from_dynamo(resource, table_name):
    table = resource.Table(table_name)
    response = table.scan(
        ProjectionExpression="email_address",
        FilterExpression=Attr("unsubscribe").eq(True),
    )

    count = response.get("Count")
    start_key = response.get("LastEvaluatedKey")
    opt_outs = [x.get("email_address") for x in response.get("Items")]

    while count > 0 and start_key:

        response = table.scan(
            ProjectionExpression="email_address",
            FilterExpression=Attr("unsubscribe").eq(True),
            ExclusiveStartKey=start_key,
        )

        count = response.get("Count")
        start_key = response.get("LastEvaluatedKey")
        opt_outs += [x.get("email_address") for x in response.get("Items")]

    return opt_outs


def insert_batch_to_dynamo(client, table_name, batch):
    response = client.batch_write_item(
        RequestItems={table_name: [_get_dynamo_item(x) for x in batch]}
    )
    return response


def upload_file_to_s3(filepath, bucket, key):
    session = boto3.Session(profile_name=AWS_PROFILE_NAME, region_name=AWS_REGION)
    client = session.client("s3")
    response = client.upload_file(str(filepath), bucket, key)
    return response


def _get_dynamo_item(entry):
    # required fields
    request = {
        "PutRequest": {
            "Item": {
                "email_address": {"S": entry.pop("email_address")},
                "email_hash": {"S": entry.pop("email_hash")},
            }
        }
    }

    # add in optional attributes as well
    for key, value in entry.items():
        if value:
            request["PutRequest"]["Item"][key] = {"S": str(value)}

    return request
