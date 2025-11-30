from django.contrib import admin
from django.urls import path
from django.http import JsonResponse

def health(request):
    return JsonResponse({'status': 'healthy'})

def home(request):
    return JsonResponse({'message': 'Django app is running!'})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health),
    path('', home),
]
