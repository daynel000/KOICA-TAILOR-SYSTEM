-- ═══════════════════════════════════════════════════════════════
--   Tailor Connect — Clear All Data
--   Run this in phpMyAdmin to wipe sample data (keeps table structure)
-- ═══════════════════════════════════════════════════════════════

USE tailor_connect_db;

SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM messages;
DELETE FROM reviews;
DELETE FROM tailor_collaborations;
DELETE FROM notifications;
DELETE FROM tailoring_orders;
DELETE FROM tailor_profiles;
DELETE FROM users;

SET FOREIGN_KEY_CHECKS = 1;

-- Done! All tables are now empty.
-- Open the app and register your tailor account to get started.
