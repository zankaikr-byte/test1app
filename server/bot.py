import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes, MessageHandler, filters
from cryptography.fernet import Fernet
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import random
import threading
import sqlite3
from datetime import datetime

# Admin Telegram IDs
ADMIN_IDS = [8434056844]  # Замени на свой Telegram ID

# Bot Token
BOT_TOKEN = "8623096705:AAGTHypGpra_zTN2JP5OLjTJMRm8tNoOw3Y"

# Encryption key
ENCRYPTION_KEY = Fernet.generate_key()
cipher = Fernet(ENCRYPTION_KEY)

# Data storage
used_phones = set()
verification_codes = {}  # {phone: code}

# Flask API
app_flask = Flask(__name__)
CORS(app_flask)

# Database setup
def init_db():
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    
    # Users table
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (phone TEXT PRIMARY KEY,
                  name TEXT,
                  is_anonymous INTEGER,
                  created_at TEXT)''')
    
    # Messages table
    c.execute('''CREATE TABLE IF NOT EXISTS messages
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  from_phone TEXT,
                  to_phone TEXT,
                  text TEXT,
                  encrypted TEXT,
                  timestamp TEXT,
                  FOREIGN KEY (from_phone) REFERENCES users(phone),
                  FOREIGN KEY (to_phone) REFERENCES users(phone))''')
    
    # Chats table (для списка чатов каждого пользователя)
    c.execute('''CREATE TABLE IF NOT EXISTS chats
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_phone TEXT,
                  contact_phone TEXT,
                  last_message TEXT,
                  last_message_time TEXT,
                  unread_count INTEGER DEFAULT 0,
                  FOREIGN KEY (user_phone) REFERENCES users(phone),
                  FOREIGN KEY (contact_phone) REFERENCES users(phone))''')
    
    conn.commit()
    conn.close()

init_db()

def is_admin(user_id: int) -> bool:
    return user_id in ADMIN_IDS

def generate_phone() -> str:
    """Генерация американского номера +1 (XXX) XXX-XXXX"""
    while True:
        area_code = random.randint(200, 999)
        prefix = random.randint(200, 999)
        line = random.randint(1000, 9999)
        phone = f"+1{area_code}{prefix}{line}"
        
        if phone not in used_phones:
            used_phones.add(phone)
            return phone

def generate_anonymous_phone() -> str:
    """Генерация анонимного номера +888 XXXX XXXX"""
    while True:
        part1 = random.randint(1000, 9999)
        part2 = random.randint(1000, 9999)
        phone = f"+888{part1}{part2}"
        
        if phone not in used_phones:
            used_phones.add(phone)
            return phone

def format_phone_display(phone: str) -> str:
    """Форматирование номера для отображения"""
    if phone.startswith("+1") and len(phone) == 12:
        # +1 (XXX) XXX-XXXX
        return f"+1 ({phone[2:5]}) {phone[5:8]}-{phone[8:]}"
    elif phone.startswith("+888") and len(phone) == 12:
        # +888 XXXX XXXX
        return f"+888 {phone[4:8]} {phone[8:]}"
    return phone

def find_user_by_phone(phone: str):
    """Поиск пользователя по номеру"""
    return users_data.get(phone)

def encrypt_message(message: str) -> str:
    return cipher.encrypt(message.encode()).decode()

def decrypt_message(encrypted: str) -> str:
    return cipher.decrypt(encrypted.encode()).decode()

def get_user(phone: str):
    """Получить пользователя из БД"""
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('SELECT * FROM users WHERE phone = ?', (phone,))
    user = c.fetchone()
    conn.close()
    if user:
        return {'phone': user[0], 'name': user[1], 'is_anonymous': user[2], 'created_at': user[3]}
    return None

def create_user(phone: str, name: str, is_anonymous: bool):
    """Создать пользователя в БД"""
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('INSERT INTO users VALUES (?, ?, ?, ?)',
              (phone, name, 1 if is_anonymous else 0, datetime.now().isoformat()))
    conn.commit()
    conn.close()

def get_or_create_chat(user_phone: str, contact_phone: str):
    """Получить или создать чат"""
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('SELECT * FROM chats WHERE user_phone = ? AND contact_phone = ?',
              (user_phone, contact_phone))
    chat = c.fetchone()
    
    if not chat:
        c.execute('INSERT INTO chats (user_phone, contact_phone, last_message, last_message_time, unread_count) VALUES (?, ?, ?, ?, ?)',
                  (user_phone, contact_phone, '', '', 0))
        conn.commit()
    
    conn.close()

def update_chat(user_phone: str, contact_phone: str, message: str):
    """Обновить последнее сообщение в чате"""
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    
    # Обновить чат отправителя
    c.execute('UPDATE chats SET last_message = ?, last_message_time = ? WHERE user_phone = ? AND contact_phone = ?',
              (message, datetime.now().isoformat(), user_phone, contact_phone))
    
    # Обновить чат получателя и увеличить счетчик непрочитанных
    c.execute('UPDATE chats SET last_message = ?, last_message_time = ?, unread_count = unread_count + 1 WHERE user_phone = ? AND contact_phone = ?',
              (message, datetime.now().isoformat(), contact_phone, user_phone))
    
    conn.commit()
    conn.close()

def save_message(from_phone: str, to_phone: str, text: str):
    """Сохранить сообщение в БД"""
    encrypted = encrypt_message(text)
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('INSERT INTO messages (from_phone, to_phone, text, encrypted, timestamp) VALUES (?, ?, ?, ?, ?)',
              (from_phone, to_phone, text, encrypted, datetime.now().isoformat()))
    conn.commit()
    conn.close()
    
    # Создать или обновить чаты
    get_or_create_chat(from_phone, to_phone)
    get_or_create_chat(to_phone, from_phone)
    update_chat(from_phone, to_phone, text)

def generate_verification_code() -> str:
    """Генерация 6-значного кода"""
    return str(random.randint(100000, 999999))

# Flask API Routes
@app_flask.route('/api/request_code', methods=['POST'])
def request_code():
    """Запросить код подтверждения"""
    data = request.json
    phone = data.get('phone')
    
    user = get_user(phone)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    # Генерировать код
    code = generate_verification_code()
    verification_codes[phone] = code
    
    print(f"📱 Код для {phone}: {code}")
    
    return jsonify({
        'success': True,
        'message': f'Code sent (check console): {code}'
    })

@app_flask.route('/api/verify_code', methods=['POST'])
def verify_code():
    """Проверить код подтверждения"""
    data = request.json
    phone = data.get('phone')
    code = data.get('code')
    
    if phone not in verification_codes:
        return jsonify({'error': 'Code not requested'}), 400
    
    if verification_codes[phone] != code:
        return jsonify({'error': 'Invalid code'}), 401
    
    # Удалить использованный код
    del verification_codes[phone]
    
    user = get_user(phone)
    return jsonify({
        'success': True,
        'name': user['name'],
        'phone': user['phone']
    })

@app_flask.route('/api/login', methods=['POST'])
def login():
    """Старый метод входа (для совместимости)"""
    data = request.json
    phone = data.get('phone')
    
    user = get_user(phone)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify({
        'success': True,
        'name': user['name']
    })

@app_flask.route('/api/users', methods=['GET'])
def get_users():
    """Получить всех пользователей"""
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('SELECT * FROM users')
    users = c.fetchall()
    conn.close()
    
    users_list = []
    for user in users:
        users_list.append({
            'phone': user[0],
            'name': user[1],
            'is_anonymous': bool(user[2])
        })
    return jsonify(users_list)

@app_flask.route('/api/search', methods=['GET'])
def search():
    """Поиск пользователей"""
    query = request.args.get('q', '').lower()
    
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('SELECT * FROM users WHERE LOWER(name) LIKE ? OR phone LIKE ?',
              (f'%{query}%', f'%{query}%'))
    users = c.fetchall()
    conn.close()
    
    results = []
    for user in users[:10]:
        results.append({
            'phone': user[0],
            'name': user[1]
        })
    
    return jsonify(results)

@app_flask.route('/api/send', methods=['POST'])
def send_message_api():
    """Отправить сообщение"""
    data = request.json
    from_phone = data.get('from')
    to_phone = data.get('to')
    text = data.get('text')
    
    if not get_user(from_phone) or not get_user(to_phone):
        return jsonify({'error': 'User not found'}), 404
    
    save_message(from_phone, to_phone, text)
    
    return jsonify({'success': True})

@app_flask.route('/api/messages', methods=['GET'])
def get_messages():
    """Получить сообщения между двумя пользователями"""
    phone = request.args.get('phone')
    contact = request.args.get('contact')
    
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('''SELECT * FROM messages 
                 WHERE (from_phone = ? AND to_phone = ?) 
                 OR (from_phone = ? AND to_phone = ?)
                 ORDER BY timestamp ASC''',
              (phone, contact, contact, phone))
    messages = c.fetchall()
    conn.close()
    
    result = []
    for msg in messages[-50:]:
        result.append({
            'from': msg[1],
            'to': msg[2],
            'text': msg[3],
            'timestamp': msg[5]
        })
    
    return jsonify(result)

@app_flask.route('/api/chats', methods=['GET'])
def get_chats():
    """Получить список чатов пользователя"""
    phone = request.args.get('phone')
    
    conn = sqlite3.connect('telegram_clone.db')
    c = conn.cursor()
    c.execute('''SELECT c.*, u.name FROM chats c
                 JOIN users u ON c.contact_phone = u.phone
                 WHERE c.user_phone = ?
                 ORDER BY c.last_message_time DESC''', (phone,))
    chats = c.fetchall()
    conn.close()
    
    result = []
    for chat in chats:
        result.append({
            'contact_phone': chat[2],
            'contact_name': chat[6],
            'last_message': chat[3],
            'last_message_time': chat[4],
            'unread_count': chat[5]
        })
    
    return jsonify(result)

@app_flask.route('/api/create_account', methods=['POST'])
def create_account():
    """Создать новый аккаунт"""
    data = request.json
    is_anonymous = data.get('anonymous', False)
    
    if is_anonymous:
        phone = generate_anonymous_phone()
    else:
        phone = generate_phone()
    
    create_user(phone, 'New User', is_anonymous)
    
    return jsonify({
        'success': True,
        'phone': phone,
        'display': format_phone_display(phone)
    })

@app_flask.route('/')
def index():
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Telegram Clone Admin</title>
        <style>
            body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
            button { padding: 10px 20px; margin: 10px; font-size: 16px; cursor: pointer; }
            .account { background: #f0f0f0; padding: 15px; margin: 10px 0; border-radius: 8px; }
            .phone { font-size: 20px; font-weight: bold; color: #0088cc; }
        </style>
    </head>
    <body>
        <h1>🔐 Telegram Clone Admin Panel</h1>
        <div>
            <button onclick="createAccount(false)">➕ Create Account</button>
            <button onclick="createAccount(true)">🎭 Create Anonymous</button>
        </div>
        <div id="accounts"></div>
        
        <script>
            async function createAccount(anonymous) {
                const res = await fetch('/api/create_account', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({anonymous})
                });
                const data = await res.json();
                
                const div = document.createElement('div');
                div.className = 'account';
                div.innerHTML = `
                    <div class="phone">${data.display}</div>
                    <div>Raw: ${data.phone}</div>
                    <div>Type: ${anonymous ? 'Anonymous' : 'Regular'}</div>
                `;
                document.getElementById('accounts').prepend(div);
            }
            
            async function loadUsers() {
                const res = await fetch('/api/users');
                const users = await res.json();
                const div = document.getElementById('accounts');
                div.innerHTML = '';
                users.forEach(user => {
                    const acc = document.createElement('div');
                    acc.className = 'account';
                    acc.innerHTML = `
                        <div class="phone">${user.phone}</div>
                        <div>Name: ${user.name}</div>
                        <div>Type: ${user.is_anonymous ? 'Anonymous' : 'Regular'}</div>
                    `;
                    div.appendChild(acc);
                });
            }
            
            loadUsers();
        </script>
    </body>
    </html>
    '''

