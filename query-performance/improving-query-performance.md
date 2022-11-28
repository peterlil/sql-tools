# Improving query performance in Azure SQL Database

This article can of course be used on other versions of SQL Server as well, but it has been developed and tested with Azure SQL DB.

## Get an overview

I want to start by getting an overview of the sizes and amount of rows in the tables and indexes of the database.

Execute this query to get the allocated space (MB) (size of the database files) and amount of unused space (MB) within the files.

```sql
SELECT
    type_desc AS TypeOfData,
    CAST(ROUND(SUM(size/128.0), 1) AS DECIMAL(18,1)) AS SpaceAllocatedInMB,
    CAST(ROUND(SUM(FILEPROPERTY(name, 'SpaceUsed'))/128.0, 1) AS DECIMAL(18,1)) AS SpaceUsedInMB,
    CAST(ROUND(SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0),1) AS DECIMAL(18,1)) AS SpaceAllocatedUnusedInMB
FROM sys.database_files
GROUP BY type_desc
```

Get the size information for all the tables in the database and aggregated index sizes per table. 

<details>
    <summary>Expand code block</summary>

```sql
SELECT 
    p.[Table Name],
    SUM (
        CASE
            WHEN (p.index_id < 2) THEN p.row_count
            ELSE 0
        END
        ) AS [# Records],
    SUM (p.reserved_page_count) * 8192 / 1024 AS [Reserved (kB)],
    SUM (p.data_pages) * 8192 / 1024 AS [Data (kB)],
    (
        CASE 
            WHEN SUM (p.used_page_count) > SUM (p.data_pages) THEN (SUM (p.used_page_count) - SUM (p.data_pages)) 
            ELSE 0 
        END
    ) * 8192 / 1024 AS [Indexes (kB)] ,
    (
        CASE 
            WHEN SUM (p.reserved_page_count) > SUM (p.used_page_count) THEN (SUM(p.reserved_page_count) - SUM (p.used_page_count)) 
            ELSE 0 
        END
    ) * 8192 / 1024 AS [Unused (kB)]
FROM
(
    -- User tables
    SELECT
        sch.[name] + N'.' + t.[name] AS [Table Name],
        ps.object_id,
        ps.index_id,
        ps.reserved_page_count,
        sub_ps.data_pages,
        ps.used_page_count,
        ps.row_count
    FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.tables t ON ps.object_id = t.object_id
        INNER JOIN sys.schemas sch ON t.schema_id = sch.schema_id
        INNER JOIN 
        (
            SELECT partition_id, 
                CASE
                    WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                    ELSE ps.lob_used_page_count + ps.row_overflow_used_page_count
                END    AS data_pages
                FROM sys.dm_db_partition_stats ps
        ) sub_ps ON ps.partition_id = sub_ps.partition_id
    UNION
    -- User Views
    SELECT sch.[name] + N'.' + v.[name] AS [Table Name],
            ps.object_id,
            ps.index_id,
            ps.reserved_page_count,
            sub_ps.data_pages,
            ps.used_page_count,
            ps.row_count
    FROM sys.dm_db_partition_stats ps
            INNER JOIN sys.views v ON ps.object_id = v.object_id
            INNER JOIN sys.schemas sch ON v.schema_id = sch.schema_id
            INNER JOIN 
            (
                SELECT partition_id, 
                    CASE
                        WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                        ELSE ps.lob_used_page_count + ps.row_overflow_used_page_count
                    END    AS data_pages
                    FROM sys.dm_db_partition_stats ps
            ) sub_ps ON ps.partition_id = sub_ps.partition_id
    UNION
    -- Internal tables
    SELECT
        sch.[name] + N'.' + t.[name] AS [Table Name], 
        it.parent_id AS object_id,
        0 AS index_id,
        sum(reserved_page_count) AS reserved_page_count,
        0 AS data_pages,
        sum(used_page_count) AS used_page_count,
        0 AS row_count
    FROM sys.dm_db_partition_stats ps
    INNER JOIN sys.internal_tables it ON ps.object_id = it.object_id AND it.internal_type IN (202,204,211,212,213,214,215,216)
    INNER JOIN sys.tables t on it.parent_id = t.object_id
    INNER JOIN sys.schemas sch on t.schema_id = sch.schema_id
    GROUP BY sch.name, t.name, it.parent_id
) P
GROUP BY [Table Name]
ORDER BY[Data (kB)] DESC;
```

