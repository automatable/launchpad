"""Views for error handling."""

from django.shortcuts import redirect


def custom_404(request, exception):
    """Redirect all 404s to the home page."""
    return redirect("home")
