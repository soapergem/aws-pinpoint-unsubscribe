import boto3
import logging
import json
import os
import re
from boto3.dynamodb.conditions import Key
from datetime import datetime
from dateutil import tz

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logging.basicConfig()

HTML_NO_HASH = """<html>
<head>
<title>Unsubscribe Successful</title>
</head>
<body>
<h1>Unsubscribe Successful</h1>
<p>You have been removed from all of our lists. Please allow 24 to 48 hours for this to take effect. We apologize for any inconvenience.</p>
</body>
</html>"""

HTML_FIRST_TIME = """<html>
<head>
<title>Unsubscribe Successful</title>
</head>
<body>
<h1>Unsubscribe Successful</h1>
<p>You have been removed from all of our lists. We will no longer send any correspondence to your address, %s. Please allow 24 to 48 hours for this to take effect. We apologize for any inconvenience.</p>
</body>
</html>
"""

HTML_SECOND_TIME = """<html>
<head>
<title>Unsubscribe Successful</title>
</head>
<body>
<h1>Unsubscribe Successful</h1>
<p>Okay, we get it. You really don't want email from us! This is confirmation that you already unsubscribed from us on %s. We will <u>definitely</u> no longer send any correspondence to your address, %s! We apologize for any inconvenience.</p>
</body>
</html>
"""


def ord_suffix(n):
    return "th" if 4 <= n % 100 <= 20 else {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")


def lambda_handler(event, context):

    hash_id = event.get("hash_id")
    if not hash_id:
        html = HTML_NO_HASH
        logger.warning("No hash specified")
    else:
        table_name = os.getenv("TABLE_NAME")
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table(table_name)

        index_name = os.getenv("INDEX_NAME")
        response = table.query(
            IndexName=index_name,
            Select="ALL_ATTRIBUTES",
            KeyConditionExpression=Key("email_hash").eq(hash_id),
        )

        count = response.get("Count")
        if not count:
            html = HTML_NO_HASH
            logger.warning(f"Hash {hash_id} not found in table")
        else:
            item = response.get("Items")[0]
            email = item.get("email_address")
            masked = re.sub("(?!^).(?=[^@]+@)", "*", email)
            unsubscribe = item.get("unsubscribe")
            unsubscribed_at = item.get("unsubscribed_at")
            if unsubscribe:
                unsub_date = datetime.strptime(unsubscribed_at, "%Y-%m-%dT%H:%M:%S.%fZ")
                unsub_date = unsub_date.replace(tzinfo=tz.tzutc())
                unsub_date = unsub_date.astimezone(tz.gettz("America/Chicago"))
                day_of_month = int(unsub_date.strftime("%-d"))
                suffix = ord_suffix(day_of_month)
                unsub_date = unsub_date.strftime(f"%b. %-d{suffix} at %-I:%M %p")
                html = HTML_SECOND_TIME % (unsub_date, masked)
                logger.info(f"Multiple unsubs for {email}")
            else:
                html = HTML_FIRST_TIME % (masked,)
                logger.info(f"First unsub for {email}")
                response = table.update_item(
                    Key={"email_address": email,},
                    AttributeUpdates={
                        "unsubscribe": {"Value": True, "Action": "PUT",},
                        "unsubscribed_at": {
                            "Value": datetime.utcnow().strftime(
                                "%Y-%m-%dT%H:%M:%S.%fZ"
                            ),
                            "Action": "PUT",
                        },
                    },
                )
    return {"body": html}
