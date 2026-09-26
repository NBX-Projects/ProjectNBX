-- Adiciona colunas para anexos de mídia (imagens) nas mensagens de canais
ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_type VARCHAR(50);
ALTER TABLE messages ALTER COLUMN content DROP NOT NULL;

