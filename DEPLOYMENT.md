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
| **Preview** | PR branches | Ephemeral apps | `*.ondigitalocean.app` |

Production runs on DigitalOcean App Platform in the London region. Preview apps are created automatically for each PR and deleted when the PR is closed.

### App IDs
```
Production: 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e
Preview:    Created dynamically per PR
```

### Branch Protection

| Branch | Default | Protection |
|--------|---------|------------|
| `main` | ✅ Yes | Requires PR + CI must pass |

**What this means:**
- `git clone` checks out `main` by default
- New PRs target `main` by default
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
git checkout main
git pull origin main
git checkout -b feature/my-new-feature
```

### 2. Develop and Test Locally
```bash
# Run local server
python manage.py runserver

# Run tests
pytest -v
```

### 3. Push and Create PR to Main
```bash
git push -u origin feature/my-new-feature
gh pr create --title "Add my new feature"
```

Or use the `/push-pr` skill in Claude Code for a streamlined workflow.

### 4. CI Runs + Preview Deploys
GitHub Actions will:
- Run CI checks (`python manage.py check --deploy` and `pytest`)
- Deploy an ephemeral preview app
- Post the preview URL as a PR comment (usually takes 2-3 minutes)

### 5. Verify on Preview
Click the preview URL in the PR comments to verify your changes in a production-like environment.

### 6. Merge to Production
After CI passes, preview is verified, and PR is approved:
```bash
gh pr merge --squash
```

The preview app is automatically deleted and production is deployed.

### 7. Verify Production
Visit https://automatable.agency to confirm the deployment.

---

## CI/CD Pipeline

### GitHub Actions

**CI Workflow (`.github/workflows/ci.yml`)**
Runs on all PRs and pushes to `main`:
1. Checkout code
2. Set up Python 3.12
3. Install dependencies
4. Run Django deployment checks
5. Collect static files
6. Run pytest

**Preview Deploy (`.github/workflows/preview-deploy.yml`)**
Runs when a PR is opened/updated:
1. Deploy ephemeral preview app to DigitalOcean
2. Post preview URL as PR comment

**Preview Cleanup (`.github/workflows/preview-cleanup.yml`)**
Runs when a PR is closed:
1. Delete the preview app

### DigitalOcean Auto-Deploy
Production has `deploy_on_push: true`, so merges to `main` trigger automatic deployments.

---

## Manual Deployment Operations

### Check Deployment Status
```bash
# Production
doctl apps list-deployments 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e

# List all apps (to find preview apps)
doctl apps list
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
APP_ID="16c55ee6-8e1d-4036-a26f-ba5d4130eb9e"  # Production app ID

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
- GitHub repo admin access (for secrets)

### Create Production App
```bash
doctl apps create --spec .do/app.yaml --wait
```

### Assign to Project
```bash
doctl projects resources assign f7e22f1b-d2e8-4e06-8bc8-02212e9365f6 \
  --resource=do:app:<NEW_APP_ID>
```

### Set SECRET_KEY
```bash
APP_ID="<app-id>"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
doctl apps update $APP_ID --spec <(doctl apps spec get $APP_ID | sed "s/type: SECRET$/value: \"$SECRET_KEY\"/")
```

### Configure GitHub Secret for Preview Apps
1. Generate a DigitalOcean API token at https://cloud.digitalocean.com/account/api/tokens
2. Give it Read/Write access to App Platform
3. Add it as a GitHub repository secret named `DIGITALOCEAN_ACCESS_TOKEN`:
   - Go to repo Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `DIGITALOCEAN_ACCESS_TOKEN`
   - Value: Your DigitalOcean API token

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
| `ENVIRONMENT` | RUN_TIME | `production` or `preview` |
| `DATABASE_URL` | RUN_TIME | Database connection string (optional) |