</details>

 \
 \
Get the total size of the tables and indexes in the database.

<details>
    <summary>Expand code block</summary>

```sql
SELECT 
    SUM (
        CASE
            WHEN (p.index_id < 2) THEN p.row_count
            ELSE 0
        END
        ) AS [# Records],
    SUM (p.reserved_page_count) * 8192 / 1024 AS [Reserved (kB)],
    SUM (p.data_pages) * 8192 / 1024 AS [Data (kB)],
    (
        CASE 
            WHEN SUM (p.used_page_count) > SUM (p.data_pages) THEN (SUM (p.used_page_count) - SUM (p.data_pages)) 
            ELSE 0 
        END
    ) * 8192 / 1024 AS [Indexes (kB)] ,
    (
        CASE 
            WHEN SUM (p.reserved_page_count) > SUM (p.used_page_count) THEN (SUM(p.reserved_page_count) - SUM (p.used_page_count)) 
            ELSE 0 
        END
    ) * 8192 / 1024 AS [Unused (kB)]
FROM
(
    -- User tables
    SELECT
        sch.[name] + N'.' + t.[name] AS [Table Name],
        ps.object_id,
        ps.index_id,
        ps.reserved_page_count,
        sub_ps.data_pages,
        ps.used_page_count,
        ps.row_count
    FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.tables t ON ps.object_id = t.object_id
        INNER JOIN sys.schemas sch ON t.schema_id = sch.schema_id
        INNER JOIN 
        (
            SELECT partition_id, 
                CASE
                    WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                    ELSE ps.lob_used_page_count + ps.row_overflow_used_page_count
                END    AS data_pages
                FROM sys.dm_db_partition_stats ps
        ) sub_ps ON ps.partition_id = sub_ps.partition_id
    UNION
    -- User Views
    SELECT sch.[name] + N'.' + v.[name] AS [Table Name],
            ps.object_id,
            ps.index_id,
            ps.reserved_page_count,
            sub_ps.data_pages,
            ps.used_page_count,
            ps.row_count
    FROM sys.dm_db_partition_stats ps
            INNER JOIN sys.views v ON ps.object_id = v.object_id
            INNER JOIN sys.schemas sch ON v.schema_id = sch.schema_id
            INNER JOIN 
            (
                SELECT partition_id, 
                    CASE
                        WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                        ELSE ps.lob_used_page_count + ps.row_overflow_used_page_count
                    END    AS data_pages
                    FROM sys.dm_db_partition_stats ps
            ) sub_ps ON ps.partition_id = sub_ps.partition_id
    UNION
    -- Internal tables
    SELECT
        sch.[name] + N'.' + t.[name] AS [Table Name], 
        it.parent_id AS object_id,
        0 AS index_id,
        sum(reserved_page_count) AS reserved_page_count,
        0 AS data_pages,
        sum(used_page_count) AS used_page_count,
        0 AS row_count
    FROM sys.dm_db_partition_stats ps
    INNER JOIN sys.internal_tables it ON ps.object_id = it.object_id AND it.internal_type IN (202,204,211,212,213,214,215,216)
    INNER JOIN sys.tables t on it.parent_id = t.object_id
    INNER JOIN sys.schemas sch on t.schema_id = sch.schema_id
    GROUP BY sch.name, t.name, it.parent_id
) P
```

</details>

 \
 \
Script (most of) the indexes from the database.

<details>
    <summary>Expand code block</summary>

