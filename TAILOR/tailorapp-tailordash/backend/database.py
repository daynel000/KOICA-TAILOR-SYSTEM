import mysql.connector
from mysql.connector import Error

# ─── Database Connection Settings ───────────────────────────────────────────
# Change these values to match your XAMPP MySQL setup
DATABASE_HOST     = "localhost"
DATABASE_USER     = "root"
DATABASE_PASSWORD = ""           # Default XAMPP password is empty
DATABASE_NAME     = "tailor_connect_db"

def create_database_connection():
    """
    Connect to the MySQL database running on XAMPP.
    Returns the connection object if successful, or None if failed.
    """
    try:
        connection = mysql.connector.connect(
            host     = DATABASE_HOST,
            user     = DATABASE_USER,
            password = DATABASE_PASSWORD,
            database = DATABASE_NAME
        )
        return connection

    except Error as error:
        print(f"[Database Error] Could not connect to MySQL: {error}")
        return None


def close_database_connection(connection):
    """
    Safely close the database connection.
    Always call this after you're done with the connection.
    """
    if connection and connection.is_connected():
        connection.close()


def run_query(sql_query, query_values=None):
    """
    Run a SELECT query and return the results as a list of dictionaries.
    Each dictionary represents one row from the database.

    Example:
        rows = run_query("SELECT * FROM orders WHERE tailor_id = %s", (tailor_id,))
    """
    connection = create_database_connection()
    if not connection:
        return []

    try:
        # Use dictionary=True so results come back as {column: value} format
        cursor = connection.cursor(dictionary=True)
        cursor.execute(sql_query, query_values or ())
        result_rows = cursor.fetchall()
        return result_rows

    except Error as error:
        print(f"[Query Error] Failed to run SELECT query: {error}")
        return []

    finally:
        close_database_connection(connection)


def run_insert_or_update(sql_query, query_values=None):
    """
    Run an INSERT, UPDATE, or DELETE query.
    Returns the ID of the last inserted row, or 0 if it's an update/delete.

    Example:
        new_id = run_insert_or_update(
            "INSERT INTO messages (order_id, sender_id, message_text) VALUES (%s, %s, %s)",
            (order_id, sender_id, message_text)
        )
    """
    connection = create_database_connection()
    if not connection:
        return 0

    try:
        cursor = connection.cursor()
        cursor.execute(sql_query, query_values or ())
        connection.commit()  # Save the changes to the database
        return cursor.lastrowid  # Return the ID of the newly inserted row

    except Error as error:
        print(f"[Query Error] Failed to run INSERT/UPDATE query: {error}")
        connection.rollback()  # Undo changes if something went wrong
        return 0

    finally:
        close_database_connection(connection)
