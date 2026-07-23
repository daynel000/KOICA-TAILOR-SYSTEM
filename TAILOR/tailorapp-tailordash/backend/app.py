import os
import json
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from database import run_query, run_insert_or_update

app = Flask(__name__)
CORS(app)  # Allow requests from Flutter web (Chrome) and any other origin


# Helper function to format datetime for JSON response
def format_datetime(obj):
    if isinstance(obj, datetime):
        return obj.strftime('%Y-%m-%d %H:%M:%S')
    return obj

# Helper function to process database rows (handle JSON parsing and dates)
def process_rows(rows):
    processed = []
    for row in rows:
        new_row = {}
        for key, value in row.items():
            if isinstance(value, str) and (value.startswith('{') or value.startswith('[')):
                try:
                    new_row[key] = json.loads(value)
                except:
                    new_row[key] = value
            else:
                new_row[key] = format_datetime(value)
        processed.append(new_row)
    return processed


# ─── API ENDPOINTS ────────────────────────────────────────────────────────────

@app.route('/api/dashboard/<int:tailor_id>', methods=['GET'])
def get_dashboard_data(tailor_id):
    """Get statistics for the Home screen"""
    
    # Get active orders count (status not completed or cancelled)
    active_query = "SELECT COUNT(*) as count FROM tailoring_orders WHERE tailor_id = %s AND status NOT IN ('completed', 'cancelled')"
    active_result = run_query(active_query, (tailor_id,))
    active_count = active_result[0]['count'] if active_result else 0

    # Get this week's completed orders (mock implementation for "This Week" stat)
    # In a real app, this would filter by current week's dates
    week_query = "SELECT COUNT(*) as count FROM tailoring_orders WHERE tailor_id = %s"
    week_result = run_query(week_query, (tailor_id,))
    week_count = week_result[0]['count'] if week_result else 0

    # Get recent orders
    recent_query = """
        SELECT o.order_id, o.clothing_type, o.status, u.full_name as customer_name, u.profile_photo as customer_photo
        FROM tailoring_orders o
        JOIN users u ON o.customer_id = u.user_id
        WHERE o.tailor_id = %s
        ORDER BY o.created_at DESC
        LIMIT 5
    """
    recent_orders = process_rows(run_query(recent_query, (tailor_id,)))

    return jsonify({
        "status": "success",
        "data": {
            "active_orders": active_count,
            "this_week": week_count,
            "recent_orders": recent_orders
        }
    })


@app.route('/api/orders/<int:tailor_id>', methods=['GET'])
def get_orders(tailor_id):
    """Get all orders for the tailor"""
    query = """
        SELECT o.*, u.full_name as customer_name, u.profile_photo as customer_photo
        FROM tailoring_orders o
        JOIN users u ON o.customer_id = u.user_id
        WHERE o.tailor_id = %s
        ORDER BY o.due_date ASC
    """
    orders = process_rows(run_query(query, (tailor_id,)))
    
    return jsonify({
        "status": "success",
        "data": orders
    })


