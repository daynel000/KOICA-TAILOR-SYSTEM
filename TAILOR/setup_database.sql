-- ═══════════════════════════════════════════════════════════════
--   Tailor Connect System — MySQL Database Setup Script
--   Run this file in XAMPP phpMyAdmin or MySQL command line
-- ═══════════════════════════════════════════════════════════════

-- Step 1: Create the database
CREATE DATABASE IF NOT EXISTS tailor_connect_db;
USE tailor_connect_db;


-- ─── TABLE 1: users ──────────────────────────────────────────────────────────
-- Stores all registered users: both tailors and customers
CREATE TABLE IF NOT EXISTS users (
    user_id         INT           AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(150)  NOT NULL UNIQUE,
    phone_number    VARCHAR(20),
    password_hash   VARCHAR(255)  NOT NULL,        -- Hashed password (never store plain text)
    profile_photo   VARCHAR(255),                  -- File path to profile photo
    is_tailor       BOOLEAN       DEFAULT FALSE,   -- TRUE = tailor, FALSE = customer
    location_lat    FLOAT,                         -- GPS latitude of user's location
    location_lng    FLOAT,                         -- GPS longitude of user's location
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- ─── TABLE 2: tailor_profiles ────────────────────────────────────────────────
-- Extra information specific to tailor users (shop details, skills, etc.)
CREATE TABLE IF NOT EXISTS tailor_profiles (
    profile_id      INT           AUTO_INCREMENT PRIMARY KEY,
    user_id         INT           NOT NULL UNIQUE,  -- One tailor profile per user
    shop_name       VARCHAR(200)  NOT NULL,
    bio             TEXT,                           -- Short description of the tailor
    address         VARCHAR(300),                   -- Physical shop address
    skills          JSON,                           -- Example: ["suits", "dresses", "barong"]
    availability    JSON,                           -- Example: {"mon": "9am-5pm", "tue": "9am-5pm"}
    pricing         JSON,                           -- Example: {"suits": 1500, "dresses": 800}
    portfolio_photos JSON,                          -- List of portfolio image URLs
    store_picture   VARCHAR(255),                   -- Main shop/store photo
    rating          FLOAT         DEFAULT 0.0,      -- Average rating (0.0 to 5.0)
    total_reviews   INT           DEFAULT 0,        -- Total number of reviews received
    total_clients   INT           DEFAULT 0,        -- Total number of clients served
    years_experience INT          DEFAULT 0,        -- Years of tailoring experience
    is_verified     BOOLEAN       DEFAULT FALSE,    -- Verified by admin
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ─── TABLE 3: tailoring_orders ───────────────────────────────────────────────
-- Each order/request a customer sends to a tailor
CREATE TABLE IF NOT EXISTS tailoring_orders (
    order_id             INT           AUTO_INCREMENT PRIMARY KEY,
    customer_id          INT           NOT NULL,    -- The customer who placed the order
    tailor_id            INT           NOT NULL,    -- The tailor who received the order
    clothing_type        VARCHAR(100)  NOT NULL,    -- Example: "Barong Tagalog", "Evening Gown"
    clothing_description TEXT,                      -- Additional description from customer
    design_photo         VARCHAR(255),              -- Photo of the clothing design uploaded
    measurements         JSON,                      -- Body measurements (chest, waist, hips, etc.)
    notes                TEXT,                      -- Special instructions from customer
    status               ENUM(
                            'new',
                            'accepted',
                            'rejected',
                            'in_progress',
                            'ready_for_fitting',
                            'completed',
                            'cancelled'
                         )            DEFAULT 'new',
    progress_percent     INT           DEFAULT 0,   -- Progress bar value (0 to 100)
    due_date             DATE,                      -- Target completion date
    cancellation_reason  TEXT,                      -- Reason if order is cancelled
    created_at           DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (tailor_id)   REFERENCES tailor_profiles(profile_id) ON DELETE CASCADE
);


-- ─── TABLE 4: messages ───────────────────────────────────────────────────────
-- Chat messages between tailor and customer (linked to an order)
CREATE TABLE IF NOT EXISTS messages (
    message_id      INT           AUTO_INCREMENT PRIMARY KEY,
    order_id        INT           NOT NULL,         -- Which order this chat belongs to
    sender_id       INT           NOT NULL,         -- Who sent the message
    message_text    TEXT          NOT NULL,         -- The actual message content
    is_read         BOOLEAN       DEFAULT FALSE,    -- Has the receiver read it yet?
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)   REFERENCES tailoring_orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id)  REFERENCES users(user_id) ON DELETE CASCADE
);


