-- ==========================================================
-- Migration: 000004_add_user_name_and_username_index.up.sql
-- ProjectNBX: Adiciona campo name e índice para busca por username
-- ==========================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(100) DEFAULT '';

-- Popula o name inicial a partir do username para usuários existentes sem nome
UPDATE users SET name = username WHERE name IS NULL OR name = '';

CREATE INDEX IF NOT EXISTS idx_users_username ON users(LOWER(username));
