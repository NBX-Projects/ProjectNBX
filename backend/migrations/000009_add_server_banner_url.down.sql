-- ProjectNBX: Remove banner_url do servidor
ALTER TABLE servers DROP COLUMN IF EXISTS banner_url;