-- ─── TABLE 5: notifications ──────────────────────────────────────────────────
-- Alerts sent to tailors (new order, message, status update, etc.)
CREATE TABLE IF NOT EXISTS notifications (
    notification_id   INT           AUTO_INCREMENT PRIMARY KEY,
    user_id           INT           NOT NULL,       -- Who receives this notification
    notification_type VARCHAR(50)   NOT NULL,       -- Example: "new_order", "message", "collab_request"
    title             VARCHAR(200)  NOT NULL,       -- Short title of the notification
    message           TEXT          NOT NULL,       -- Full notification message
    related_order_id  INT,                          -- Optional: linked order
    is_read           BOOLEAN       DEFAULT FALSE,
    created_at        DATETIME      DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)          REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (related_order_id) REFERENCES tailoring_orders(order_id) ON DELETE SET NULL
);


-- ─── TABLE 6: reviews ────────────────────────────────────────────────────────
-- Customer ratings and reviews for completed orders
CREATE TABLE IF NOT EXISTS reviews (
    review_id       INT           AUTO_INCREMENT PRIMARY KEY,
    order_id        INT           NOT NULL UNIQUE,  -- One review per order
    customer_id     INT           NOT NULL,
    tailor_id       INT           NOT NULL,
    rating          INT           NOT NULL,         -- 1 to 5 stars
    comment         TEXT,                           -- Written feedback
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)    REFERENCES tailoring_orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (tailor_id)   REFERENCES tailor_profiles(profile_id) ON DELETE CASCADE
);


-- ─── TABLE 7: tailor_collaborations ──────────────────────────────────────────
-- When a tailor requests help from a nearby tailor (collaboration feature)
CREATE TABLE IF NOT EXISTS tailor_collaborations (
    collaboration_id    INT           AUTO_INCREMENT PRIMARY KEY,
    requester_tailor_id INT           NOT NULL,     -- Tailor who is asking for help
    helper_tailor_id    INT           NOT NULL,     -- Nearby tailor being asked to help
    order_id            INT           NOT NULL,     -- The specific order they need help with
    request_message     TEXT,                       -- Message explaining why they need help
    status              ENUM(
                            'pending',
                            'accepted',
                            'declined'
                        )             DEFAULT 'pending',
    response_message    TEXT,                       -- Helper tailor's response message
    created_at          DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (requester_tailor_id) REFERENCES tailor_profiles(profile_id) ON DELETE CASCADE,
    FOREIGN KEY (helper_tailor_id)    REFERENCES tailor_profiles(profile_id) ON DELETE CASCADE,
    FOREIGN KEY (order_id)            REFERENCES tailoring_orders(order_id) ON DELETE CASCADE
);


