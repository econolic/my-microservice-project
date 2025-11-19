"""
URL Configuration
"""

from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

def home(request):
    return HttpResponse("""
    <html>
        <head>
            <title>Django + PostgreSQL + Nginx</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    max-width: 800px;
                    margin: 50px auto;
                    padding: 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }
                .container {
                    background: rgba(255, 255, 255, 0.1);
                    padding: 40px;
                    border-radius: 10px;
                    box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
                }
                h1 { text-align: center; font-size: 2.5em; margin-bottom: 30px; }
                .info { background: rgba(255, 255, 255, 0.2); padding: 20px; border-radius: 5px; margin: 20px 0; }
                .success { color: #4ade80; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎉 Вітаємо!</h1>
                <div class="info">
                    <p class="success">✅ Django працює успішно!</p>
                    <p class="success">✅ PostgreSQL підключена!</p>
                    <p class="success">✅ Nginx проксує запити!</p>
                </div>
                <div class="info">
                    <h2>Інформація про проєкт:</h2>
                    <ul>
                        <li><strong>Framework:</strong> Django 4.2</li>
                        <li><strong>База даних:</strong> PostgreSQL 15</li>
                        <li><strong>Веб-сервер:</strong> Nginx</li>
                        <li><strong>WSGI:</strong> Gunicorn</li>
                    </ul>
                </div>
                <p style="text-align: center; margin-top: 30px;">
                    <a href="/admin/" style="color: #fbbf24; text-decoration: none; font-size: 1.2em;">
                        👉 Перейти до адмін-панелі
                    </a>
                </p>
            </div>
        </body>
    </html>
    """)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
]
