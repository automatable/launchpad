# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup

### Automatic (Claude Code)
When you start a Claude Code session, git hooks are automatically installed via the session-start hook.

### Manual Setup
```bash
# Clone the repo
git clone https://github.com/automatable/automatable-website.git
cd automatable-website

# Install git hooks (prompts before committing to main)
./scripts/install-hooks.sh

# Create virtual environment
python -m venv .venv && source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests to verify setup
pytest
```

## Project Overview

Automatable Launch Pad - A landing page for Automatable, specializing in AI-powered business automation solutions.

**Live URLs:**
- https://automatable.agency (primary)
- https://www.automatable.agency (alias)

## Tech Stack

- **Backend**: Django 5.0+ with Gunicorn
- **Database**: PostgreSQL (production), SQLite (development)
- **Static Files**: WhiteNoise for serving static assets
- **Deployment**: DigitalOcean App Platform (London region)
- **CDN/Proxy**: Cloudflare

## Development Commands

```bash
# Create virtual environment
python -m venv .venv && source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run development server
python manage.py runserver

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser

# Run tests
pytest
```

## Architecture

```
automatable-website/
├── automatable_website/    # Django project
│   ├── settings.py         # Configuration (uses env vars)
│   ├── urls.py             # URL routing
│   ├── views.py            # Health check view (fallback)
│   ├── middleware.py       # Health check middleware
│   └── wsgi.py             # WSGI entry point
├── templates/              # HTML templates
├── static/                 # Static assets (CSS, JS, images)
├── tests/                  # Pytest test suite
├── .do/app.yaml            # Production app config
├── .do/app-preview.yaml    # PR preview app config
└── manage.py               # Django CLI
```

## Deployment Workflow

### Branch Strategy
| Branch | Deploys To | URL |
|--------|------------|-----|
| `main` | Production | https://automatable.agency |
| PR branches | Preview apps | `*.ondigitalocean.app` (ephemeral) |

### Workflow
```
feature/* branch → PR to main → preview app created → verify → merge → preview deleted, deploys to production
```

### Auto-Deploy
- **Production**: App Platform auto-deploys on push to `main`. Config in `.do/app.yaml`.
- **Preview apps**: GitHub Actions automatically deploy ephemeral preview apps for each PR. The preview URL is posted as a PR comment. Preview apps are deleted when the PR is merged or closed.

### Environment Variables
| Variable | Scope | Description |
|----------|-------|-------------|
| `DJANGO_SECRET_KEY` | RUN_AND_BUILD_TIME | Secret key (encrypted in DO) |
| `DJANGO_ALLOWED_HOSTS` | RUN_TIME | `.automatable.agency,.ondigitalocean.app,localhost` |
| `DEBUG` | RUN_TIME | `False` in production |
| `DATABASE_URL` | RUN_TIME | Auto-set by DO if database attached |

### Health Checks
- **Endpoint**: `/health/` (internal only - returns 404 to public)
- **Middleware**: `HealthCheckMiddleware` responds before `ALLOWED_HOSTS` validation
- **Probes**: Only responds to `kube-probe/*` User-Agent or `10.x.x.x` IPs
- **Failure handling**: App Platform auto-rolls back if health checks fail

### doctl Commands
```bash
# Production app (16c55ee6-8e1d-4036-a26f-ba5d4130eb9e)
doctl apps list-deployments 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e
doctl apps logs 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e
doctl apps logs 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --type build
doctl apps create-deployment 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --force-rebuild
doctl apps spec get 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e
doctl apps update 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --spec .do/app.yaml

# List all apps (to find preview apps)
doctl apps list
```

### Important Notes

1. **SECRET_KEY Management**: When updating the app spec via `doctl`, SECRET_KEY values marked as `type: SECRET` get cleared. To fix this, generate and set a new key:
   ```bash
   # Generate a new SECRET_KEY and update the app spec
   APP_ID="<app-id>"
   SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
   doctl apps update $APP_ID --spec <(doctl apps spec get $APP_ID | sed "s/type: SECRET$/value: \"$SECRET_KEY\"/")
   ```
   See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for full details.

2. **ALLOWED_HOSTS**: Uses `.automatable.agency` (with leading dot) to match both apex and subdomains. The health check middleware bypasses this for internal probes.

3. **Cloudflare**: Site uses Cloudflare proxy. Ensure Full SSL mode is enabled in Cloudflare settings.

## DigitalOcean Resources

### Production App
- **App ID**: `16c55ee6-8e1d-4036-a26f-ba5d4130eb9e`
- **App Name**: `automatable-website-production`
- **Branch**: `main`
- **URL**: https://automatable.agency

### Preview Apps
Preview apps are created automatically by GitHub Actions when PRs are opened. They are ephemeral and deleted when the PR is closed.

### Common
- **Project**: Automatable (`f7e22f1b-d2e8-4e06-8bc8-02212e9365f6`)
- **Region**: London (lon)
- **Instance**: `apps-s-1vcpu-0.5gb`
