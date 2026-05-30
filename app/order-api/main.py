import json
import os
import time
import uuid
from typing import Dict, Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

APP_NAME = os.getenv("APP_NAME", "order-api")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
LAMBDA_FUNCTION_NAME = os.getenv("LAMBDA_FUNCTION_NAME", "")

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "order_api_requests_total",
    "Total HTTP requests processed by order-api",
    ["method", "endpoint", "status"],
)

REQUEST_LATENCY = Histogram(
    "order_api_request_duration_seconds",
    "HTTP request latency in seconds",
    ["endpoint"],
)

lambda_client = boto3.client("lambda", region_name=AWS_REGION)


@app.before_request
def before_request():
    request.start_time = time.time()


@app.after_request
def after_request(response):
    endpoint = request.path
    elapsed = time.time() - getattr(request, "start_time", time.time())
    REQUEST_LATENCY.labels(endpoint=endpoint).observe(elapsed)
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=endpoint,
        status=response.status_code,
    ).inc()
    return response


@app.get("/")
def root():
    return jsonify(
        {
            "service": APP_NAME,
            "environment": ENVIRONMENT,
            "message": "Order API is running on Amazon EKS",
            "lambdaConfigured": bool(LAMBDA_FUNCTION_NAME),
        }
    )


@app.get("/healthz")
def healthz():
    return jsonify({"status": "healthy"}), 200


@app.get("/readyz")
def readyz():
    # Add real dependency checks here: DB, cache, external API, etc.
    return jsonify({"status": "ready"}), 200


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.post("/orders")
def create_order():
    payload: Dict[str, Any] = request.get_json(silent=True) or {}
    order_id = payload.get("orderId") or str(uuid.uuid4())
    amount = payload.get("amount", 100)

    event = {
        "orderId": order_id,
        "amount": amount,
        "source": "eks-order-api",
        "environment": ENVIRONMENT,
    }

    lambda_response = None

    if LAMBDA_FUNCTION_NAME:
        try:
            response = lambda_client.invoke(
                FunctionName=LAMBDA_FUNCTION_NAME,
                InvocationType="RequestResponse",
                Payload=json.dumps(event).encode("utf-8"),
            )
            raw_payload = response["Payload"].read().decode("utf-8")
            lambda_response = json.loads(raw_payload)
        except (BotoCoreError, ClientError, json.JSONDecodeError) as exc:
            return jsonify(
                {
                    "orderId": order_id,
                    "status": "lambda_invocation_failed",
                    "error": str(exc),
                }
            ), 502

    return jsonify(
        {
            "orderId": order_id,
            "status": "accepted",
            "processedBy": lambda_response,
        }
    ), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
