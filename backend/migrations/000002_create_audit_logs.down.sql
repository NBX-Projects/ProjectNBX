-- ===================================================
-- Migration: 000002_create_audit_logs.down.sql
-- Rollback Audit Logs Table & Enum
-- ===================================================

DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TYPE IF EXISTS audit_source;
