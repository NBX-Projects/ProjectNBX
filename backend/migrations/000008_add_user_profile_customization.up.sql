-- ==========================================================
-- Migration: 000008_add_user_profile_customization.up.sql
-- ProjectNBX: Adiciona banner/capa, bio e custom_status ao usuário
-- ==========================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS banner_url TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS custom_status TEXT DEFAULT '';
