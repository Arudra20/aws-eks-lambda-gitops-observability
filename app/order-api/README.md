# order-api

A simple Flask API deployed on EKS.

## Endpoints

| Endpoint | Purpose |
|---|---|
| `/` | App info |
| `/healthz` | Liveness probe |
| `/readyz` | Readiness probe |
| `/metrics` | Prometheus-compatible metrics |
| `POST /orders` | Creates an order and invokes AWS Lambda if configured |

## Local run

```powershell
cd app/order-api
python -m venv .venv
. .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python main.py
```

```powershell
curl http://localhost:8080/healthz
curl -Method POST http://localhost:8080/orders -Body '{"amount":250}' -ContentType 'application/json'
```
