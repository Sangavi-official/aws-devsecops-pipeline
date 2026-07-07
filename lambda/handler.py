"""Visitor counter Lambda.

Each GET /visits request atomically increments a counter item in
DynamoDB and returns the new total as JSON.
"""

import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    response = table.update_item(
        Key={"id": "visits"},
        UpdateExpression="ADD visit_count :one",
        ExpressionAttributeValues={":one": 1},
        ReturnValues="UPDATED_NEW",
    )
    count = int(response["Attributes"]["visit_count"])
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "Deployed via a shift-left DevSecOps pipeline",
                "visits": count,
            }
        ),
    }
