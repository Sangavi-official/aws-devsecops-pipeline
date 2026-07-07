# Shift-Left DevSecOps Pipeline on AWS

Hi, I am Sangavi. 

**Live demo page:** https://cemrr3gc81.execute-api.ap-south-1.amazonaws.com/ (a designed page that shows the live visit counter and explains the request flow)

**Raw API:** https://cemrr3gc81.execute-api.ap-south-1.amazonaws.com/visits (the JSON endpoint the page calls - each hit increments the counter in DynamoDB)

## What is this project about

Companies get hacked when someone deploys cloud setup with a mistake in it. Like a public database, or a password pushed into GitHub.

So I built a pipeline that checks my work before it reaches AWS. If my code has a security mistake, the deploy is blocked. Simple as that.

## What I did, in simple words

1. I wrote my AWS infrastructure as code using Terraform. A small API with Lambda and DynamoDB.
2. I set up GitHub Actions so every push runs two scanners first. Checkov checks the Terraform for security mistakes. Gitleaks checks for leaked passwords or keys.
3. Only if both pass, Terraform deploys to AWS. It logs in using OIDC, so no AWS keys are saved in GitHub at all.
4. Then I scanned my live AWS account with Prowler against the CIS benchmark. It is like a health checkup for a cloud account.
5. I fixed what I could for free, scanned again, and saved both reports in the /evidence folder as proof.

## Result

| Scan | Score |
|------|-------|
| Before hardening | 38 of 138 checks passed (27.5%) |
| After hardening | 63 of 139 checks passed (45.3%) |

Total AWS bill: 0 rupees. The whole project runs inside the free tier, forever.

## What is different about my approach

- No stored cloud keys anywhere. GitHub gets 15 minute temporary credentials for one repo only.
- Every GitHub Action is pinned to a commit SHA, not a version tag. I did this because the Trivy scanner supply chain was compromised in March 2026 by moved tags. That is also why I chose Checkov.
- Every security check I skipped has a written reason next to it in the code. Nothing is silently ignored.
- The pipeline blocked my own first deploy because my API route had no auth. I had to justify it in writing before it let me through. That is the whole idea, and it worked on me first.

## Three things I learned

- Security tools are not there to annoy you. Mine caught my own access key inside a report before it went public.
- Least privilege is a conversation. You start too strict, read the error, and add exactly one permission.
- A finding you cannot fix is fine, if you write down why. Hiding it is the real failure.

## How this helps my career

This is the daily work of DevSecOps and cloud security engineers: IaC scanning, secret scanning, OIDC, CIS compliance, least privilege IAM. I now have a running example of each one that I built and debugged myself.

Full step-by-step story, screenshots and references are in [docs/PROJECT_REPORT.md](docs/PROJECT_REPORT.md).

