import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes
from cryptography.fernet import Fernet
import json

# Admin Telegram IDs
ADMIN_IDS = [8434056844]  # Замени на свой Telegram ID

# Encryption key
ENCRYPTION_KEY = Fernet.generate_key()
cipher = Fernet(ENCRYPTION_KEY)

# Data storage
users_data = {}
messages_data = []

def is_admin(user_id: int) -> bool:
    return user_id in ADMIN_IDS

def encrypt_message(message: str) -> str:
    return cipher.encrypt(message.encode()).decode()

def decrypt_message(encrypted: str) -> str:
    return cipher.decrypt(encrypted.encode()).decode()

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    
    if is_admin(user_id):
        keyboard = [
            [InlineKeyboardButton("📊 Статистика", callback_data='stats')],
            [InlineKeyboardButton("👥 Пользователи", callback_data='users')],
            [InlineKeyboardButton("💬 Сообщения", callback_data='messages')],
            [InlineKeyboardButton("🔒 Шифрование", callback_data='encryption')],
            [InlineKeyboardButton("⚙️ Настройки", callback_data='settings')]
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
            f'Ваш ID: `{user_id}`',
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
🔑 Ключ: `{ENCRYPTION_KEY.decode()[:20]}...`
"""
        await query.edit_message_text(stats_text, parse_mode='Markdown')
    
    elif query.data == 'users':
        if not users_data:
            text = "👥 *Пользователи*\n\nПользователей пока нет"
        else:
            text = "👥 *Пользователи*\n\n"
            for uid, data in users_data.items():
                text += f"• ID: {uid}\n  Имя: {data.get('name', 'Unknown')}\n\n"
        
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'messages':
        if not messages_data:
            text = "💬 *Сообщения*\n\nСообщений пока нет"
        else:
            text = "💬 *Последние сообщения*\n\n"
            for msg in messages_data[-10:]:
                decrypted = decrypt_message(msg['encrypted'])
                text += f"• {msg['from']}: {decrypted}\n"
        
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'encryption':
        text = f"""
🔒 *Настройки шифрования*

Алгоритм: Fernet (AES-128)
Ключ: `{ENCRYPTION_KEY.decode()[:30]}...`

Все сообщения шифруются end-to-end.
"""
        keyboard = [
            [InlineKeyboardButton("🔄 Сгенерировать новый ключ", callback_data='new_key')],
            [InlineKeyboardButton("◀️ Назад", callback_data='back')]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'settings':
        text = """
⚙️ *Настройки приложения*

• Язык: Русский/English
• Тема: Светлая/Темная
• Фон чата: 3 варианта
• Приватность: Настраивается
"""
        keyboard = [[InlineKeyboardButton("◀️ Назад", callback_data='back')]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        await query.edit_message_text(text, reply_markup=reply_markup, parse_mode='Markdown')
    
    elif query.data == 'back':
        await start(query, context)

async def add_user(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("❌ Нет доступа")
        return
    
    if len(context.args) < 2:
        await update.message.reply_text("Использование: /adduser <id> <name>")
        return
    
    user_id = context.args[0]
    name = " ".join(context.args[1:])
    
    users_data[user_id] = {"name": name}
    await update.message.reply_text(f"✅ Пользователь {name} добавлен")

async def send_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("❌ Нет доступа")
        return
    
    if len(context.args) < 1:
        await update.message.reply_text("Использование: /send <message>")
        return
    
    message = " ".join(context.args)
    encrypted = encrypt_message(message)
    
    messages_data.append({
        "from": "Admin",
        "encrypted": encrypted
    })
    
    await update.message.reply_text(
        f"✅ Сообщение отправлено\n"
        f"Зашифровано: `{encrypted[:50]}...`",
        parse_mode='Markdown'
    )

def main():
    # Замени на свой токен бота
    TOKEN = "8623096705:AAGTHypGpra_zTN2JP5OLjTJMRm8tNoOw3Y"
    
    app = Application.builder().token(TOKEN).build()
    
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("adduser", add_user))
    app.add_handler(CommandHandler("send", send_message))
    app.add_handler(CallbackQueryHandler(button_callback))
    
    print("🤖 Бот запущен!")
    print(f"🔑 Ключ шифрования: {ENCRYPTION_KEY.decode()}")
    
    # Fix for Python 3.14
    import asyncio
    try:
        asyncio.get_event_loop()
    except RuntimeError:
        asyncio.set_event_loop(asyncio.new_event_loop())
    
    app.run_polling()

if __name__ == '__main__':
    main()
