-- Reversão da adição de colunas de mídia nas mensagens
ALTER TABLE messages DROP COLUMN IF EXISTS media_url;
ALTER TABLE messages DROP COLUMN IF EXISTS media_type;
ALTER TABLE messages ALTER COLUMN content SET NOT NULL;

