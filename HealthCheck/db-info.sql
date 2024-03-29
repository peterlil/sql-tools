/*
Works on:
	*
Does not work on:
	Azure SQL DB
*/
DECLARE @dbname sysname

declare @exec_stmt nvarchar(625)
declare @showdev	bit
declare @name           sysname
declare @cmd	nvarchar(279)
declare @low nvarchar(11)
declare @dbdesc varchar(600)	/* the total description for the db */
declare @propdesc varchar(40)

set nocount on

/*	Create temp table before any DMP to enure dynamic
**  Since we examine the status bits in sysdatabase and turn them
**  into english, we need a temporary table to build the descriptions.
*/
create table #spdbdesc
(
	dbname sysname,
	owner sysname null,
	created nvarchar(11),
	dbid	smallint,
	dbdesc	nvarchar(600)	null,
	dbsize		nvarchar(13) null,
	cmptlevel	tinyint
)


/*
**  If no database name given, get 'em all.
*/
if @dbname is null
	select @showdev = 0
else select @showdev = 1

select @low = convert(varchar(11),low) from master.dbo.spt_values
			where type = N'E' and number = 1
/*
**  Initialize #spdbdesc from sysdatabases
*/
insert into #spdbdesc (dbname, owner, created, dbid, cmptlevel)
		select name, suser_sname(sid), convert(nvarchar(11), crdate),
			dbid, cmptlevel from master.dbo.sysdatabases
			where (@dbname is null or name = @dbname)

/*
** Check if you have access to database
** if have access set size and collation
*/
select @low = convert(varchar(11),low) from master.dbo.spt_values
			where type = N'E' and number = 1

declare ms_crs_c1 cursor global for
	select db_name (dbid) from #spdbdesc
open ms_crs_c1
fetch ms_crs_c1 into @name
while @@fetch_status >= 0
begin
	if (has_dbaccess(@name) <> 1)
	begin
	  delete #spdbdesc where current of ms_crs_c1
	  raiserror(15622,-1,-1, @name)
	end
	else
		begin
			/* Insert row for each database */
			select @exec_stmt = 'update #spdbdesc
								set dbsize = (select str(convert(dec(15),sum(size))* ' + @low + '/ 1048576,10,2)+ N'' MB'' from '
 								+ quotename(@name, N'[') + N'.dbo.sysfiles) WHERE current of ms_crs_c1'

			execute (@exec_stmt)
		end
	fetch ms_crs_c1 into @name
end
deallocate ms_crs_c1

/*
**  Now for each dbid in #spdbdesc, build the database status
**  description.
*/
declare @curdbid smallint	/* the one we're currently working on */
/*
**  Set @curdbid to the first dbid.
*/
select @curdbid = min(dbid) from #spdbdesc


while @curdbid IS NOT NULL
begin
	set @name = db_name(@curdbid)

	-- These properties always available
	SELECT @dbdesc = 'Status=' + convert(sysname,DatabasePropertyEx(@name,'Status'))
	SELECT @dbdesc = @dbdesc + ', Updateability=' + convert(sysname,DatabasePropertyEx(@name,'Updateability'))
	SELECT @dbdesc = @dbdesc + ', UserAccess=' + convert(sysname,DatabasePropertyEx(@name,'UserAccess'))
	SELECT @dbdesc = @dbdesc + ', Recovery=' + convert(sysname,DatabasePropertyEx(@name,'Recovery'))
	SELECT @dbdesc = @dbdesc + ', Version=' + convert(sysname,DatabasePropertyEx(@name,'Version'))

	-- These props only available if db not shutdown
	IF DatabasePropertyEx(@name, 'IsShutdown') = 0
	BEGIN
		SELECT @dbdesc = @dbdesc + ', Collation=' + convert(sysname,DatabasePropertyEx(@name,'Collation'))
		SELECT @dbdesc = @dbdesc + ', SQLSortOrder=' + convert(sysname,DatabasePropertyEx(@name,'SQLSortOrder'))
	END

	-- These are the boolean properties
	IF DatabasePropertyEx(@name,'IsAutoClose') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAutoClose'
	IF DatabasePropertyEx(@name,'IsAutoShrink') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAutoShrink'
	IF DatabasePropertyEx(@name,'IsInStandby') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsInStandby'
	IF DatabasePropertyEx(@name,'IsTornPageDetectionEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsTornPageDetectionEnabled'
	IF DatabasePropertyEx(@name,'IsAnsiNullDefault') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAnsiNullDefault'
	IF DatabasePropertyEx(@name,'IsAnsiNullsEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAnsiNullsEnabled'
	IF DatabasePropertyEx(@name,'IsAnsiPaddingEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAnsiPaddingEnabled'
	IF DatabasePropertyEx(@name,'IsAnsiWarningsEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAnsiWarningsEnabled'
	IF DatabasePropertyEx(@name,'IsArithmeticAbortEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsArithmeticAbortEnabled'
	IF DatabasePropertyEx(@name,'IsAutoCreateStatistics') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAutoCreateStatistics'
	IF DatabasePropertyEx(@name,'IsAutoUpdateStatistics') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsAutoUpdateStatistics'
	IF DatabasePropertyEx(@name,'IsCloseCursorsOnCommitEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsCloseCursorsOnCommitEnabled'
	IF DatabasePropertyEx(@name,'IsFullTextEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsFullTextEnabled'
	IF DatabasePropertyEx(@name,'IsLocalCursorsDefault') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsLocalCursorsDefault'
	IF DatabasePropertyEx(@name,'IsNullConcat') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsNullConcat'
	IF DatabasePropertyEx(@name,'IsNumericRoundAbortEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsNumericRoundAbortEnabled'
	IF DatabasePropertyEx(@name,'IsQuotedIdentifiersEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsQuotedIdentifiersEnabled'
	IF DatabasePropertyEx(@name,'IsRecursiveTriggersEnabled') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsRecursiveTriggersEnabled'
	IF DatabasePropertyEx(@name,'IsMergePublished') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsMergePublished'
	IF DatabasePropertyEx(@name,'IsPublished') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsPublished'
	IF DatabasePropertyEx(@name,'IsSubscribed') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsSubscribed'
	IF DatabasePropertyEx(@name,'IsSyncWithBackup') = 1
		SELECT @dbdesc = @dbdesc + ', ' + 'IsSyncWithBackup'

	update #spdbdesc set dbdesc = @dbdesc where dbid = @curdbid

	/*
	**  Now get the next, if any dbid.
	*/
	select @curdbid = min(dbid) from #spdbdesc where dbid > @curdbid
end

/*
**  Now #spdbdesc is complete so we can print out the db info
*/
select name = dbname,
	db_size = dbsize,
	owner = owner,
	dbid = dbid,
	created = created,
	status = dbdesc,
    compatibility_level = cmptlevel
from  #spdbdesc
order by dbname

