/*
 * Create the stored procedure GetDbInfo
 */

USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure GetDbInfo (@dbname sysname = NULL)
as
BEGIN
declare @exec_stmt nvarchar(625)
declare @showdev	bit
declare @name           sysname
declare @cmd	nvarchar(285) -- (26 + 258) + 1 extra
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

/*
**  See if the database exists
*/
if not exists (select * from master.dbo.sysdatabases
	where (@dbname is null or name = @dbname))
	begin
		raiserror(15010,-1,-1,@dbname)
	  return (1)
	end


/*
**  Initialize #spdbdesc from sysdatabases
*/
insert into #spdbdesc (dbname, owner, created, dbid, cmptlevel)
		select name, isnull(suser_sname(sid),'~~UNKNOWN~~'), convert(nvarchar(11), crdate),
			dbid, cmptlevel from master.dbo.sysdatabases
			where (@dbname is null or name = @dbname)


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
			select @exec_stmt = 
			    'update #spdbdesc
/*
** 8 KB pages is 128 per MB. If we ever change page size, this
** will be variable by DB or file or filegroup in some manner 
** unforseeable now so just hard code it.
*/
				set dbsize = (select str(sum(convert(dec(17,2),size)) / 128,10,2)
				+ N'' MB'' from '
 				+ quotename(@name, N'[') 
 				+ N'.dbo.sysfiles) 
 				WHERE current of ms_crs_c1'

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
	IF DatabaseProperty(@name, 'IsShutdown') = 0
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
return (0);
END;
