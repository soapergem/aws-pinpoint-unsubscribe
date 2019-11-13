# aws-pinpoint-unsubscribe
A simple serverless API for handling unsubscribes with AWS Pinpoint.

## Installation

Run the Terraform scripts first. This will print various outputs that you will need
to feed into the Python script.

Once the Terraform has been run, install the pip dependencies specified in requirements.txt
to your virtual environment (e.g. `pip install -r requirements.txt`). Then invoke the Python
script with the following arguments and required options:

```bash
./main.py PATH_TO_YOUR_CSV_FILE.csv
    --app-id PINPOINT_APPLICATION_ID
    --dynamo-table DYNAMO_TABLE_NAME
    --role-name IAM_ROLE_NAME
    --segment-name SEGMENT_NAME_OF_YOUR_CHOOSING
    --s3-bucket S3_BUCKET_NAME
```

The Pinpoint Application ID, Dynamo Table name, IAM role name, and S3 bucket name will
all appear as outputs from the Terraform. You must choose your own segment name, and
naturally you must provide a CSV file to import.

## CSV File Input Format

The CSV file you provide must include at least this one header:

* Email

The code is currently set up to also support the following, optional headers:

* First Name
* Middle Name
* Last Name

## Using the unsubscribe link in Pinpoint campaigns

When you actually need to send your campaign, include a link like this in the Message Template:

```html
<a href="https://1234567890.execute-api.us-east-1.amazonaws.com/unsubscribe/{{User.UserId}}">unsubscribe</a>
```

Of course you need to replace the 1234567890 portion with your actual API Gateway URL.
This will be displayed as one of the Terraform outputs.

## Extra credit

If you don't want such an ugly URL for your unsubscribe link, you can add a Cloudfront distribution in
front of your API Gateway, assign it a certificate from ACM, enable HTTP to HTTPS forwarding, and set
up a CNAME record in Route53 to point to the CF distribution. I didn't try to codify this part in
Terraform (yet) because it's dependent on your domain name and certificate.
