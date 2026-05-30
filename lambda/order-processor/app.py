import json
import os
import time


def handler(event, context):
    order_id = event.get("orderId", "unknown")
    amount = event.get("amount", 0)

    print(
        json.dumps(
            {
                "message": "Processing order",
                "orderId": order_id,
                "amount": amount,
                "environment": os.getenv("ENVIRONMENT", "dev"),
            }
        )
    )

    return {
        "processor": "aws-lambda",
        "function": os.getenv("AWS_LAMBDA_FUNCTION_NAME", "order-processor"),
        "orderId": order_id,
        "amount": amount,
        "processedAtEpoch": int(time.time()),
        "status": "processed",
    }
