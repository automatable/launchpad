import json

import pytest
from django.http import Http404
from django.test import Client, RequestFactory

from automatable_website.middleware import HealthCheckMiddleware


class TestHomePage:
    """Tests for the home page.

    Note: These tests require `collectstatic` to be run first due to
    WhiteNoise's manifest storage. The CI workflow handles this.
    """

    @pytest.fixture
    def client(self):
        return Client()

    def test_home_page_returns_200(self, client):
        """Home page should return 200 OK."""
        response = client.get("/")
        assert response.status_code == 200

    def test_home_page_contains_automatable(self, client):
        """Home page should contain the Automatable branding."""
        response = client.get("/")
        assert b"Automatable" in response.content


class TestHealthEndpoint:
    """Tests for the health check endpoint."""

    @pytest.fixture
    def factory(self):
        return RequestFactory()

    def test_health_check_responds_to_kube_probe(self, factory):
        """Health check should respond to Kubernetes probes."""
        request = factory.get("/health/", HTTP_USER_AGENT="kube-probe/1.27")
        middleware = HealthCheckMiddleware(lambda r: None)
        response = middleware(request)
        assert response.status_code == 200
        data = json.loads(response.content)
        assert data["status"] == "healthy"

    def test_health_check_responds_to_internal_ip(self, factory):
        """Health check should respond to internal IPs."""
        request = factory.get("/health/")
        request.META["REMOTE_ADDR"] = "10.0.0.1"
        middleware = HealthCheckMiddleware(lambda r: None)
        response = middleware(request)
        assert response.status_code == 200

    def test_health_check_blocks_external_requests(self, factory):
        """Health check should raise 404 for external requests."""
        request = factory.get("/health/", HTTP_USER_AGENT="Mozilla/5.0")
        request.META["REMOTE_ADDR"] = "203.0.113.1"
        middleware = HealthCheckMiddleware(lambda r: None)
        with pytest.raises(Http404):
            middleware(request)
