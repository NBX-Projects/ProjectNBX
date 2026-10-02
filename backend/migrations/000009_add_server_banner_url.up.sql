-- ProjectNBX: Adiciona banner_url ao servidor
ALTER TABLE servers ADD COLUMN IF NOT EXISTS banner_url TEXT DEFAULT '';
