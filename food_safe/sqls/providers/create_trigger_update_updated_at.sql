-- Trigger para atualizar automaticamente o campo updated_at em UPDATEs
--
-- Este trigger garante que toda modificação feita na tabela providers
-- atualize automaticamente o campo updated_at para now(), permitindo que
-- a sincronização incremental baseada em updated_at funcione corretamente.
--
-- Como aplicar:
-- 1. Acesse o Supabase Dashboard → SQL Editor
-- 2. Cole e execute este script

-- Função que será chamada pelo trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que chama a função antes de cada UPDATE
DROP TRIGGER IF EXISTS set_updated_at ON providers;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON providers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verificação: após aplicar, edite um registro no Dashboard (Table Editor)
-- e confirme que o campo updated_at foi atualizado automaticamente.
