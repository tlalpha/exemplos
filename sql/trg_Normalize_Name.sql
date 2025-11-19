SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 Trigger: trg_entity_normalizeName
 Aplica: dbo.func_superTrim, dbo.func_removeracentos e TRIM no campo [Name]
 Disparado: AFTER INSERT, UPDATE
 Comportamento: Em INSERT sempre; em UPDATE somente quando a coluna [Name] for afetada.
 Proteção contra recursão: retorna quando TRIGGER_NESTLEVEL() > 1
*/

CREATE OR ALTER TRIGGER [dbo].[trg_entity_normalizeName]
ON [dbo].[entity]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Evita recursão infinita se a atualização dentro do gatilho disparar o mesmo gatilho
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    -- Se não houver linhas inseridas, nada a fazer
    IF NOT EXISTS(SELECT 1 FROM inserted)
        RETURN;

    -- Em UPDATE queremos agir somente quando a coluna [Name] foi afetada.
    -- Em INSERT sempre aplicamos.
    IF (NOT EXISTS(SELECT 1 FROM deleted)) OR UPDATE([Name])
    BEGIN 
        -- Atualiza somente quando o valor normalizado for diferente do atual,
        -- evitando escritas desnecessárias.
        UPDATE e
        SET [Name] = v.newName
        FROM dbo.[entity] e
        INNER JOIN inserted i ON e.EntityId = i.EntityId
        CROSS APPLY (
            -- v.newName é o valor final normalizado (UPPER + Trim + Sem Acentos)
            SELECT CASE WHEN i.[Name] IS NULL THEN NULL
                        -- O fluxo de normalização permanece o mesmo
                        ELSE dbo.Lord_RemoverAcentos(dbo.Lord_SuperTrim(CONVERT(NVARCHAR(MAX), UPPER(i.[Name]))))
                   END AS 'newName'
        ) v
        -- IMPORTANTE: Aplicamos COLLATE Latin1_General_BIN2 (Collation Binária)
        -- para forçar uma comparação Case-Sensitive e Accent-Sensitive.
        -- Isso garante que 'joão' <> 'JOAO' seja avaliado como TRUE, mesmo que a coluna
        -- [Name] seja Case-Insensitive (CI) ou Accent-Insensitive (AI).
        WHERE (
              (e.[Name] IS NULL AND v.newName IS NOT NULL)
           OR (e.[Name] IS NOT NULL AND v.newName IS NULL)
           -- A correção está nesta linha: forçando a Collation Binária
           OR (e.[Name] IS NOT NULL AND v.newName IS NOT NULL 
               AND CONVERT(VARCHAR(MAX), e.[Name]) COLLATE Latin1_General_BIN2 <> v.newName COLLATE Latin1_General_BIN2)
        );
    END
END

GO
ALTER TABLE [dbo].[entity] ENABLE TRIGGER [trg_entity_normalizeName]
GO
