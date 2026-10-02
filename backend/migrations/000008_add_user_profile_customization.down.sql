-- ==========================================================
-- Migration: 000008_add_user_profile_customization.down.sql
-- ProjectNBX: Reverte campos de personalização de perfil
-- ==========================================================

ALTER TABLE users DROP COLUMN IF EXISTS banner_url;
ALTER TABLE users DROP COLUMN IF EXISTS bio;
ALTER TABLE users DROP COLUMN IF EXISTS custom_status;