def run_flask():
    app_flask.run(host='0.0.0.0', port=5000, debug=False)

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    chat_id = update.effective_chat.id
    
    if is_admin(user_id):
        keyboard = [
            [InlineKeyboardButton("📊 Статистика", callback_data='stats')],
            [InlineKeyboardButton("👥 Пользователи", callback_data='users')],
            [InlineKeyboardButton("💬 Сообщения", callback_data='messages')],
            [InlineKeyboardButton("➕ Создать аккаунт", callback_data='create_account')],
            [InlineKeyboardButton("🎭 Анонимный аккаунт", callback_data='create_anonymous')]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await update.message.reply_text(
            '🔐 *Админ панель Telegram App*\n\n'
            'Выберите действие:',
            reply_markup=reply_markup,
            parse_mode='Markdown'
        )
    else:
        await update.message.reply_text(
            '❌ У вас нет доступа к админ панели.\n'
            f'Ваш Telegram ID: `{user_id}`',
            parse_mode='Markdown'
        )

async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = query.from_user.id
    
    if not is_admin(user_id):
        await query.answer("❌ Нет доступа", show_alert=True)
        return
    
    await query.answer()
    
    if query.data == 'stats':
        conn = sqlite3.connect('telegram_clone.db')
        c = conn.cursor()
        c.execute('SELECT COUNT(*) FROM users')
        users_count = c.fetchone()[0]
        c.execute('SELECT COUNT(*) FROM messages')
        messages_count = c.fetchone()[0]
        conn.close()
        
        stats_text = f"""
📊 *Статистика приложения*

👥 Пользователей: {users_count}
💬 Сообщений: {messages_count}
🔒 Шифрование: Активно
"""
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(stats_text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'users':
        if not users_data:
            text = "👥 *Пользователи*\n\nПользователей пока нет"
        else:
            text = "👥 *Пользователи*\n\n"
            for phone, data in users_data.items():
                phone_display = format_phone_display(phone)
                icon = "🎭" if data.get('is_anonymous') else "📱"
                text += f"{icon} {phone_display}\n👤 {data.get('name', 'Unknown')}\n\n"
        
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'messages':
        if not messages_data:
            text = "� *Сообщения*\n\nСообщений пока нет"
        else:
            text = "� *Последние сообщения*\n\n"
            for msg in messages_data[-10:]:
                try:
                    decrypted = decrypt_message(msg['encrypted'])
                    text += f"От {msg['from_phone']} → {msg['to_phone']}\n{decrypted}\n\n"
                except:
                    pass
        
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'create_account':
        # Генерация обычного аккаунта
        phone = generate_phone()
        create_user(phone, 'New User', False)
        
        phone_display = format_phone_display(phone)
        text = f"""
✅ *Аккаунт создан!*

📱 Номер для входа:
`{phone}`

Отображается как: {phone_display}

Используйте этот номер для входа в приложение.
"""
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'create_anonymous':
        # Генерация анонимного аккаунта
        phone = generate_anonymous_phone()
        create_user(phone, 'Anonymous', True)
        
        phone_display = format_phone_display(phone)
        text = f"""
✅ *Анонимный аккаунт создан!*

🎭 Номер для входа:
`{phone}`

Отображается как: {phone_display}

Анонимные аккаунты имеют специальный префикс +888.
"""
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'back':
        keyboard = [
            [InlineKeyboardButton("📊 Статистика", callback_data='stats')],
            [InlineKeyboardButton("👥 Пользователи", callback_data='users')],
            [InlineKeyboardButton("💬 Сообщения", callback_data='messages')],
            [InlineKeyboardButton("➕ Создать аккаунт", callback_data='create_account')],
            [InlineKeyboardButton("🎭 Анонимный аккаунт", callback_data='create_anonymous')]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await query.edit_message_text(
            '🔐 *Админ панель Telegram App*\n\n'
            'Выберите действие:',
            reply_markup=reply_markup,
            parse_mode='Markdown'
        )

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработка текстовых сообщений"""
    text = update.message.text
    await update.message.reply_text(f"Получено: {text}")

def main():
    # Запуск Flask API в отдельном потоке
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()
    
    print("🤖 Бот запущен (Telegram может быть заблокирован)")
    print("🌐 API сервер запущен на http://localhost:5000")
    print(f"🔐 Ключ шифрования: {ENCRYPTION_KEY.decode()}")
    print("\n📱 Открой http://172.20.10.2:5000 в браузере для создания аккаунтов")
    print("   Или используй Telegram бота если есть VPN/прокси\n")
    
    # Пытаемся запустить Telegram бота (может не работать без VPN)
    try:
        app = Application.builder().token(BOT_TOKEN).build()
        
        app.add_handler(CommandHandler("start", start))
        app.add_handler(CallbackQueryHandler(button_callback))
        app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
        
        # Fix for Python 3.14 asyncio event loop
        import asyncio
        import sys
        
        if sys.platform == 'win32':
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        app.run_polling()
    except Exception as e:
        print(f"⚠️ Telegram бот не запустился: {e}")
        print("💡 Используй веб-интерфейс: http://172.20.10.2:5000")
        # Держим Flask запущенным
        import time
        while True:
            time.sleep(1)

if __name__ == '__main__':
    main()
