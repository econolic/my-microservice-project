# Мій власний мікросервісний проєкт  
Це репозиторій для навчального проєкту в межах курсу "DevOps CI/CD".  

## Мета  
Навчитися основам роботи з Git, GitHub та Docker.

## Lesson 4: Docker - Контейнеризація Django проєкту

### Опис
Django-застосунок з базою даних PostgreSQL та вебсервером Nginx, повністю контейнеризований за допомогою Docker.

### Технології
- Django 4.2
- PostgreSQL 15
- Nginx
- Gunicorn
- Docker & Docker Compose

### Запуск проєкту

```bash
docker-compose up -d
```

### Створення суперкористувача
```bash
docker-compose exec web python manage.py createsuperuser
```
- Username: admin
- Email: admin@example.com
- Password: (ваш пароль)

### Доступ до застосунку
- Головна сторінка: http://localhost
- Django Admin: http://localhost/admin

### Зупинка проєкту

```bash
docker-compose down
```

