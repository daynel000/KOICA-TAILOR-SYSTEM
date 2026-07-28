"""
app.py — TailorSystem Flask Backend (Supabase Edition)
Separated Accounts: 'customers' and 'tailors' tables.
"""
import os
import json
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS

# Load .env
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# OpenAI for AI body scan
try:
    from openai import OpenAI as _OpenAI
    _openai_client = _OpenAI(api_key=os.environ.get('OPENAI_API_KEY', ''))
except Exception:
    _openai_client = None

# Supabase helpers
from database import (
    sb_select, sb_insert, sb_update, sb_delete,
    sb_auth_sign_up, sb_auth_sign_in, sb_auth_get_user,
    get_client,
)

app = Flask(__name__)
CORS(app)


def _get_user_id_from_token(req) -> str | None:
    auth = req.headers.get('Authorization', '')
    if not auth.startswith('Bearer '):
        return None
    token = auth.replace('Bearer ', '').strip()
    try:
        user_resp = sb_auth_get_user(token)
        if user_resp and user_resp.user:
            return str(user_resp.user.id)
    except Exception:
        pass
    return None

def _ok(data):
    return jsonify({'status': 'success', 'data': data})

def _err(msg, code=400):
    return jsonify({'status': 'error', 'message': msg}), code


# ─── AUTH ENDPOINTS ───────────────────────────────────────────────────────────

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.json or {}
    email      = (data.get('email_address') or data.get('email') or '').strip()
    password   = (data.get('password') or '')
    full_name  = (data.get('full_name') or '').strip()
    phone      = (data.get('phone_number') or '').strip()
    city       = (data.get('city_location') or '').strip()
    is_tailor  = bool(data.get('is_tailor', False))
    shop_name  = (data.get('shop_name') or '').strip()

    if not all([email, password, full_name, phone]):
        return _err('email_address, password, full_name, and phone_number are required.')

    if is_tailor and not shop_name:
        return _err('shop_name is required for tailor accounts.')

    try:
        resp = sb_auth_sign_up(
            email=email,
            password=password,
            metadata={
                'full_name':    full_name,
                'phone_number': phone,
                'is_tailor':    is_tailor,
                'city_location': city,
                'shop_name':    shop_name,
            },
        )
    except Exception as e:
        return _err(str(e))

    if not resp or not resp.user:
        return _err('Registration failed. Please try again.')

    user_id = str(resp.user.id)

    return jsonify({
        'status': 'success',
        'message': 'Account created! Please check your email to verify your account before logging in.',
        'auth_token': resp.session.access_token if resp.session else None,
        'customer': {
            'customer_id':   user_id,
            'full_name':     full_name,
            'email_address': email,
            'phone_number':  phone,
            'city_location': city,
            'avatar_image_url': '',
            'account_tier':  'tailor' if is_tailor else 'standard',
            'member_since':  str(datetime.now().year),
        },
        'data': {
            'user_id':    user_id,
            'profile_id': user_id,
            'is_tailor':  is_tailor,
            'full_name':  full_name,
            'email':      email,
        },
    })


@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.json or {}
    email    = (data.get('email_address') or data.get('email') or '').strip()
    password = (data.get('password') or '')

    if not email or not password:
        return _err('email_address and password are required.', 400)

    try:
        resp = sb_auth_sign_in(email=email, password=password)
    except Exception as e:
        msg = str(e)
        if 'Email not confirmed' in msg:
            return _err('Please verify your email first. Check your inbox for the confirmation link.', 401)
        return _err('Invalid email or password.', 401)

    if not resp or not resp.user or not resp.session:
        return _err('Invalid email or password.', 401)

    user_id    = str(resp.user.id)
    jwt_token  = resp.session.access_token

    # Check if tailor
    tailor_rows = sb_select('tailors', {'id': user_id})
    if tailor_rows:
        is_tailor = True
        p = tailor_rows[0]
        shop_name = p.get('shop_name', '')
    else:
        customer_rows = sb_select('customers', {'id': user_id})
        p = customer_rows[0] if customer_rows else {}
        shop_name = ''
        
        # Fallback to metadata if DB rows are missing entirely
        is_tailor = False
        if not customer_rows and resp.user.user_metadata:
            is_tailor = bool(resp.user.user_metadata.get('is_tailor', False))

    # Fallback to Supabase Auth metadata if the database trigger failed
    full_name  = p.get('full_name', '')
    if not full_name and resp.user.user_metadata:
        full_name = resp.user.user_metadata.get('full_name', '')

    phone      = p.get('phone_number', '')
    city       = p.get('city_location', '')
    
    # If it was actually a tailor (via fallback), ensure we get shop_name
    if is_tailor and not shop_name and resp.user.user_metadata:
        shop_name = resp.user.user_metadata.get('shop_name', '')

    return jsonify({
        'status': 'success',
        'auth_token': jwt_token,
        'customer': {
            'customer_id':    user_id,
            'full_name':      full_name,
            'email_address':  email,
            'phone_number':   phone,
            'city_location':  city,
            'avatar_image_url': '',
            'account_tier':   'tailor' if is_tailor else 'standard',
            'member_since':   str(datetime.now().year),
        },
        'data': {
            'user_id':    user_id,
            'profile_id': user_id,
            'is_tailor':  is_tailor,
            'full_name':  full_name,
            'shop_name':  shop_name,
            'email':      email,
            'phone_number': phone,
        },
    })


