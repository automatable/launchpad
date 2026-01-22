import os

import django
from django.conf import settings

# Configure Django settings before any tests run
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "automatable_website.settings")


def pytest_configure():
    """Configure Django for pytest."""
    if not settings.configured:
        django.setup()
