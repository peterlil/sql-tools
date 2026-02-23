;WITH idx AS
(
    SELECT
        i.object_id,
        i.index_id,
        s.name AS schema_name,
        o.name AS table_name,
        i.name AS index_name,
        i.type_desc,
        i.is_unique,
        i.has_filter,
        i.filter_definition,
        i.fill_factor,
        i.is_padded,
        i.ignore_dup_key,
        i.allow_row_locks,
        i.allow_page_locks,
        i.data_space_id,
        ds.name AS data_space_name
    FROM sys.indexes i
    JOIN sys.objects o
        ON o.object_id = i.object_id
    JOIN sys.schemas s
        ON s.schema_id = o.schema_id
    LEFT JOIN sys.data_spaces ds
        ON ds.data_space_id = i.data_space_id
    WHERE
        o.type = 'U'
        AND i.index_id > 0                  -- exclude heaps
        AND i.type IN (1,2)                 -- clustered/nonclustered
        AND i.is_hypothetical = 0
),
cols AS
(
    SELECT
        ic.object_id,
        ic.index_id,

        key_columns =
            STUFF((
                SELECT
                    N', ' + QUOTENAME(c.name) +
                    CASE WHEN ic2.is_descending_key = 1 THEN N' DESC' ELSE N' ASC' END
                FROM sys.index_columns ic2
                JOIN sys.columns c
                    ON c.object_id = ic2.object_id
                   AND c.column_id = ic2.column_id
                WHERE
                    ic2.object_id = ic.object_id
                    AND ic2.index_id = ic.index_id
                    AND ic2.is_included_column = 0
                ORDER BY ic2.key_ordinal
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N''),

        include_columns =
            STUFF((
                SELECT
                    N', ' + QUOTENAME(c.name)
                FROM sys.index_columns ic3
                JOIN sys.columns c
                    ON c.object_id = ic3.object_id
                   AND c.column_id = ic3.column_id
                WHERE
                    ic3.object_id = ic.object_id
                    AND ic3.index_id = ic.index_id
                    AND ic3.is_included_column = 1
                ORDER BY ic3.index_column_id
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N'')
    FROM sys.index_columns ic
    GROUP BY ic.object_id, ic.index_id
)
SELECT
    CreateIndexStatement =
        CONCAT(
            N'CREATE ',
            CASE WHEN i.is_unique = 1 THEN N'UNIQUE ' ELSE N'' END,
            CASE WHEN i.type_desc = 'CLUSTERED' THEN N'CLUSTERED ' ELSE N'NONCLUSTERED ' END,
            N'INDEX ', QUOTENAME(i.index_name),
            N' ON ', QUOTENAME(i.schema_name), N'.', QUOTENAME(i.table_name),
            N' (', c.key_columns, N')',

            CASE
                WHEN NULLIF(c.include_columns, N'') IS NOT NULL
                THEN CONCAT(N' INCLUDE (', c.include_columns, N')')
                ELSE N''
            END,

            CASE
                WHEN i.has_filter = 1 THEN CONCAT(N' WHERE ', i.filter_definition)
                ELSE N''
            END,

            N' WITH (',
                N'PAD_INDEX = ', CASE WHEN i.is_padded = 1 THEN N'ON' ELSE N'OFF' END,
                N', FILLFACTOR = ', CAST(CASE WHEN i.fill_factor = 0 THEN 100 ELSE i.fill_factor END AS nvarchar(3)),
                N', IGNORE_DUP_KEY = ', CASE WHEN i.ignore_dup_key = 1 THEN N'ON' ELSE N'OFF' END,
                N', ALLOW_ROW_LOCKS = ', CASE WHEN i.allow_row_locks = 1 THEN N'ON' ELSE N'OFF' END,
                N', ALLOW_PAGE_LOCKS = ', CASE WHEN i.allow_page_locks = 1 THEN N'ON' ELSE N'OFF' END,
            N')',

            CASE
                WHEN i.data_space_name IS NOT NULL THEN CONCAT(N' ON ', QUOTENAME(i.data_space_name))
                ELSE N''
            END,

            N';'
        )
FROM idx i
JOIN cols c
  ON c.object_id = i.object_id
 AND c.index_id  = i.index_id
ORDER BY
    i.schema_name, i.table_name,
    CASE WHEN i.type_desc = 'CLUSTERED' THEN 0 ELSE 1 END,
    i.index_name;
