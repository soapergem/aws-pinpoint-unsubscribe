#!/usr/bin/env python
import click
import csv
from pathlib import Path
from tqdm import tqdm
from importer.hash import to_hash
from importer.aws import (
    get_dynamo_client,
    import_and_create_segment,
    insert_batch_to_dynamo,
    upload_file_to_s3,
)

MAX_DYNAMODB_BATCH_SIZE = 25


@click.command()
@click.argument("csv-file")
@click.option("--app-id", required=True, help="Pinpoint Application ID")
@click.option("--dynamo-table", required=True, help="DynamoDB Table Name")
@click.option("--role-arn", required=True, help="IAM Role for Pinpoint")
@click.option("--segment-name", required=True, help="Pinpoint Segment Name")
@click.option("--s3-bucket", required=True, help="S3 Bucket Name")
def import_csv_file(csv_file, app_id, dynamo_table, role_arn, segment_name, s3_bucket):
    """
    Import a CSV file of contacts into both a Dynamo Table and a Pinpoint Segment.
    This will convert your CSV file into the format the Pinpoint expects, generating
    unique hashes based on email addresses as the primary key. That converted CSV
    file is uploaded to an S3 bucket so that it can be imported by Pinpoint.
    """

    csv_path = Path(csv_file).resolve()
    converted_file = csv_path.parent / (csv_path.stem + ".converted" + csv_path.suffix)

    batch = []
    dynamodb = get_dynamo_client()

    with open(csv_path, "r") as in_file:
        with open(converted_file, "w") as out_file:
            csv_reader = csv.DictReader(in_file)
            csv_writer = csv.writer(out_file)

            # write the header row to our converted file
            csv_writer.writerow(
                [
                    "ChannelType",
                    "Address",
                    "Location.Country",
                    "User.UserAttributes.FirstName",
                    "User.UserAttributes.MiddleName",
                    "User.UserAttributes.LastName",
                    "User.UserId",
                ]
            )

            # loop through the input, showing a progress bar
            for row in tqdm(csv_reader):

                # these are the column headings we're looking for
                email = row.get("Email")
                fname = row.get("First Name")
                mname = row.get("Middle Name")
                lname = row.get("Last Name")

                # optional: fix some formatting issues around middle/last names
                if not mname and " " in lname:
                    components = tuple(filter(None, lname.split(" ", 1)))
                    mname = components[0]
                    lname = components[1]

                # generate a unique hash based on the email
                user_id = to_hash(email)

                # only add this to our segment if the email address is not blank
                if email:

                    # write out to our CSV file
                    csv_writer.writerow(
                        ["EMAIL", email, "USA", fname, mname, lname, user_id]
                    )

                    # add it to our dynamo table as well
                    batch.append(
                        {
                            "email_address": email,
                            "email_hash": user_id,
                            "fname": fname,
                            "mname": mname,
                            "lname": lname,
                        }
                    )

                # insert records in batches
                if len(batch) >= MAX_DYNAMODB_BATCH_SIZE:
                    insert_batch_to_dynamo(dynamodb, dynamo_table, batch)
                    batch = []

            # insert any leftovers into dynamo
            if batch:
                insert_batch_to_dynamo(dynamodb, dynamo_table, batch)

    # upload our converted file to S3
    upload_file_to_s3(converted_file, s3_bucket, converted_file.name)

    # and start the import job in Pinpoint
    s3_url = f"s3://{s3_bucket}/{converted_file.name}"
    import_id = import_and_create_segment(app_id, segment_name, role_arn, s3_url)
    click.echo(f"Pinpoint Segment Import ID: {import_id}")


if __name__ == "__main__":
    import_csv_file()
