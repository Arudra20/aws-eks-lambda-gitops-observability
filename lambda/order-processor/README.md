# order-processor Lambda

This Lambda function is invoked by the EKS order API using IRSA.

Flow:

```text
User -> ALB -> EKS Service -> order-api Pod -> IRSA Role -> AWS Lambda InvokeFunction -> order-processor
```
