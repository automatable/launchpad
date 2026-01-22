"""Custom middleware for health checks and monitoring."""

from django.http import JsonResponse


class HealthCheckMiddleware:
    """
    Middleware that responds to health check requests before ALLOWED_HOSTS validation.

    This is necessary because Kubernetes health probes use internal IPs
    that don't match the configured ALLOWED_HOSTS.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Respond to health checks immediately, bypassing other middleware
        if request.path == "/health/":
            return JsonResponse({"status": "healthy"})

        return self.get_response(request)
