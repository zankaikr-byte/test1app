from flask import Flask, request, jsonify
from flask_cors import CORS
from cryptography.fernet import Fernet
import json
import os

app = Flask(__name__)
CORS(app)

# Shared data with bot
DATA_FILE = 'users_data.json'
MESSAGES_FILE = 'messages_data.json'

# Encryption
ENCRYPTION_KEY = Fernet.generate_key()
cipher = Fernet(ENCRYPTION_KEY)

user_counter = 1

def load_data():
    users = {}
    messages = []
    
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    
    if os.path.exists(MESSAGES_FILE):
        with open(MESSAGES_FILE, 'r', encoding='utf-8') as f:
            messages = json.load(f)
    
    return users, messages

def save_data(users, messages):
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, ensure_ascii=False, indent=2)
    
    with open(MESSAGES_FILE, 'w', encoding='utf-8') as f:
        json.dump(messages, f, ensure_ascii=False, indent=2)

def encrypt_message(text):
    return cipher.encrypt(text.encode()).decode()

def decrypt_message(encrypted):
    return cipher.decrypt(encrypted.encode()).decode()

@app.route('/api/register', methods=['POST'])
def register():
    global user_counter
    
    data = request.json
    phone = data.get('phone')
    
    if not phone:
        return jsonify({'error': 'Phone required'}), 400
    
    users, messages = load_data()
    
    # Check if already registered
    for user_id, user_data in users.items():
        if user_data.get('phone') == phone:
            return jsonify({
                'user_id': user_data['user_id'],
                'name': user_data['name'],
                'phone': user_data['phone']
            })
    
    # Create new user
    new_user_id = f"+{user_counter}"
    user_counter += 1
    
    telegram_id = str(hash(phone) % 1000000)  # Generate fake telegram ID
    
    users[telegram_id] = {
        'user_id': new_user_id,
        'name': data.get('name', 'User'),
        'phone': phone,
        'telegram_id': telegram_id,
        'is_admin': False
    }
    
    save_data(users, messages)
    
    return jsonify({
        'user_id': new_user_id,
        'name': users[telegram_id]['name'],
        'phone': phone,
        'telegram_id': telegram_id
    })

@app.route('/api/search', methods=['GET'])
def search():
    query = request.args.get('q', '').lower()
    
    if not query:
        return jsonify([])
    
    users, _ = load_data()
    results = []
    
    for user_data in users.values():
        if query in user_data.get('name', '').lower() or query in user_data.get('user_id', ''):
            results.append({
                'user_id': user_data['user_id'],
                'name': user_data['name'],
                'phone': user_data['phone']
            })
    
    return jsonify(results[:10])

@app.route('/api/send', methods=['POST'])
def send_message():
    data = request.json
    from_id = data.get('from')
    to_id = data.get('to')
    text = data.get('text')
    
    if not all([from_id, to_id, text]):
        return jsonify({'error': 'Missing fields'}), 400
    
    users, messages = load_data()
    
    # Find users
    from_telegram_id = None
    to_telegram_id = None
    
    for tid, user_data in users.items():
        if user_data['user_id'] == from_id:
            from_telegram_id = tid
        if user_data['user_id'] == to_id:
            to_telegram_id = tid
    
    if not from_telegram_id or not to_telegram_id:
        return jsonify({'error': 'User not found'}), 404
    
    # Encrypt and save
    encrypted = encrypt_message(text)
    messages.append({
        'from_id': from_telegram_id,
        'to_id': to_telegram_id,
        'text': text,
        'encrypted': encrypted
    })
    
    save_data(users, messages)
    
    return jsonify({'success': True})

@app.route('/api/messages/<user_id>', methods=['GET'])
def get_messages(user_id):
    users, messages = load_data()
    
    # Find telegram ID
    telegram_id = None
    for tid, user_data in users.items():
        if user_data['user_id'] == user_id:
            telegram_id = tid
            break
    
    if not telegram_id:
        return jsonify([])
    
    # Get messages
    user_messages = []
    for msg in messages:
        if msg['to_id'] == telegram_id or msg['from_id'] == telegram_id:
            user_messages.append({
                'from': msg['from_id'],
                'to': msg['to_id'],
                'text': msg['text']
            })
    
    return jsonify(user_messages)

if __name__ == '__main__':
    print("🚀 API Server запущен на http://localhost:5000")
    print(f"🔑 Ключ шифрования: {ENCRYPTION_KEY.decode()}")
    app.run(host='0.0.0.0', port=5000, debug=True)
