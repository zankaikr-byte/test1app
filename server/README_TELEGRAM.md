# Telegram Session Server

Отдельный сервер для управления Telegram сессиями через Telethon.

## Установка

```bash
cd server
pip install -r requirements_telegram.txt
```

## Настройка

1. Получи API_ID и API_HASH на https://my.telegram.org/apps
2. Открой `config.py` и вставь свои данные
3. Создай сессии командой:

```bash
python create_session.py
```

## Запуск сервера

```bash
python telegram_session_server.py
```

Сервер запустится на http://0.0.0.0:5001

## API Endpoints

### POST /api/send_code
Отправить код подтверждения
```json
{
  "phone": "+1234567890"
}
```

### POST /api/verify_code
Проверить код
```json
{
  "phone": "+1234567890",
  "code": "12345",
  "password": "optional_2fa_password"
}
```

### POST /api/send_message
Отправить сообщение боту
```json
{
  "phone": "+1234567890",
  "bot_username": "@sherlock_bot",
  "message": "/start"
}
```

### POST /api/check_requests
Проверить доступные запросы
```json
{
  "phone": "+1234567890",
  "bot_username": "@sherlock_bot"
}
```

## Использование в iOS приложении

В `TelegramAPI.swift` измени baseURL на:
```swift
private let baseURL = "http://YOUR_SERVER_IP:5001/api"
```