# ─── CUSTOMER PROFILE ─────────────────────────────────────────────────────────

@app.route('/api/customer/me', methods=['GET'])
def get_customer_me():
    user_id = _get_user_id_from_token(request)
    if not user_id:
        return _err('Unauthorized', 401)

    # They could be a tailor using the customer app, so check both
    rows = sb_select('customers', {'id': user_id})
    if not rows:
        rows = sb_select('tailors', {'id': user_id})
        if not rows:
            return _err('User not found', 404)
        is_tailor = True
    else:
        is_tailor = False

    p = rows[0]
    return jsonify({
        'customer_id':    user_id,
        'full_name':      p.get('full_name', ''),
        'email_address':  '',
        'phone_number':   p.get('phone_number', ''),
        'city_location':  p.get('city_location', '') if not is_tailor else p.get('address', ''),
        'avatar_image_url': p.get('avatar_url', '') if not is_tailor else p.get('store_picture', ''),
        'account_tier':   'tailor' if is_tailor else 'standard',
        'member_since':   str(p.get('created_at', ''))[:4] or str(datetime.now().year),
    })


# ─── TAILOR PROFILE ───────────────────────────────────────────────────────────

@app.route('/api/profile/<tailor_id>', methods=['GET'])
def get_tailor_profile(tailor_id):
    rows = sb_select('tailors', {'id': tailor_id})
    if not rows:
        return _err('Profile not found', 404)
    return _ok(rows[0])

@app.route('/api/profile/<tailor_id>', methods=['PUT'])
def update_tailor_profile(tailor_id):
    data       = request.json or {}
    shop_name  = (data.get('shop_name') or '').strip()
    bio        = (data.get('bio') or '').strip()
    address    = (data.get('address') or '').strip()
    phone      = (data.get('phone_number') or '').strip()
    skills     = data.get('skills', [])
    lat        = data.get('location_lat')
    lng        = data.get('location_lng')

    update_payload = {
        'shop_name': shop_name,
        'bio':       bio,
        'address':   address,
        'phone_number': phone,
        'skills':    skills if isinstance(skills, list) else [],
        'updated_at': datetime.utcnow().isoformat(),
    }
    
    if lat is not None and lng is not None:
        update_payload['location_lat'] = float(lat)
        update_payload['location_lng'] = float(lng)

    sb_update('tailors', update_payload, {'id': tailor_id})

    return jsonify({'status': 'success', 'message': 'Profile updated successfully'})

import uuid

@app.route('/api/tailors/<tailor_id>/store-picture', methods=['POST'])
def upload_store_picture(tailor_id):
    if 'image' not in request.files:
        return _err('No image provided')
    
    file = request.files['image']
    if file.filename == '':
        return _err('No selected file')
        
    client = get_client()
    try:
        # Generate unique filename
        ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else 'jpg'
        filename = f"{tailor_id}/store_{uuid.uuid4().hex}.{ext}"
        
        file_bytes = file.read()
        client.storage.from_('tailor-images').upload(
            file=file_bytes, 
            path=filename, 
            file_options={"content-type": file.content_type}
        )
        
        public_url = client.storage.from_('tailor-images').get_public_url(filename)
        
        # Update db
        sb_update('tailors', {'store_picture': public_url}, {'id': tailor_id})
        
        return _ok({'store_picture': public_url})
    except Exception as e:
        return _err(str(e))