-- ─── TABLE 8: customer_profiles ──────────────────────────────────────────────
-- Profile details specific to customer users (preferences, fitting locations, etc.)
CREATE TABLE IF NOT EXISTS customer_profiles (
    profile_id                  INT           AUTO_INCREMENT PRIMARY KEY,
    user_id                     INT           NOT NULL UNIQUE,  -- One customer profile per user
    gender                      VARCHAR(20),
    birthdate                   DATE,
    preferred_clothing_style    VARCHAR(150),
    preferred_fitting_location  VARCHAR(255),
    address                     VARCHAR(300),
    created_at                  DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ─── TABLE 9: customer_measurements ──────────────────────────────────────────
-- Holds the current/active measurements of the customer (both manual overrides and AI calibrated values)
CREATE TABLE IF NOT EXISTS customer_measurements (
    measurement_id     INT           AUTO_INCREMENT PRIMARY KEY,
    user_id            INT           NOT NULL UNIQUE,  -- One measurements record per user
    chest              FLOAT,
    waist              FLOAT,
    hips               FLOAT,
    shoulder           FLOAT,
    sleeve             FLOAT,
    inseam             FLOAT,
    neck               FLOAT,
    height             FLOAT,
    weight             FLOAT,
    measurement_source ENUM('AI', 'Manual') DEFAULT 'Manual',
    confidence_score   FLOAT,                          -- Confidence score from AI scan if applicable
    scan_date          DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ─── TABLE 10: customer_addresses ─────────────────────────────────────────────
-- Multiple saved shipping/fitting addresses for customers
CREATE TABLE IF NOT EXISTS customer_addresses (
    address_id       INT           AUTO_INCREMENT PRIMARY KEY,
    user_id          INT           NOT NULL,
    address_label    VARCHAR(100)  NOT NULL,       -- Example: "Home", "Office", "Billing"
    street_address   VARCHAR(255)  NOT NULL,
    city             VARCHAR(100)  NOT NULL,
    state_province   VARCHAR(100),
    postal_code      VARCHAR(20),
    is_default       BOOLEAN       DEFAULT FALSE,
    created_at       DATETIME      DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ─── TABLE 11: appointments ──────────────────────────────────────────────────
-- Bookings for physical shop visits, design consultations, or fitting schedules
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id   INT           AUTO_INCREMENT PRIMARY KEY,
    customer_id      INT           NOT NULL,       -- Customer booking the appointment
    tailor_id        INT           NOT NULL,       -- Tailor shop being visited
    appointment_date DATE          NOT NULL,
    appointment_time TIME          NOT NULL,
    status           ENUM(
                        'pending',
                        'confirmed',
                        'completed',
                        'cancelled'
                     )             DEFAULT 'pending',
    notes            TEXT,                         -- Special instructions/questions from customer
    created_at       DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (tailor_id)   REFERENCES tailor_profiles(profile_id) ON DELETE CASCADE
);


-- ─── TABLE 12: ai_scan_history ───────────────────────────────────────────────
-- History of AI body scans executed by the customer, retaining photo and JSON records
CREATE TABLE IF NOT EXISTS ai_scan_history (
    scan_id           INT           AUTO_INCREMENT PRIMARY KEY,
    user_id           INT           NOT NULL,
    image_path        VARCHAR(255)  NOT NULL,       -- Uploaded silhouette image path
    measurements_json JSON          NOT NULL,       -- Set of measurements calculated by AI
    confidence_score  FLOAT         NOT NULL,       -- Detection confidence
    scanned_at        DATETIME      DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ─── TABLE 13: clothing_preferences ──────────────────────────────────────────
-- Customer customization preferences for fabric, size and fit styles
CREATE TABLE IF NOT EXISTS clothing_preferences (
    preference_id      INT           AUTO_INCREMENT PRIMARY KEY,
    user_id            INT           NOT NULL UNIQUE,  -- One preference record per user
    favorite_colors    JSON,                           -- Array of favorite color names
    fabric_preferences JSON,                           -- Array of preferred fabric materials
    size_preference    VARCHAR(20),                    -- Standard size tag (e.g. "S", "M", "L")
    preferred_fit      ENUM('Slim', 'Regular', 'Loose') DEFAULT 'Regular',
    created_at         DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ═══════════════════════════════════════════════════════════════
--   Database is ready!
--   No sample data — use the app to register and enter real data.
--   To clear all data later, run: clear_data.sql
-- ═══════════════════════════════════════════════════════════════

