-- ===================================================
-- Migration: 000001_init_schema.down.sql
-- Rollback ProjectNBX Core Tables
-- ===================================================

DROP TABLE IF EXISTS server_members CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS channels CASCADE;
DROP TABLE IF EXISTS servers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
