import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes, MessageHandler, filters
from cryptography.fernet import Fernet
import json
import random

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
    """Обработка текстовых сообщений от приложения"""
    text = update.message.text
    chat_id = update.effective_chat.id
    
    # Формат: LOGIN:phone или SEND:from_phone:to_phone:message или SEARCH:query
    if text.startswith('LOGIN:'):
        phone = text.replace('LOGIN:', '').strip()
        user = find_user_by_phone(phone)
        
        if user:
            users_data[phone]['chat_id'] = chat_id
            await update.message.reply_text(f"OK:{user['name']}")
        else:
            await update.message.reply_text("ERROR:User not found")
    
    elif text.startswith('SEND:'):
        parts = text.replace('SEND:', '').split(':', 2)
        if len(parts) == 3:
            from_phone, to_phone, message = parts
            
            if find_user_by_phone(from_phone) and find_user_by_phone(to_phone):
                encrypted = encrypt_message(message)
                messages_data.append({
                    'from_phone': from_phone,
                    'to_phone': to_phone,
                    'text': message,
                    'encrypted': encrypted
                })
                
                # Отправить уведомление получателю если он онлайн
                to_user = users_data[to_phone]
                if to_user.get('chat_id'):
                    try:
                        await context.bot.send_message(
                            chat_id=to_user['chat_id'],
                            text=f"MSG:{from_phone}:{message}"
                        )
                    except:
                        pass
                
                await update.message.reply_text("OK:Message sent")
            else:
                await update.message.reply_text("ERROR:User not found")
    
    elif text.startswith('SEARCH:'):
        query_text = text.replace('SEARCH:', '').strip().lower()
        results = []
        
        for phone, data in users_data.items():
            if query_text in data.get('name', '').lower() or query_text in phone:
                results.append(f"{phone}:{data['name']}")
        
        if results:
            await update.message.reply_text("RESULTS:" + "|".join(results[:10]))
        else:
            await update.message.reply_text("RESULTS:")
    
    elif text.startswith('GETMSGS:'):
        phone = text.replace('GETMSGS:', '').strip()
        user_messages = []
        
        for msg in messages_data:
            if msg['from_phone'] == phone or msg['to_phone'] == phone:
                user_messages.append(f"{msg['from_phone']}>{msg['to_phone']}:{msg['text']}")
        
        if user_messages:
            await update.message.reply_text("MSGS:" + "|".join(user_messages[-50:]))
        else:
            await update.message.reply_text("MSGS:")

def main():
    app = Application.builder().token(BOT_TOKEN).build()
    
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CallbackQueryHandler(button_callback))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print("🤖 Бот запущен!")
    print(f"🔑 Bot Token: {BOT_TOKEN}")
    print(f"🔐 Ключ шифрования: {ENCRYPTION_KEY.decode()}")
    print("\nПриложение будет общаться напрямую с ботом через Telegram API")
    
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
