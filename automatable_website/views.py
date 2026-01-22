"""Views for health checks and error handling."""

from django.db import connection
from django.http import JsonResponse
from django.shortcuts import redirect


def health_check(request):
    """
    Health check endpoint for App Platform.

    Verifies:
    - Django app is running
    - Database connection is working

    Returns 200 if healthy, 500 if not.
    """
    health = {
        "status": "healthy",
        "checks": {
            "app": "ok",
            "database": "ok",
        }
    }

    # Check database connection
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    except Exception as e:
        health["status"] = "unhealthy"
        health["checks"]["database"] = str(e)
        return JsonResponse(health, status=500)

    return JsonResponse(health)


def custom_404(request, exception):
    """Redirect all 404s to the home page."""
    return redirect("home")
