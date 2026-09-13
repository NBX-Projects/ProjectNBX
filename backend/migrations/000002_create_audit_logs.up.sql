-- ===================================================
-- Migration: 000002_create_audit_logs.up.sql
-- ProjectNBX System Audit & Activity Logs
-- ===================================================

CREATE TYPE audit_source AS ENUM (
    'AUTH',
    'SERVER',
    'CHANNEL',
    'CHAT',
    'VOICE',
    'USER',
    'SYSTEM',
    'ADMIN'
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(64) PRIMARY KEY,
    source audit_source NOT NULL,
    action VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    resource_id VARCHAR(64),
    ip_address VARCHAR(64),
    user_agent TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_source ON audit_logs(source);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
