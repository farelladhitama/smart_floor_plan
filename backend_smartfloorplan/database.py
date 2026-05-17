import sqlite3
from werkzeug.security import generate_password_hash

DATABASE_NAME = "smartfloorplan.db"


def get_db_connection():
    conn = sqlite3.connect(DATABASE_NAME)
    conn.row_factory = sqlite3.Row
    return conn


def init_database():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS floorplans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            land_width REAL NOT NULL,
            land_length REAL NOT NULL,
            material TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            floorplan_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            x REAL NOT NULL,
            y REAL NOT NULL,
            width REAL NOT NULL,
            height REAL NOT NULL,
            FOREIGN KEY (floorplan_id) REFERENCES floorplans (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS rabs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            floorplan_id INTEGER NOT NULL,
            total_area REAL NOT NULL,
            total_price REAL NOT NULL,
            foundation_cost REAL NOT NULL,
            wall_cost REAL NOT NULL,
            roof_cost REAL NOT NULL,
            floor_cost REAL NOT NULL,
            finishing_cost REAL NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (floorplan_id) REFERENCES floorplans (id)
        )
    """)

    conn.commit()
    conn.close()

    print("Database dan tabel berhasil dibuat.")


def seed_admin_user():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM users WHERE email = ?",
        ("admin@smartfloorplan.com",),
    )

    existing_user = cursor.fetchone()

    if existing_user is None:
        hashed_password = generate_password_hash("admin123")

        cursor.execute("""
            INSERT INTO users (name, email, password)
            VALUES (?, ?, ?)
        """, ("Admin SmartFloorPlan", "admin@smartfloorplan.com", hashed_password))

        conn.commit()
        print("User admin berhasil dibuat.")
    else:
        print("User admin sudah ada.")

    conn.close()


if __name__ == "__main__":
    init_database()
    seed_admin_user()