"""
Скрипт для создания сессий аккаунтов.
Запусти этот скрипт для каждого аккаунта, который хочешь добавить.
"""
import asyncio
import os
import sys
from telethon import TelegramClient
from telethon.errors import SessionPasswordNeededError
import config

async def create_session(session_name):
    # Создаем папку для сессий
    os.makedirs("sessions", exist_ok=True)
    
    client = TelegramClient(
        f"sessions/{session_name}",
        config.API_ID,
        config.API_HASH
    )
    
    print("Подключаюсь...")
    await client.connect()
    
    if not await client.is_user_authorized():
        phone = input("Введи номер телефона (с +): ").strip()
        await client.send_code_request(phone)
        
        try:
            code = input("Введи код из Telegram: ").strip()
            await client.sign_in(phone, code)
        except SessionPasswordNeededError:
            password = input("Введи пароль 2FA: ").strip()
            await client.sign_in(password=password)
    
    me = await client.get_me()
    print(f"\n✅ Сессия создана!")
    print(f"Аккаунт: {me.first_name} (@{me.username})")
    print(f"Файл сессии: sessions/{session_name}.session")
    print(f"\nДобавь '{session_name}' в список SESSIONS в config.py")
    
    await client.disconnect()

def main():
    print("=== Создание сессии ===\n")
    session_name = input("Введи имя для сессии (например: account1): ").strip()
    
    if not session_name:
        print("Имя сессии не может быть пустым!")
        return
    
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        loop.run_until_complete(create_session(session_name))
    except KeyboardInterrupt:
        print("\nОтменено")
    except Exception as e:
        print(f"\n❌ Ошибка: {e}")
    finally:
        loop.close()
    
    input("\nНажми Enter чтобы закрыть...")

if __name__ == "__main__":
    main()
