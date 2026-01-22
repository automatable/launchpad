"""Custom middleware for health checks and monitoring."""

from django.http import Http404, JsonResponse


class HealthCheckMiddleware:
    """
    Middleware that responds to health check requests from internal probes only.

    Only responds to:
    - Kubernetes probes (User-Agent: kube-probe/*)
    - Internal network requests (10.x.x.x IPs)

    Public requests to /health/ get a 404.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path == "/health/":
            if self._is_internal_probe(request):
                return JsonResponse({"status": "healthy"})
            # Return 404 for public requests - makes endpoint invisible
            raise Http404()

        return self.get_response(request)

    def _is_internal_probe(self, request) -> bool:
        """Check if request is from an internal health probe."""
        # Check User-Agent for Kubernetes probe
        user_agent = request.META.get("HTTP_USER_AGENT", "")
        if user_agent.startswith("kube-probe"):
            return True

        # Check for internal IP ranges (Kubernetes pod network)
        client_ip = self._get_client_ip(request)
        if client_ip and client_ip.startswith("10."):
            return True

        return False

    def _get_client_ip(self, request) -> str | None:
        """Extract client IP from request, handling proxies."""
        # X-Forwarded-For can contain multiple IPs; last one is closest to server
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            # Get the rightmost IP (closest proxy to server)
            return x_forwarded_for.split(",")[-1].strip()

        return request.META.get("REMOTE_ADDR")
