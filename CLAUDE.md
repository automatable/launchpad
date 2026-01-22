# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
launchpad/
├── launchpad/              # Django project
│   ├── settings.py         # Configuration (uses env vars)
│   ├── urls.py             # URL routing
│   ├── views.py            # Health check view (fallback)
│   ├── middleware.py       # Health check middleware
│   └── wsgi.py             # WSGI entry point
├── templates/              # HTML templates
├── static/                 # Static assets (CSS, JS, images)
├── .do/app.yaml            # DigitalOcean App Platform config
└── manage.py               # Django CLI
```

## Deployment

### Auto-Deploy
App Platform auto-deploys on every push to `main`. Configuration in `.do/app.yaml`.

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
# Check deployment status
doctl apps list-deployments 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e

# View logs
doctl apps logs 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e

# View build logs
doctl apps logs 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --type build

# Force rebuild
doctl apps create-deployment 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --force-rebuild

# Get current spec
doctl apps spec get 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e

# Update app spec (preserves SECRET_KEY if using encrypted value)
doctl apps update 16c55ee6-8e1d-4036-a26f-ba5d4130eb9e --spec .do/app.yaml
```

### Important Notes

1. **SECRET_KEY Management**: When updating the app spec via `doctl`, SECRET_KEY values marked as `type: SECRET` get cleared unless you include the encrypted `EV[1:...]` value. Either:
   - Get current spec first with `doctl apps spec get` to preserve the encrypted value
   - Or re-set the secret after updating

2. **ALLOWED_HOSTS**: Uses `.automatable.agency` (with leading dot) to match both apex and subdomains. The health check middleware bypasses this for internal probes.

3. **Cloudflare**: Site uses Cloudflare proxy. Ensure Full SSL mode is enabled in Cloudflare settings.

## DigitalOcean Resources

- **App ID**: `16c55ee6-8e1d-4036-a26f-ba5d4130eb9e`
- **App Name**: `automatable-launchpad`
- **Project**: Automatable
- **Region**: London (lon)
- **Instance**: `apps-s-1vcpu-0.5gb`
