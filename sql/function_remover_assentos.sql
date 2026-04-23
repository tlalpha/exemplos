CREATE FUNCTION dbo.Lord_RemoverAcentos (@Texto NVARCHAR(MAX))
RETURNS VARCHAR(MAX) -- O resultado será VARCHAR, pois a conversão para remover acentos não é Unicode.
AS
BEGIN
    -- Se o texto de entrada for NULO, retorna NULO.
    IF @Texto IS NULL
        RETURN NULL;
    -- A conversão para um tipo de dados não-Unicode (VARCHAR) com uma collation
    -- Accent-Insensitive (AI) força a remoção dos acentos.
    RETURN CONVERT(NVARCHAR(MAX), CONVERT(VARCHAR(MAX), @Texto COLLATE SQL_Latin1_General_CP1251_CI_AS));
END;
GO
