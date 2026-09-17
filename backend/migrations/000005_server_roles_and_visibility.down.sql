-- ===================================================
-- Migration: 000005_server_roles_and_visibility.down.sql
-- ===================================================

DROP TABLE IF EXISTS server_join_requests;
DROP TABLE IF EXISTS server_member_roles;
DROP TABLE IF EXISTS server_roles;

ALTER TABLE servers 
DROP COLUMN IF EXISTS category,
DROP COLUMN IF EXISTS description,
DROP COLUMN IF EXISTS is_public;
