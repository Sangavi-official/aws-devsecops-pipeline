"""Visitor counter Lambda.

GET /        -> serves a small HTML demo page (professional presentation)
GET /visits  -> increments the counter in DynamoDB, returns JSON
"""

import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shift-Left DevSecOps Pipeline - Live Demo</title>
<style>
  :root { --bg:#0d1117; --card:#161b22; --line:#30363d; --txt:#e6edf3; --dim:#8b949e; --acc:#3fb950; --blue:#58a6ff; }
  * { box-sizing:border-box; margin:0; }
  body { background:var(--bg); color:var(--txt); font-family:Segoe UI,system-ui,sans-serif; min-height:100vh; display:flex; align-items:center; justify-content:center; padding:24px; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:12px; max-width:640px; width:100%; padding:32px; }
  h1 { font-size:1.35rem; margin-bottom:4px; }
  .sub { color:var(--dim); font-size:.9rem; margin-bottom:24px; }
  .count-box { text-align:center; border:1px solid var(--line); border-radius:10px; padding:20px; margin-bottom:24px; }
  .count { font-size:3rem; font-weight:700; color:var(--acc); }
  .count-label { color:var(--dim); font-size:.85rem; }
  .flow { display:flex; flex-wrap:wrap; gap:6px; align-items:center; justify-content:center; margin-bottom:24px; font-size:.8rem; }
  .step { border:1px solid var(--line); border-radius:6px; padding:6px 10px; background:var(--bg); }
  .arrow { color:var(--dim); }
  .explain { color:var(--dim); font-size:.85rem; line-height:1.6; margin-bottom:24px; }
  .explain b { color:var(--txt); }
  .row { display:flex; gap:10px; flex-wrap:wrap; }
  a.btn, button.btn { flex:1; min-width:140px; text-align:center; padding:10px 14px; border-radius:8px; border:1px solid var(--line); background:var(--bg); color:var(--blue); font-size:.9rem; text-decoration:none; cursor:pointer; }
  button.btn { color:var(--acc); font-weight:600; }
  .badge { display:inline-block; border:1px solid var(--acc); color:var(--acc); border-radius:20px; font-size:.7rem; padding:2px 10px; margin-bottom:14px; }
</style>
</head>
<body>
<main class="card">
  <span class="badge">deployed via security-gated CI/CD - $0 infrastructure</span>
  <h1>Shift-Left DevSecOps Pipeline</h1>
  <p class="sub">A serverless demo by Sangavi - every deploy passed Checkov + gitleaks scans and used keyless OIDC credentials.</p>

  <div class="count-box">
    <div class="count" id="count">-</div>
    <div class="count-label">total visits recorded in DynamoDB</div>
  </div>

  <div class="flow">
    <span class="step">Your browser</span><span class="arrow">-></span>
    <span class="step">API Gateway</span><span class="arrow">-></span>
    <span class="step">Lambda (Python)</span><span class="arrow">-></span>
    <span class="step">DynamoDB</span>
  </div>

  <p class="explain">
    <b>What just happened:</b> this page called the <b>/visits</b> API. API Gateway (throttled and access-logged)
    invoked a Lambda function running with a least-privilege IAM role that is allowed exactly one action:
    update one counter item in one DynamoDB table. The count above came back in milliseconds.
    None of this infrastructure was clicked together - it is all Terraform, and no change reaches AWS
    without passing an IaC security scan and a secret scan first.
  </p>

  <div class="row">
    <button class="btn" onclick="hit()">Call the API again</button>
    <a class="btn" href="visits">Raw JSON response</a>
    <a class="btn" href="https://github.com/Sangavi-official/aws-devsecops-pipeline" target="_blank">Source + pipeline on GitHub</a>
  </div>
</main>
<script>
  function hit() {
    fetch("visits").then(function (r) { return r.json(); }).then(function (d) {
      document.getElementById("count").textContent = d.visits;
    }).catch(function () { document.getElementById("count").textContent = "error"; });
  }
  hit();
</script>
</body>
</html>"""


def handler(event, context):
    path = event.get("rawPath", "/")
    if path.rstrip("/").endswith("visits"):
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
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/html; charset=utf-8"},
        "body": PAGE,
    }
