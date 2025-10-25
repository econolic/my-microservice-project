# Використовуємо образ Python
FROM python:3.11-slim

# Встановлюємо робочу директорію
WORKDIR /app

# Встановлюємо змінні середовища
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Встановлюємо системні залежності
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Копіюємо файл з залежностями
COPY requirements.txt /app/

# Встановлюємо Python-залежності
RUN pip install --upgrade pip && pip install -r requirements.txt

# Копіюємо весь проєкт
COPY . /app/

# Збираємо статичні файли
RUN python manage.py collectstatic --noinput || true

# Відкриваємо порт
EXPOSE 8000

# Запускаємо Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]
