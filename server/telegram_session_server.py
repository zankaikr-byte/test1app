"""
Сервер для управления Telegram сессиями
Использует Telethon для создания и управления сессиями
"""
import asyncio
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from telethon import TelegramClient
from telethon.errors import SessionPasswordNeededError, PhoneCodeInvalidError
import json

# Конфигурация
API_ID = 39905970  # Замени на свой API ID с https://my.telegram.org/apps
API_HASH = "69f06a4021226878937cd97fc4aed799"  # Замени на свой API Hash

app = Flask(__name__)
CORS(app)

# Хранилище активных клиентов
active_clients = {}
pending_auth = {}

# Создаем папку для сессий
os.makedirs("sessions", exist_ok=True)

def get_client(phone):
    """Получить или создать клиент для номера"""
    if phone not in active_clients:
        session_file = f"sessions/{phone.replace('+', '')}"
        client = TelegramClient(session_file, API_ID, API_HASH)
        active_clients[phone] = client
    return active_clients[phone]

@app.route('/api/send_code', methods=['POST'])
async def send_code():
    """Отправить код подтверждения на номер"""
    try:
        data = request.json
        phone = data.get('phone')
        
        if not phone:
            return jsonify({'error': 'Phone number required'}), 400
        
        client = get_client(phone)
        await client.connect()
        
        # Отправляем код
        result = await client.send_code_request(phone)
        
        # Сохраняем phone_code_hash
        pending_auth[phone] = {
            'phone_code_hash': result.phone_code_hash,
            'client': client
        }
        
        return jsonify({
            'success': True,
            'phone_code_hash': result.phone_code_hash,
            'message': 'Код отправлен на Telegram'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/verify_code', methods=['POST'])
async def verify_code():
    """Проверить код и авторизоваться"""
    try:
        data = request.json
        phone = data.get('phone')
        code = data.get('code')
        password = data.get('password')  # Для 2FA
        
        if phone not in pending_auth:
            return jsonify({'error': 'Code not requested'}), 400
        
        client = pending_auth[phone]['client']
        
        try:
            # Пытаемся войти с кодом
            await client.sign_in(phone, code)
        except SessionPasswordNeededError:
            # Нужен пароль 2FA
            if not password:
                return jsonify({
                    'error': '2FA required',
                    'needs_password': True
                }), 401
            await client.sign_in(password=password)
        except PhoneCodeInvalidError:
            return jsonify({'error': 'Invalid code'}), 401
        
        # Получаем информацию о пользователе
        me = await client.get_me()
        
        # Сохраняем сессию
        session_string = client.session.save()
        
        # Удаляем из pending
        del pending_auth[phone]
        
        return jsonify({
            'success': True,
            'session_string': session_string,
            'user': {
                'id': me.id,
                'first_name': me.first_name,
                'username': me.username,
                'phone': me.phone
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/send_message', methods=['POST'])
async def send_message():
    """Отправить сообщение боту"""
    try:
        data = request.json
        phone = data.get('phone')
        bot_username = data.get('bot_username')
        message = data.get('message')
        
        if not all([phone, bot_username, message]):
            return jsonify({'error': 'Missing parameters'}), 400
        
        client = get_client(phone)
        
        if not await client.is_user_authorized():
            return jsonify({'error': 'Not authorized'}), 401
        
        # Отправляем сообщение боту
        await client.send_message(bot_username, message)
        
        # Ждем ответ (последнее сообщение от бота)
        await asyncio.sleep(2)
        messages = await client.get_messages(bot_username, limit=1)
        
        response_text = messages[0].text if messages else "No response"
        
        return jsonify({
            'success': True,
            'response': response_text
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/check_requests', methods=['POST'])
async def check_requests():
    """Проверить количество доступных запросов у бота"""
    try:
        data = request.json
        phone = data.get('phone')
        bot_username = data.get('bot_username')
        
        client = get_client(phone)
        
        if not await client.is_user_authorized():
            return jsonify({'error': 'Not authorized'}), 401
        
        # Отправляем команду /profile
        await client.send_message(bot_username, '/profile')
        await asyncio.sleep(2)
        
        messages = await client.get_messages(bot_username, limit=1)
        response = messages[0].text if messages else ""
        
        # Парсим количество запросов
        import re
        match = re.search(r'(\d+)\s*(запрос|request)', response, re.IGNORECASE)
        requests_count = int(match.group(1)) if match else 0
        
        return jsonify({
            'success': True,
            'available_requests': requests_count,
            'response': response
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/disconnect', methods=['POST'])
async def disconnect():
    """Отключить клиент"""
    try:
        data = request.json
        phone = data.get('phone')
        
        if phone in active_clients:
            await active_clients[phone].disconnect()
            del active_clients[phone]
        
        return jsonify({'success': True})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/')
def index():
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Telegram Session Server</title>
        <style>
            body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
            .status { padding: 20px; background: #e8f5e9; border-radius: 8px; }
        </style>
    </head>
    <body>
        <h1>🔐 Telegram Session Server</h1>
        <div class="status">
            <h2>✅ Сервер запущен</h2>
            <p>API доступен на порту 5001</p>
            <p>Endpoints:</p>
            <ul>
                <li>POST /api/send_code - Отправить код</li>
                <li>POST /api/verify_code - Проверить код</li>
                <li>POST /api/send_message - Отправить сообщение боту</li>
                <li>POST /api/check_requests - Проверить запросы</li>
            </ul>
        </div>
    </body>
    </html>
    '''

def run_async_flask():
    """Запуск Flask с поддержкой async"""
    from hypercorn.asyncio import serve
    from hypercorn.config import Config
    
    config = Config()
    config.bind = ["0.0.0.0:5001"]
    
    asyncio.run(serve(app, config))

if __name__ == '__main__':
    print("🚀 Telegram Session Server запущен")
    print("📡 API: http://0.0.0.0:5001")
    print("⚠️  Не забудь установить: pip install telethon flask flask-cors hypercorn")
    print("⚠️  Замени API_ID и API_HASH в коде!")
    
    # Запуск с async поддержкой
    try:
        run_async_flask()
    except ImportError:
        print("\n❌ Установи hypercorn: pip install hypercorn")
        print("Или используй обычный Flask (без async):")
        app.run(host='0.0.0.0', port=5001, debug=True)