@app.route('/api/tailors/<tailor_id>/portfolio', methods=['POST'])
def upload_portfolio_photo(tailor_id):
    if 'image' not in request.files:
        return _err('No image provided')
    
    file = request.files['image']
    if file.filename == '':
        return _err('No selected file')
        
    client = get_client()
    try:
        ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else 'jpg'
        filename = f"{tailor_id}/portfolio_{uuid.uuid4().hex}.{ext}"
        
        file_bytes = file.read()
        client.storage.from_('tailor-images').upload(
            file=file_bytes, 
            path=filename, 
            file_options={"content-type": file.content_type}
        )
        
        public_url = client.storage.from_('tailor-images').get_public_url(filename)
        
        # Get current portfolio
        rows = sb_select('tailors', {'id': tailor_id})
        if not rows:
            return _err('Tailor not found')
            
        current_portfolio = rows[0].get('portfolio_photos', [])
        if not isinstance(current_portfolio, list):
            current_portfolio = []
            
        current_portfolio.append(public_url)
        sb_update('tailors', {'portfolio_photos': current_portfolio}, {'id': tailor_id})
        
        return _ok({'portfolio_photos': current_portfolio})
    except Exception as e:
        return _err(str(e))

@app.route('/api/tailors/<tailor_id>/portfolio', methods=['DELETE'])
def delete_portfolio_photo(tailor_id):
    data = request.json or {}
    url_to_delete = data.get('url')
    if not url_to_delete:
        return _err('url is required')
        
    try:
        rows = sb_select('tailors', {'id': tailor_id})
        if not rows:
            return _err('Tailor not found')
            
        current_portfolio = rows[0].get('portfolio_photos', [])
        if not isinstance(current_portfolio, list):
            current_portfolio = []
            
        if url_to_delete in current_portfolio:
            current_portfolio.remove(url_to_delete)
            sb_update('tailors', {'portfolio_photos': current_portfolio}, {'id': tailor_id})
            
            # Optionally delete from storage as well
            # filename = url_to_delete.split('/tailor-images/')[-1]
            # client.storage.from_('tailor-images').remove([filename])
            
        return _ok({'portfolio_photos': current_portfolio})
    except Exception as e:
        return _err(str(e))


# ─── DASHBOARD ────────────────────────────────────────────────────────────────

@app.route('/api/dashboard/<tailor_id>', methods=['GET'])
def get_dashboard(tailor_id):
    # Fetch active and completed orders
    client = get_client()
    try:
        # Get active orders
        res_active = client.table('orders').select('*').eq('tailor_id', tailor_id).neq('status', 'completed').neq('status', 'cancelled').execute()
        active_count = len(res_active.data) if res_active.data else 0
        
        # Get completed orders
        res_completed = client.table('orders').select('*').eq('tailor_id', tailor_id).eq('status', 'completed').execute()
        completed_count = len(res_completed.data) if res_completed.data else 0
        
        # Get recent orders
        res_recent = client.table('orders').select('*, customer:customers(*)').eq('tailor_id', tailor_id).order('created_at', desc=True).limit(5).execute()
        recent_orders = res_recent.data if res_recent.data else []
        
        # Format recent orders for the UI
        formatted_recent = []
        for o in recent_orders:
            cust = o.get('customer', {}) or {}
            formatted_recent.append({
                'id': o.get('id'),
                'customer_name': cust.get('full_name', 'Unknown Customer'),
                'clothing_type': o.get('garment_type', ''),
                'status': o.get('status', 'pending'),
                'date': o.get('created_at', ''),
                'price': 0.0, # Placeholder
                'progress_percent': 100 if o.get('status') == 'completed' else (50 if o.get('status') == 'in_progress' else 0)
            })

        return _ok({
            'active_orders': active_count,
            'this_week': completed_count,
            'recent_orders': formatted_recent
        })
    except Exception as e:
        print("Dashboard error:", e)
        return _err(str(e))

# ─── ORDERS ───────────────────────────────────────────────────────────────────

@app.route('/api/orders/<tailor_id>', methods=['GET'])
def get_orders(tailor_id):
    client = get_client()
    try:
        res = client.table('orders').select('*, customer:customers(*)').eq('tailor_id', tailor_id).order('created_at', desc=True).execute()
        orders = res.data if res.data else []
        
        formatted_orders = []
        for o in orders:
            cust = o.get('customer', {}) or {}
            formatted_orders.append({
                'id': o.get('id'),
                'customer_name': cust.get('full_name', 'Unknown Customer'),
                'clothing_type': o.get('garment_type', ''),
                'status': o.get('status', 'pending'),
                'date': o.get('created_at', ''),
                'price': 0.0,
                'progress_percent': 100 if o.get('status') == 'completed' else (50 if o.get('status') == 'in_progress' else 0)
            })
        return _ok(formatted_orders)
    except Exception as e:
        return _err(str(e))