```sql

-- works only in single partition objects
-- supports row and page subscriptions, not columnstore.

declare @SchemaName varchar(100)
declare @TableName varchar(256)
declare @IndexName varchar(256)
declare @ColumnName varchar(100)
declare @is_unique varchar(100)
declare @IndexTypeDesc varchar(100)
declare @FileGroupName varchar(100)
declare @is_disabled varchar(100)
declare @IndexOptions varchar(max)
declare @IndexColumnId int
declare @IsDescendingKey int 
declare @IsIncludedColumn int
declare @data_compression tinyint
declare @TSQLScripCreationIndex varchar(max)
declare @TSQLScripDisableIndex varchar(max)
declare @FilterTable varchar(256) = NULL -- Set this to NULL for all tables or to the name of the table you want the indexes for.


declare CursorIndex cursor for
 select schema_name(t.schema_id) [schema_name], t.name, ix.name,
 case when ix.is_unique = 1 then 'UNIQUE ' else '' END 
 , ix.type_desc,
 case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end
 + case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end
 + case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end
 + case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end
 + case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end
 + CASE data_compression WHEN 1 THEN 'DATA_COMPRESSION = ROW, ' WHEN 2 THEN 'DATA_COMPRESSION = PAGE, ' ELSE '' END
 + CASE WHEN ix.fill_factor > 0 THEN 'FILLFACTOR=' + CAST(ix.fill_factor AS VARCHAR(3)) + ', ' ELSE '' END
 + 'SORT_IN_TEMPDB = OFF, ONLINE=ON' AS IndexOptions
 , ix.is_disabled , FILEGROUP_NAME(ix.data_space_id) FileGroupName,
 par.data_compression
 from sys.tables t 
 inner join sys.indexes ix on t.object_id=ix.object_id
 INNER JOIN sys.partitions par ON t.object_id=par.object_id AND ix.index_id = par.index_id
 where ix.type>0 
 and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
 AND (@FilterTable IS NULL OR t.name=@FilterTable)
 AND par.partition_number=1 -- works only on single partition objects
 order by schema_name(t.schema_id), t.name, ix.name

open CursorIndex
fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions,@is_disabled, @FileGroupName, @data_compression

while (@@fetch_status=0)
begin

  PRINT @SchemaName + '.' + @TableName

 declare @IndexColumns varchar(max)
 declare @IncludedColumns varchar(max)
 
 set @IndexColumns=''
 set @IncludedColumns=''
 
 declare CursorIndexColumn cursor for 
  select col.name, ixc.is_descending_key, ixc.is_included_column
  from sys.tables tb 
  inner join sys.indexes ix on tb.object_id=ix.object_id
  inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id
  inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id
  where ix.type>0 and (ix.is_primary_key=0 or ix.is_unique_constraint=0)
  and schema_name(tb.schema_id)=@SchemaName and tb.name=@TableName and ix.name=@IndexName
  order by ixc.index_column_id
 
 open CursorIndexColumn 
 fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn
 
 while (@@fetch_status=0)
 begin
  if @IsIncludedColumn=0 
   set @IndexColumns=@IndexColumns + @ColumnName  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end
  else 
   set @IncludedColumns=@IncludedColumns  + @ColumnName  +', ' 

  fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn
 end

 close CursorIndexColumn
 deallocate CursorIndexColumn

 set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)
 set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end
 --  print @IndexColumns
 --  print @IncludedColumns

 set @TSQLScripCreationIndex =''
 set @TSQLScripDisableIndex =''
 set @TSQLScripCreationIndex='CREATE '+ @is_unique  +@IndexTypeDesc + ' INDEX ' +QUOTENAME(@IndexName)+' ON ' + QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName)+ '('+@IndexColumns+') '+ 
  case when len(@IncludedColumns)>0 then CHAR(13) +'INCLUDE (' + @IncludedColumns+ ')' else '' end + CHAR(13)+'WITH (' + @IndexOptions+ ') ON ' + QUOTENAME(@FileGroupName) + ';'  

 if @is_disabled=1 
  set  @TSQLScripDisableIndex=  CHAR(13) +'ALTER INDEX ' +QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName) + ' DISABLE;' + CHAR(13) 

 print @TSQLScripCreationIndex
 print @TSQLScripDisableIndex

 fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions,@is_disabled, @FileGroupName, @data_compression

end
close CursorIndex
deallocate CursorIndex
```

</details>

## Tune based on logical reads (focus on reads)

TBD.

Helper code.

```sql
SET STATISTICS IO ON
GO

CHECKPOINT
GO

DBCC DROPCLEANBUFFERS
GO
```