@app.route('/api/orders/<int:order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    """Update order status and progress"""
    data = request.json
    status = data.get('status')
    progress = data.get('progress_percent')
    
    query = "UPDATE tailoring_orders SET status = %s, progress_percent = %s WHERE order_id = %s"
    run_insert_or_update(query, (status, progress, order_id))
    
    return jsonify({"status": "success", "message": "Order updated successfully"})


@app.route('/api/chat/<int:order_id>', methods=['GET'])
def get_chat_messages(order_id):
    """Get messages for a specific order"""
    query = """
        SELECT m.*, u.full_name as sender_name, u.profile_photo as sender_photo, u.is_tailor
        FROM messages m
        JOIN users u ON m.sender_id = u.user_id
        WHERE m.order_id = %s
        ORDER BY m.created_at ASC
    """
    messages = process_rows(run_query(query, (order_id,)))
    
    return jsonify({
        "status": "success",
        "data": messages
    })


@app.route('/api/chat/<int:order_id>', methods=['POST'])
def send_message(order_id):
    """Send a new message"""
    data = request.json
    sender_id = data.get('sender_id')
    message_text = data.get('message_text')
    
    query = "INSERT INTO messages (order_id, sender_id, message_text) VALUES (%s, %s, %s)"
    new_id = run_insert_or_update(query, (order_id, sender_id, message_text))
    
    return jsonify({"status": "success", "message_id": new_id})


@app.route('/api/profile/<int:tailor_id>', methods=['GET'])
def get_tailor_profile(tailor_id):
    """Get tailor profile details"""
    query = """
        SELECT tp.*, u.full_name, u.email, u.phone_number, u.location_lat, u.location_lng
        FROM tailor_profiles tp
        JOIN users u ON tp.user_id = u.user_id
        WHERE tp.profile_id = %s
    """
    result = run_query(query, (tailor_id,))
    profile = process_rows(result)[0] if result else None
    
    if profile:
        return jsonify({"status": "success", "data": profile})
    return jsonify({"status": "error", "message": "Profile not found"}), 404


@app.route('/api/map/tailors', methods=['GET'])
def get_nearby_tailors():
    """Get all verified tailors for the map view (for collaboration)"""
    # In a real app, you would pass lat/lng and calculate distance. 
    # For now, we return all verified tailors.
    query = """
        SELECT tp.profile_id, tp.shop_name, tp.rating, tp.skills, u.location_lat, u.location_lng, u.full_name
        FROM tailor_profiles tp
        JOIN users u ON tp.user_id = u.user_id
        WHERE u.is_tailor = TRUE
    """
    tailors = process_rows(run_query(query))
    
    return jsonify({
        "status": "success",
        "data": tailors
    })


@app.route('/api/collaborate', methods=['POST'])
def request_collaboration():
    """Send a collaboration request to another tailor"""
    data = request.json
    requester_id = data.get('requester_tailor_id')
    helper_id = data.get('helper_tailor_id')
    order_id = data.get('order_id')
    message = data.get('request_message')
    
    query = """
        INSERT INTO tailor_collaborations 
        (requester_tailor_id, helper_tailor_id, order_id, request_message) 
        VALUES (%s, %s, %s, %s)
    """
    new_id = run_insert_or_update(query, (requester_id, helper_id, order_id, message))
    
    helper_user_query = "SELECT user_id FROM tailor_profiles WHERE profile_id = %s"
    helper_user_res = run_query(helper_user_query, (helper_id,))
    if helper_user_res:
        helper_user_id = helper_user_res[0]['user_id']
        notif_query = """
            INSERT INTO notifications (user_id, notification_type, title, message, related_order_id)
            VALUES (%s, 'collab_request', 'New Collaboration Request', 'A nearby tailor requested your help.', %s)
        """
        run_insert_or_update(notif_query, (helper_user_id, order_id))
    
    return jsonify({"status": "success", "collaboration_id": new_id})


# ─── AUTH ENDPOINTS ───────────────────────────────────────────────────────────

@app.route('/api/auth/login', methods=['POST'])
def login():
    """Tailor login with email and password"""
    data = request.json
    email = data.get('email', '').strip()
    password = data.get('password', '')

    user_query = """
        SELECT user_id, full_name, email, phone_number
        FROM users
        WHERE email = %s AND password_hash = %s AND is_tailor = TRUE
    """
    users = run_query(user_query, (email, password))

    if not users:
        return jsonify({"status": "error", "message": "Invalid email or password"}), 401

    user = users[0]

    profile_query = "SELECT profile_id, shop_name FROM tailor_profiles WHERE user_id = %s"
    profiles = run_query(profile_query, (user['user_id'],))

    if not profiles:
        return jsonify({"status": "error", "message": "Tailor profile not found"}), 404

    profile = profiles[0]

    return jsonify({
        "status": "success",
        "data": {
            "user_id": user['user_id'],
            "profile_id": profile['profile_id'],
            "full_name": user['full_name'],
            "shop_name": profile['shop_name'],
            "email": user['email'],
            "phone_number": user['phone_number'] or ''
        }
    })


@app.route('/api/auth/register', methods=['POST'])
def register():
    """Register a new tailor account"""
    data = request.json
    full_name = data.get('full_name', '').strip()
    email = data.get('email', '').strip()
    phone = data.get('phone_number', '').strip()
    password = data.get('password', '')
    shop_name = data.get('shop_name', '').strip()
    address = data.get('address', '').strip()

    if not all([full_name, email, password, shop_name]):
        return jsonify({"status": "error", "message": "Name, email, password, and shop name are required"}), 400

    existing = run_query("SELECT user_id FROM users WHERE email = %s", (email,))
    if existing:
        return jsonify({"status": "error", "message": "An account with this email already exists"}), 400

    user_id = run_insert_or_update(
        "INSERT INTO users (full_name, email, phone_number, password_hash, is_tailor) VALUES (%s, %s, %s, %s, TRUE)",
        (full_name, email, phone, password)
    )

    profile_id = run_insert_or_update(
        "INSERT INTO tailor_profiles (user_id, shop_name, address) VALUES (%s, %s, %s)",
        (user_id, shop_name, address)
    )

    return jsonify({
        "status": "success",
        "data": {
            "user_id": user_id,
            "profile_id": profile_id,
            "full_name": full_name,
            "shop_name": shop_name,
            "email": email,
            "phone_number": phone
        }
    })


# ─── ORDER CREATION ───────────────────────────────────────────────────────────

@app.route('/api/orders/create', methods=['POST'])
def create_order():
    """Create a new tailoring order (tailor manually enters customer info)"""
    data = request.json
    tailor_id = data.get('tailor_id')
    customer_name = data.get('customer_name', '').strip()
    customer_phone = data.get('customer_phone', '').strip()
    clothing_type = data.get('clothing_type', '').strip()
    description = data.get('description', '').strip()
    due_date = data.get('due_date') or None
    notes = data.get('notes', '').strip()

    if not all([tailor_id, customer_name, clothing_type]):
        return jsonify({"status": "error", "message": "Tailor ID, customer name, and clothing type are required"}), 400

    # Find existing customer by phone, or create a new one
    if customer_phone:
        existing_customer = run_query(
            "SELECT user_id FROM users WHERE phone_number = %s AND is_tailor = FALSE",
            (customer_phone,)
        )
    else:
        existing_customer = []

    if existing_customer:
        customer_id = existing_customer[0]['user_id']
        # Update name in case it changed
        run_insert_or_update(
            "UPDATE users SET full_name = %s WHERE user_id = %s",
            (customer_name, customer_id)
        )
    else:
        customer_id = run_insert_or_update(
            "INSERT INTO users (full_name, phone_number, password_hash, is_tailor) VALUES (%s, %s, 'customer', FALSE)",
            (customer_name, customer_phone)
        )

    order_id = run_insert_or_update(
        """INSERT INTO tailoring_orders
           (customer_id, tailor_id, clothing_type, clothing_description, notes, status, progress_percent, due_date)
           VALUES (%s, %s, %s, %s, %s, 'new', 0, %s)""",
        (customer_id, tailor_id, clothing_type, description, notes, due_date)
    )

    return jsonify({"status": "success", "order_id": order_id})


# ─── PROFILE UPDATE ───────────────────────────────────────────────────────────

@app.route('/api/profile/<int:tailor_id>', methods=['PUT'])
def update_tailor_profile(tailor_id):
    """Update tailor profile details"""
    data = request.json
    shop_name = data.get('shop_name', '').strip()
    bio = data.get('bio', '').strip()
    address = data.get('address', '').strip()
    phone_number = data.get('phone_number', '').strip()
    skills_list = data.get('skills', [])

    # skills_list comes in as a list (already parsed by Flutter)
    if isinstance(skills_list, list):
        skills_json = json.dumps(skills_list)
    else:
        skills_json = json.dumps([])

    run_insert_or_update(
        """UPDATE tailor_profiles
           SET shop_name = %s, bio = %s, address = %s, skills = %s
           WHERE profile_id = %s""",
        (shop_name, bio, address, skills_json, tailor_id)
    )

    # Also update phone number on the user record
    profile = run_query("SELECT user_id FROM tailor_profiles WHERE profile_id = %s", (tailor_id,))
    if profile:
        run_insert_or_update(
            "UPDATE users SET phone_number = %s WHERE user_id = %s",
            (phone_number, profile[0]['user_id'])
        )

    return jsonify({"status": "success", "message": "Profile updated successfully"})


if __name__ == '__main__':
    # Run the Flask app on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
