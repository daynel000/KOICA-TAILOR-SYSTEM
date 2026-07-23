import mysql.connector
from database import DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME

def insert_dummy_data():
    try:
        connection = mysql.connector.connect(
            host=DATABASE_HOST,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            database=DATABASE_NAME
        )
        cursor = connection.cursor()

        # 1. Insert a Tailor
        cursor.execute("""
            INSERT INTO users (full_name, email, password_hash, is_tailor)
            VALUES ('Gievey Reinz', 'tailor@example.com', 'dummy_hash', TRUE)
        """)
        tailor_user_id = cursor.lastrowid

        cursor.execute("""
            INSERT INTO tailor_profiles (user_id, shop_name, bio, address)
            VALUES (%s, 'Gievey Reinz Tailoring', 'Premium suits and dresses', '123 Fashion St')
        """, (tailor_user_id,))
        tailor_profile_id = cursor.lastrowid

        # 2. Insert a Customer
        cursor.execute("""
            INSERT INTO users (full_name, email, password_hash, is_tailor)
            VALUES ('Jane Doe', 'jane@example.com', 'dummy_hash', FALSE)
        """)
        customer_id = cursor.lastrowid

        # 3. Insert some Orders
        orders = [
            (customer_id, tailor_profile_id, 'Barong Tagalog', 'Classic pineapple fiber barong', 'new', 0),
            (customer_id, tailor_profile_id, 'Evening Gown', 'Red silk gown for prom', 'in_progress', 30),
            (customer_id, tailor_profile_id, 'Business Suit', 'Navy blue 2-piece suit', 'completed', 100)
        ]

        for order in orders:
            cursor.execute("""
                INSERT INTO tailoring_orders (customer_id, tailor_id, clothing_type, clothing_description, status, progress_percent)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, order)

        connection.commit()
        print("✅ Dummy data successfully inserted into the database!")
        print("--> You can now log into the tailor dashboard with:")
        print("    Email: tailor@example.com")
        print("    Password: (anything, since auth isn't fully locked down yet)")

    except mysql.connector.Error as err:
        print(f"Error: {err}")
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()

if __name__ == '__main__':
    insert_dummy_data()
