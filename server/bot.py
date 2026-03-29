import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes, MessageHandler, filters
from cryptography.fernet import Fernet
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import random
import threading

# Admin Telegram IDs
ADMIN_IDS = [8434056844]  # Замени на свой Telegram ID

# Bot Token
BOT_TOKEN = "8623096705:AAGTHypGpra_zTN2JP5OLjTJMRm8tNoOw3Y"

# Encryption key
ENCRYPTION_KEY = Fernet.generate_key()
cipher = Fernet(ENCRYPTION_KEY)

# Data storage
users_data = {}  # {phone: {name, chat_id, is_anonymous}}
messages_data = []  # {from_phone, to_phone, text, encrypted}}
used_phones = set()

# Flask API
app_flask = Flask(__name__)
CORS(app_flask)

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

# Flask API Routes
@app_flask.route('/api/login', methods=['POST'])
def login():
    data = request.json
    phone = data.get('phone')
    
    user = users_data.get(phone)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify({
        'success': True,
        'name': user['name']
    })

@app_flask.route('/api/users', methods=['GET'])
def get_users():
    users_list = []
    for phone, data in users_data.items():
        users_list.append({
            'phone': phone,
            'name': data['name'],
            'is_anonymous': data.get('is_anonymous', False)
        })
    return jsonify(users_list)

@app_flask.route('/api/search', methods=['GET'])
def search():
    query = request.args.get('q', '').lower()
    results = []
    
    for phone, data in users_data.items():
        if query in data.get('name', '').lower() or query in phone:
            results.append({
                'phone': phone,
                'name': data['name']
            })
    
    return jsonify(results[:10])

@app_flask.route('/api/send', methods=['POST'])
def send_message_api():
    data = request.json
    from_phone = data.get('from')
    to_phone = data.get('to')
    text = data.get('text')
    
    if not users_data.get(from_phone) or not users_data.get(to_phone):
        return jsonify({'error': 'User not found'}), 404
    
    encrypted = encrypt_message(text)
    messages_data.append({
        'from_phone': from_phone,
        'to_phone': to_phone,
        'text': text,
        'encrypted': encrypted
    })
    
    return jsonify({'success': True})

@app_flask.route('/api/messages', methods=['GET'])
def get_messages():
    phone = request.args.get('phone')
    user_messages = []
    
    for msg in messages_data:
        if msg['from_phone'] == phone or msg['to_phone'] == phone:
            user_messages.append({
                'from': msg['from_phone'],
                'to': msg['to_phone'],
                'text': msg['text']
            })
    
    return jsonify(user_messages[-50:])

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
        stats_text = f"""
📊 *Статистика приложения*

👥 Пользователей: {len(users_data)}
💬 Сообщений: {len(messages_data)}
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
        users_data[phone] = {
            'name': 'New User',
            'chat_id': None,
            'is_anonymous': False
        }
        
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
        users_data[phone] = {
            'name': 'Anonymous',
            'chat_id': None,
            'is_anonymous': True
        }
        
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
    
    app = Application.builder().token(BOT_TOKEN).build()
    
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CallbackQueryHandler(button_callback))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print("🤖 Бот запущен!")
    print("🌐 API сервер запущен на http://localhost:5000")
    print(f"🔐 Ключ шифрования: {ENCRYPTION_KEY.decode()}")
    print("\nПриложение подключается к http://localhost:5000/api")
    
    # Fix for Python 3.14 asyncio event loop
    import asyncio
    import sys
    
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        app.run_polling()
    finally:
        loop.close()

if __name__ == '__main__':
    main()
