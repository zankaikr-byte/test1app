import sqlite3

# Миграция базы данных для добавления поля username
conn = sqlite3.connect('telegram_clone.db')
c = conn.cursor()

# Проверяем, есть ли уже колонка username
c.execute("PRAGMA table_info(users)")
columns = [column[1] for column in c.fetchall()]

if 'username' not in columns:
    print("Добавляю колонку username...")
    c.execute('ALTER TABLE users ADD COLUMN username TEXT DEFAULT ""')
    conn.commit()
    print("✓ Колонка username добавлена")
else:
    print("✓ Колонка username уже существует")

conn.close()
print("Миграция завершена!")
