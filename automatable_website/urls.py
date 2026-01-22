from django.contrib import admin
from django.urls import path
from django.views.generic import TemplateView

from .views import custom_404, health_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("health/", health_check, name="health_check"),
    path("", TemplateView.as_view(template_name="index.html"), name="home"),
]

handler404 = custom_404
