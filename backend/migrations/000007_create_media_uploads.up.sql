-- ===================================================
-- Migration: 000007_create_media_uploads.up.sql
-- Registro de propriedade dos arquivos de mídia enviados (Anti-BOLA)
-- ===================================================

CREATE TABLE IF NOT EXISTS media_uploads (
    url TEXT PRIMARY KEY,
    owner_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    media_type VARCHAR(50) NOT NULL,
    size_bytes BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_media_uploads_owner_id ON media_uploads(owner_id);

-- Recupera a propriedade dos uploads anteriores a partir da auditoria
INSERT INTO media_uploads (url, owner_id, media_type, size_bytes, created_at)
SELECT a.metadata->>'url',
       a.user_id,
       COALESCE(a.metadata->>'mime_type', 'image/jpeg'),
       COALESCE((a.metadata->>'size_bytes')::BIGINT, 0),
       a.created_at
FROM audit_logs a
JOIN users u ON u.id = a.user_id
WHERE a.action = 'UPLOAD_IMAGE'
  AND a.metadata->>'url' IS NOT NULL
ON CONFLICT (url) DO NOTHING;