@app.route('/api/orders/customer_submit', methods=['POST'])
def submit_order():
    data = request.json or {}
    customer_id = data.get('customer_id')
    tailor_id = data.get('tailor_id')
    clothing_type = data.get('clothing_type', 'Custom Garment')
    
    if not customer_id or not tailor_id:
        return _err('customer_id and tailor_id are required')
        
    try:
        res = sb_insert('orders', {
            'customer_id': customer_id,
            'tailor_id': tailor_id,
            'garment_type': clothing_type,
            'status': 'pending'
        })
        if res:
            return _ok({'order_id': res.get('id'), 'message': 'Order submitted'})
        return _err('Failed to insert order')
    except Exception as e:
        return _err(str(e))

@app.route('/api/orders/customer/<customer_id>', methods=['GET'])
def get_customer_orders(customer_id):
    client = get_client()
    try:
        res = client.table('orders').select('*, tailor:tailors(*)').eq('customer_id', customer_id).order('created_at', desc=True).execute()
        orders = res.data if res.data else []
        
        formatted_orders = []
        for o in orders:
            t = o.get('tailor', {}) or {}
            formatted_orders.append({
                'id': o.get('id'),
                'tailor_id': o.get('tailor_id'),
                'tailor_shop_name': t.get('shop_name', 'Tailor'),
                'garment_type': o.get('garment_type', ''),
                'status': o.get('status', 'pending'),
                'created_at': o.get('created_at', ''),
            })
        return _ok(formatted_orders)
    except Exception as e:
        return _err(str(e))

@app.route('/api/orders/<order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    data = request.json or {}
    status = data.get('status', 'pending')
    
    # We could also use progress_percent if we added it to DB schema, but for now just status
    sb_update('orders', {
        'status': status,
        'updated_at': datetime.utcnow().isoformat()
    }, {'id': order_id})
    return _ok({'message': 'Order updated'})

# ─── CHAT ─────────────────────────────────────────────────────────────────────

@app.route('/api/chat/<order_id>', methods=['GET'])
def get_chat_messages(order_id):
    client = get_client()
    try:
        # Check if thread exists for this order. We need customer and tailor id from the order
        res_order = client.table('orders').select('*').eq('id', order_id).execute()
        if not res_order.data:
            return _ok([])
        
        order = res_order.data[0]
        c_id = order['customer_id']
        t_id = order['tailor_id']
        
        # Get thread
        res_thread = client.table('chat_threads').select('*').eq('customer_id', c_id).eq('tailor_id', t_id).execute()
        if not res_thread.data:
            return _ok([])
            
        thread_id = res_thread.data[0]['id']
        
        # Get messages
        res_msgs = client.table('messages').select('*').eq('thread_id', thread_id).order('created_at', desc=False).execute()
        msgs = res_msgs.data if res_msgs.data else []
        
        formatted_msgs = []
        for m in msgs:
            formatted_msgs.append({
                'id': m['id'],
                'text': m['message_text'],
                'sender_type': m['sender_type'],
                'created_at': m['created_at'],
                'is_read': m['is_read']
            })
        return _ok(formatted_msgs)
    except Exception as e:
        return _err(str(e))

@app.route('/api/chat/<order_id>', methods=['POST'])
def send_chat_message(order_id):
    data = request.json or {}
    sender_id = data.get('sender_id')
    text = data.get('message_text', '')
    
    if not text:
        return _err("Message text is empty", 400)
        
    client = get_client()
    try:
        # Get order to find customer and tailor
        res_order = client.table('orders').select('*').eq('id', order_id).execute()
        if not res_order.data:
            return _err("Order not found", 404)
            
        order = res_order.data[0]
        c_id = order['customer_id']
        t_id = order['tailor_id']
        
        # Determine sender_type based on whether sender_id is customer or tailor
        sender_type = 'tailor' if str(sender_id) == str(t_id) else 'customer'
        
        # Find or create thread
        res_thread = client.table('chat_threads').select('*').eq('customer_id', c_id).eq('tailor_id', t_id).execute()
        if not res_thread.data:
            thread_res = client.table('chat_threads').insert({
                'customer_id': c_id,
                'tailor_id': t_id
            }).execute()
            thread_id = thread_res.data[0]['id']
        else:
            thread_id = res_thread.data[0]['id']
            
        # Insert message
        msg_res = client.table('messages').insert({
            'thread_id': thread_id,
            'sender_type': sender_type,
            'message_text': text
        }).execute()
        
        return _ok({'message': 'Sent successfully'})
    except Exception as e:
        return _err(str(e))

# ─── MAP / TAILORS ────────────────────────────────────────────────────────────

@app.route('/api/map/tailors', methods=['GET'])
@app.route('/api/tailors', methods=['GET'])
def get_tailors():
    client = get_client()
    try:
        res = client.table('tailors').select('*').execute()
        tailors = res.data if res.data else []
        return _ok(tailors)
    except Exception as e:
        return _err(str(e))

# ─── RUN ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
