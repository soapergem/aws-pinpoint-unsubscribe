#!/usr/bin/env python
import boto3
import click
import csv
from pathlib import Path
from importer.aws import get_dynamo_resource, get_opt_outs_from_dynamo


@click.command()
@click.option("--dynamo-table", required=True, help="DynamoDB Table Name")
def export_opt_outs(dynamo_table):
    """
    This method exports the list of email addresses who have unsubscribed.
    """
    dynamodb = get_dynamo_resource()
    opt_outs = get_opt_outs_from_dynamo(dynamodb, dynamo_table)
    if not opt_outs:
        click.echo("No one has opted out")
        return

    export_file = Path("unsub.csv")
    with open(export_file, "w") as out_file:
        csv_writer = csv.writer(out_file)
        for email in opt_outs:
            csv_writer.writerow([email])

    click.echo(f"Exported {len(opt_outs)} email address(es)")


if __name__ == "__main__":
    export_opt_outs()
