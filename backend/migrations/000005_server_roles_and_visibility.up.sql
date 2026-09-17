-- ===================================================
-- Migration: 000005_server_roles_and_visibility.up.sql
-- Server Visibility (Public/Private), Join Requests & Roles
-- ===================================================

-- 1. Campos de visibilidade e metadados no servidor
ALTER TABLE servers 
ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS category VARCHAR(64) DEFAULT 'Comunidade Geral';

CREATE INDEX IF NOT EXISTS idx_servers_public ON servers(is_public);

-- 2. Tabela de Cargos do Servidor (Roles)
CREATE TABLE IF NOT EXISTS server_roles (
    id VARCHAR(64) PRIMARY KEY,
    server_id VARCHAR(64) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    color BIGINT DEFAULT 4126743207, -- 0xFFF5CBA7 (Pastel Peach)
    position INT DEFAULT 0,
    permissions JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_server_roles_server ON server_roles(server_id);

-- 3. Associação entre Membros e Cargos
CREATE TABLE IF NOT EXISTS server_member_roles (
    server_id VARCHAR(64) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id VARCHAR(64) NOT NULL REFERENCES server_roles(id) ON DELETE CASCADE,
    PRIMARY KEY (server_id, user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_server_member_roles_user ON server_member_roles(server_id, user_id);

-- 4. Tabela de Solicitações de Entrada (Join Requests para Servidores Públicos)
CREATE TABLE IF NOT EXISTS server_join_requests (
    id VARCHAR(64) PRIMARY KEY,
    server_id VARCHAR(64) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(32) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_by VARCHAR(64) REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_server_user_request UNIQUE (server_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_join_requests_server_status ON server_join_requests(server_id, status);
