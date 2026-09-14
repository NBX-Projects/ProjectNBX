-- ===================================================
-- Migration: 000003_create_server_invites.up.sql
-- ProjectNBX Dynamic Server Invites (Temporary & Short Codes)
-- ===================================================

CREATE TABLE IF NOT EXISTS server_invites (
    code VARCHAR(16) PRIMARY KEY,
    server_id VARCHAR(64) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    creator_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    max_uses INT DEFAULT 0,
    uses_count INT DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_server_invites_server_id ON server_invites(server_id);
CREATE INDEX IF NOT EXISTS idx_server_invites_expires_at ON server_invites(expires_at);

