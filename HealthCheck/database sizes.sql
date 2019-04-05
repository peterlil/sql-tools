-- Database name, Database size, unallocated space, reserved, data, index_size, unused
SET NOCOUNT ON;
create table #stage (
	[Database Name] varchar(500),
	[Database Size (MB)] dec(15,2),
	[Database File(s) Size (kB)] dec(15,2),
	[Log File Size (kB)] dec(15,2),
	[Unallocated Space (MB)] dec(15,2),
	[Reserved Space (kB)] bigint,
	[Data Space (kB)] bigint,
	[Index Space (kB)] bigint,
	[Unused Space (kB)] bigint,
	[Unused Space (%)] int
);
exec master.dbo.sp_msforeachdb N'USE [?]
declare 
	@dbsize bigint,
	@logsize bigint,
	@reservedpages bigint,
	@usedpages bigint,
	@pages bigint;


select 
	@dbsize = sum(convert(bigint,case when status & 64 = 0 then size else 0 end)), 
	@logsize = sum(convert(bigint,case when status & 64 <> 0 then size else 0 end))
  from dbo.sysfiles;

select 
	@reservedpages = sum(a.total_pages),
	@usedpages = sum(a.used_pages),
	@pages = sum(
		CASE
			-- XML-Index and FT-Index-Docid is not considered "data", but is part of "index_size"
			When it.internal_type IN (202,204) Then 0
			When a.type <> 1 Then a.used_pages
			When p.index_id < 2 Then a.data_pages
			Else 0
		END
	)
  from sys.partitions p 
	join sys.allocation_units a on p.partition_id = a.container_id
	left join sys.internal_tables it on p.object_id = it.object_id;

/* unallocated space could not be negative */
/*
	**  Now calculate the summary data.
	**  reserved: sum(reserved) where indid in (0, 1, 255)
	** data: sum(data_pages) + sum(text_used)
	** index: sum(used) where indid in (0, 1, 255) - data
	** unused: sum(reserved) - sum(used) where indid in (0, 1, 255)
	*/
insert into #stage
select 
	[Database Name] = db_name(),
	[Database Size (MB)] = (convert (dec (15,2),@dbsize) + convert (dec (15,2),@logsize)) * 8192 / 1048576,
	[Database File(s) Size (kB)] = convert (dec (15,2),@dbsize) * 8192 / 1024,
	[Log File Size (kB)] = convert (dec (15,2),@logsize) * 8192 / 1024,
	[Unallocated Space (MB)] = case 
		when @dbsize >= @reservedpages then
			(convert (dec (15,2),@dbsize) - convert (dec (15,2),@reservedpages)) * 8192 / 1048576 
		else 0 
		end,
	[Reserved Space (kB)] = @reservedpages * 8192 / 1024.,
	[Data Space (kB)] = @pages * 8192 / 1024.,
	[Index Space (kB)] = (@usedpages - @pages) * 8192 / 1024.,
	[Unused Space (kB)] = (@reservedpages - @usedpages) * 8192 / 1024.,
	[Unused Space (%)] = ROUND(((@reservedpages - @usedpages) * 100 / @reservedpages), 0);';

select * from #stage;
drop table #stage;
