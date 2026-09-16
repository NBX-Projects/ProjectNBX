-- ==========================================================
-- Migration: 000004_add_user_name_and_username_index.down.sql
-- ==========================================================

DROP INDEX IF EXISTS idx_users_username;
ALTER TABLE users DROP COLUMN IF EXISTS name;
