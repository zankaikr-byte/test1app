# Telegram Clone Server

## Установка

```bash
pip install -r requirements.txt
```

## Настройка

Бот уже настроен с токеном: `8623096705:AAGTHypGpra_zTN2JP5OLjTJMRm8tNoOw3Y`
Admin ID: `8434056844`

## Запуск

```bash
py bot.py
```

Сервер запустится на:
- Flask API: http://0.0.0.0:5000
- Веб-интерфейс: http://192.168.1.120:5000 (или ваш локальный IP)

## Миграция базы данных

Если у вас уже есть база данных без поля username, запустите:

```bash
py migrate_db.py
```

## Функции

### Telegram Bot (может не работать без VPN)
- 📊 Статистика приложения
- 👥 Управление пользователями
- 💬 Просмотр сообщений (зашифрованных)
- ➕ Создание обычных аккаунтов (+1 XXX XXX-XXXX)
- 🎭 Создание анонимных аккаунтов (+888 XXXX XXXX)

### Веб-интерфейс (работает всегда)
- Создание аккаунтов (обычных и анонимных)
- Просмотр всех пользователей
- Отображение кодов подтверждения в реальном времени
- Автообновление каждые 2 секунды

### Flask API
- `POST /api/create_account` - Создать аккаунт
- `POST /api/request_code` - Запросить код подтверждения
- `POST /api/verify_code` - Проверить код
- `GET /api/users` - Получить всех пользователей
- `GET /api/search?q=query` - Поиск по номеру/имени/username
- `POST /api/send` - Отправить сообщение
- `GET /api/messages?phone=X&contact=Y` - Получить сообщения
- `GET /api/chats?phone=X` - Получить список чатов
- `POST /api/update_profile` - Обновить профиль (имя, username)
- `GET /api/get_codes` - Получить активные коды

## База данных

SQLite база `telegram_clone.db` с таблицами:
- `users` - Пользователи (phone, name, username, is_anonymous, created_at)
- `messages` - Сообщения (id, from_phone, to_phone, text, encrypted, timestamp)
- `chats` - Список чатов (id, user_phone, contact_phone, last_message, last_message_time, unread_count)

## Безопасность

- Доступ к боту только для админов по Telegram ID
- End-to-end шифрование сообщений (Fernet AES-128)
- Ключ шифрования генерируется автоматически при запуске

## Типы номеров

- Обычные: +1 (XXX) XXX-XXXX (американский формат)
- Анонимные: +888 XXXX XXXX (только админ может создавать)

