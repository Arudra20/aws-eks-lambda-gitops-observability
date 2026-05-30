# GitOps flow

## Flow

```text
Developer push
   |
   v
GitHub Actions
   |
   |-- Build Docker image
   |-- Push image to ECR
   |-- Update Helm values-dev.yaml with new image tag
   |-- Commit values change to Git
   v
Git repository becomes desired state
   |
   v
Argo CD detects Git change
   |
   v
Argo CD syncs Helm chart to EKS
   |
   v
Kubernetes rolling update
```

## Why this is GitOps

- Git is the source of truth.
- Cluster changes are made by Argo CD, not manually by CI.
- Every deployment is visible as a Git commit.
- Rollback can be done by reverting the image tag commit.
- Argo CD self-heals drift.

## Production improvement

For production, keep two repos:

```text
app repo      -> builds image
gitops repo   -> stores Helm values and Argo CD Applications
```

The app repo should raise a PR to the GitOps repo instead of directly committing to main.
