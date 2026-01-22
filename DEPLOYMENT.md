# Deployment Guide

This document details the deployment process for the Automatable website.

## Table of Contents
- [Environment Overview](#environment-overview)
- [Day-to-Day Development Workflow](#day-to-day-development-workflow)
- [CI/CD Pipeline](#cicd-pipeline)
- [Manual Deployment Operations](#manual-deployment-operations)
- [Troubleshooting](#troubleshooting)
- [Initial Setup (Reference)](#initial-setup-reference)

---

## Environment Overview

| Environment | Branch | App Name | URL |
|-------------|--------|----------|-----|
| **Production** | `main` | `automatable-website-production` | https://automatable.agency |
| **Testing** | `staging` | `automatable-website-testing` | https://automatable-website-testing-b2m3s.ondigitalocean.app |

Both apps run on DigitalOcean App Platform in the London region.

### App IDs
```
Production: 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e
Testing:    8abcf726-f441-47ac-ad0c-602ece882683
```

### Branch Protection

The repository is configured to enforce the staging-first workflow:

| Branch | Default | Protection |
|--------|---------|------------|
| `staging` | ✅ Yes | None (accepts direct pushes and PRs) |
| `main` | No | Requires PR + CI must pass |

**What this means:**
- `git clone` checks out `staging` by default
- New PRs target `staging` by default
- Direct pushes to `main` are blocked
- PRs to `main` require the CI workflow to pass

### Local Git Hooks (Recommended)

Install local hooks to get prompted before accidentally committing to `main`:

```bash
./scripts/install-hooks.sh
```

This installs:
- **pre-commit**: Prompts before committing while on `main`
- **pre-push**: Prompts before pushing to `main`

To bypass in emergencies: `git commit --no-verify` or `git push --no-verify`

---

## Day-to-Day Development Workflow

### 1. Create a Feature Branch
```bash
git checkout staging
git pull origin staging
git checkout -b feature/my-new-feature
```

### 2. Develop and Test Locally
```bash
# Run local server
python manage.py runserver

# Run tests
pytest -v
```

### 3. Push and Create PR to Staging
```bash
git push -u origin feature/my-new-feature
gh pr create --title "Add my new feature"
# Note: PRs target staging by default (no --base needed)
```

### 4. CI Runs Automatically
GitHub Actions will:
- Run `python manage.py check --deploy`
- Run `pytest`

### 5. Merge to Staging
After CI passes and PR is approved:
```bash
gh pr merge --squash
```

### 6. Verify on Testing Site
Visit https://automatable-website-testing-b2m3s.ondigitalocean.app to verify changes.

### 7. Promote to Production
```bash
git checkout staging
git pull
gh pr create --base main --title "Release: my new feature"
# After approval:
gh pr merge --squash
```

> **Note:** This step is manual because GitHub Actions cannot create PRs without enterprise features or a Personal Access Token.

### 8. Verify Production
Visit https://automatable.agency to confirm the deployment.

---

## CI/CD Pipeline

### GitHub Actions (`.github/workflows/ci.yml`)
Runs on:
- Pull requests to `main` or `staging`
- Pushes to `main` or `staging`

Steps:
1. Checkout code
2. Set up Python 3.12
3. Install dependencies
4. Run Django deployment checks
5. Collect static files
6. Run pytest

### DigitalOcean Auto-Deploy
Both apps have `deploy_on_push: true`, so merges to their respective branches trigger automatic deployments.

---

## Manual Deployment Operations

### Check Deployment Status
```bash
# Production
doctl apps list-deployments 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e

# Testing
doctl apps list-deployments 8abcf726-f441-47ac-ad0c-602ece882683
```

### View Logs
```bash
# Runtime logs
doctl apps logs <APP_ID>

# Build logs
doctl apps logs <APP_ID> --type build

# Deploy logs
doctl apps logs <APP_ID> --type deploy
```

### Force Rebuild
```bash
doctl apps create-deployment <APP_ID> --force-rebuild
```

### Update App Spec
```bash
# Production
doctl apps update 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --spec .do/app.yaml

# Testing
doctl apps update 8abcf726-f441-47ac-ad0c-602ece882683 --spec .do/app-testing.yaml
```

> **Warning**: This clears the `DJANGO_SECRET_KEY`. See [Fixing SECRET_KEY](#fixing-secret_key-after-spec-update) below.

---

## Troubleshooting

### Site Returns 500 Error

**Symptom**: Site returns HTTP 500, but health checks pass.

**Likely Cause**: Missing `DJANGO_SECRET_KEY`.

**Solution**: See [Fixing SECRET_KEY](#fixing-secret_key-after-spec-update).

### Fixing SECRET_KEY After Spec Update

When you update an app spec via `doctl`, environment variables marked as `type: SECRET` get cleared (DigitalOcean doesn't return encrypted values via the API).

**To fix:**
```bash
# Set the app ID
APP_ID="16c55ee6-8e1d-4036-a26f-ba5d4130eb9e"  # or testing app ID

# Generate a new secure key and update the spec in one command
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
doctl apps update $APP_ID --spec <(doctl apps spec get $APP_ID | sed "s/type: SECRET$/value: \"$SECRET_KEY\"/")
```

**What this does:**
1. Generates a cryptographically secure 50-character URL-safe token
2. Gets the current app spec from DigitalOcean
3. Replaces `type: SECRET` with the actual `value: "<key>"`
4. Updates the app with the modified spec

**Alternative - via Dashboard:**
1. Go to https://cloud.digitalocean.com/apps/<APP_ID>/settings
2. Click **Edit** on `DJANGO_SECRET_KEY`
3. Enter a secure random string
4. Save and deploy

### Health Check Failures

**Symptom**: Deployment fails or rolls back due to health check failures.

**Check the logs:**
```bash
doctl apps logs <APP_ID> --type deploy
```

**Common causes:**
- Missing environment variables
- Database migration failures
- Static files not collected

### Deployment Stuck

**Symptom**: Deployment shows "DEPLOYING" for more than 10 minutes.

**Check status:**
```bash
doctl apps list-deployments <APP_ID> --format ID,Phase,Progress
```

**If stuck, cancel and retry:**
```bash
# View deployments to find the stuck one
doctl apps list-deployments <APP_ID>

# Force a new deployment
doctl apps create-deployment <APP_ID> --force-rebuild
```

---

## Initial Setup (Reference)

This section documents how the deployment infrastructure was originally set up. You shouldn't need this for day-to-day operations.

### Prerequisites
- GitHub repository: `automatable/automatable-website`
- DigitalOcean account with App Platform access
- `doctl` CLI authenticated

### Create Production App
```bash
doctl apps create --spec .do/app.yaml --wait
```

### Create Testing App
```bash
# Ensure staging branch exists first
git checkout -b staging
git push -u origin staging

# Create the app
doctl apps create --spec .do/app-testing.yaml --wait
```

### Assign to Project
```bash
doctl projects resources assign f7e22f1b-d2e8-4e06-8bc8-02212e9365f6 \
  --resource=do:app:<NEW_APP_ID>
```

### Set SECRET_KEY for Both Apps
```bash
# For each app
APP_ID="<app-id>"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
doctl apps update $APP_ID --spec <(doctl apps spec get $APP_ID | sed "s/type: SECRET$/value: \"$SECRET_KEY\"/")
```

### Configure Custom Domain (Production Only)
1. Add domain in DigitalOcean App Platform settings
2. Configure DNS:
   - `automatable.agency` → ALIAS to `<app>.ondigitalocean.app`
   - `www.automatable.agency` → CNAME to `automatable.agency`
3. Enable Cloudflare proxy with Full SSL mode

---

## Environment Variables Reference

| Variable | Scope | Description |
|----------|-------|-------------|
| `DJANGO_SECRET_KEY` | RUN_AND_BUILD_TIME | Django secret key (required) |
| `DJANGO_ALLOWED_HOSTS` | RUN_TIME | Comma-separated allowed hosts |
| `DEBUG` | RUN_TIME | `True` or `False` |
| `ENVIRONMENT` | RUN_TIME | `production` or `testing` |
| `DATABASE_URL` | RUN_TIME | Database connection string (optional) |
