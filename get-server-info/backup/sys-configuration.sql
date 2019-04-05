SET NOCOUNT ON;

DECLARE
	@fill_factor int,
	@network_packet_size int,
	@priority_boost bit,
	@affinity_mask int,
	@cost_threshold_for_parallelism int,
	@maxdop int,
	@min_server_memory int,
	@max_server_memory int,
	@lightweight_pooling bit,
	@scan_for_startup_procs bit,
	@awe_enabled bit,
	@affinity_io_mask int,
	@clr_enabled bit,
	@default_trace_enabled bit,
	@backup_compression_default bit,
	@optimize_for_adhoc_workloads bit,
	@agent_xps bit,
	@sql_mail_xps bit,
	@database_mail_xps bit,
	@xp_cmdshell bit;
	
DECLARE @tmp TABLE
(
	Value int,
	Comment nvarchar(100)
)

SET @fill_factor = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 109);
SET @network_packet_size = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 505);
SET @priority_boost = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1517);
SET @affinity_mask = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 1535);
SET @cost_threshold_for_parallelism = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 1538);
SET @maxdop = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 1539);
SET @min_server_memory = (SELECT CAST(value AS int) FROM sys.configurations WHERE configuration_id = 1543);
SET @max_server_memory = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 1544);
SET @lightweight_pooling = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1546);
SET @scan_for_startup_procs = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1547);
SET @awe_enabled = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1548);
SET @affinity_io_mask = (SELECT CAST(value_in_use AS int) FROM sys.configurations WHERE configuration_id = 1550);
SET @clr_enabled = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1562);
SET @default_trace_enabled = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1568);
SET @backup_compression_default = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1579);
SET @optimize_for_adhoc_workloads = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 1581);
SET @agent_xps = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 16384);
SET @sql_mail_xps = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 16385);
SET @database_mail_xps = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 16386);
SET @xp_cmdshell = (SELECT CAST(value_in_use AS bit) FROM sys.configurations WHERE configuration_id = 16390);

INSERT INTO @tmp (Value, Comment)
	SELECT 
		@fill_factor, 
		CASE 
			WHEN @fill_factor != 0 AND @fill_factor != 100 THEN
				'Information: Fill Factor is not at default setting. Evaluation is needed.'
			ELSE 
				'Information; Fill Factor is at default setting.'
		END AS [Fill Factor Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT 
		@network_packet_size AS [Network Packet Size],
		CASE 
			WHEN @network_packet_size = 4096 THEN
				'Information; Network packet size is at default setting.'
			ELSE 
				'Warning: Network packet size is not at default setting. Evaluation is needed.'
		END AS [Network Packet Size Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT 
		@priority_boost AS [Priority Boost],
		CASE 
			WHEN @priority_boost = 0 THEN
				'Information; Priority Boost is at default setting.'
			ELSE 
				'Warning: Priority Boost is not at default setting. Evaluation is needed.'
		END AS [Priority Boost Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@affinity_mask AS [Affinity Mask],
		CASE 
			WHEN @affinity_mask = 0 THEN
				'Information; Affinity Mask is at default setting.'
			ELSE 
				'Warning: Affinity Mask is not at default setting. Evaluation is needed.'
		END AS [Affinity Mask Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@cost_threshold_for_parallelism AS [Cost Threshold For Parallelism],
		CASE 
			WHEN @cost_threshold_for_parallelism = 5 THEN
				'Information; Cost Threshold For Parallelism is at default setting.'
			ELSE 
				'Warning: Cost Threshold For Parallelism is not at default setting. Evaluation is needed.'
		END AS [Cost Threshold For Parallelism Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@maxdop AS [Max Degree Of Parallelism],
		CASE 
			WHEN @maxdop = 0 THEN
				'Information; Max Degree Of Parallelism is at default setting.'
			ELSE 
				'Warning: Max Degree Of Parallelism is not at default setting. Evaluation is needed.'
		END AS [Max Degree Of Parallelism Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@min_server_memory AS [Min Server Memory],
		CASE 
			WHEN @min_server_memory = 0 THEN
				'Information; Min Server Memory is at default setting.'
			ELSE 
				'Warning: Min Server Memory is not at default setting. Evaluation is needed.'
		END AS [Min Server Memory Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT		
		@max_server_memory AS [Max Server Memory (MB)],
		CASE 
			WHEN @max_server_memory = 2147483647 THEN
				'Information; Max Server Memory (MB) is at default setting.'
			ELSE 
				'Warning: Max Server Memory (MB) is not at default setting. Evaluation is needed.'
		END AS [Max Server Memory (MB) Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@lightweight_pooling AS [Lightweight Pooling],
		CASE 
			WHEN @lightweight_pooling = 0 THEN
				'Information; Lightweight Pooling is at default setting.'
			ELSE 
				'Warning: Lightweight Pooling is not at default setting. Evaluation is needed.'
		END AS [Lightweight Pooling Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@scan_for_startup_procs AS [Scan For Startup Procs],
		CASE 
			WHEN @scan_for_startup_procs = 0 THEN
				'Information; Scan For Startup Procs is at default setting.'
			ELSE 
				'Warning: Scan For Startup Procs is not at default setting. Evaluation is needed.'
		END AS [Scan For Startup Procs Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@awe_enabled AS [AWE Enabled],
		CASE 
			WHEN @awe_enabled = 0 THEN
				'Information; AWE Enabled is at default setting.'
			ELSE 
				'Warning: AWE Enabled is not at default setting. Evaluation is needed.'
		END AS [AWE Enabled Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@affinity_io_mask AS [Affinity I/O Mask],
		CASE 
			WHEN @affinity_io_mask = 0 THEN
				'Information; Affinity I/O Mask is at default setting.'
			ELSE 
				'Warning: Affinity I/O Mask is not at default setting. Evaluation is needed.'
		END AS [Affinity I/O Mask Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@clr_enabled AS [CLR Enabled],
		CASE 
			WHEN @clr_enabled = 0 THEN
				'Information; CLR Enabled is at default setting.'
			ELSE 
				'Warning: CLR Enabled is not at default setting. Evaluation is needed.'
		END AS [CLR Enabled Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@default_trace_enabled AS [Default Trace Enabled],
		CASE 
			WHEN @default_trace_enabled = 1 THEN
				'Information; Default Trace Enabled is at default setting.'
			ELSE 
				'Warning: Default Trace Enabled is not at default setting. Evaluation is needed.'
		END AS [Default Trace Enabled Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@backup_compression_default AS [Backup Compression Default],
		CASE 
			WHEN @backup_compression_default = 0 THEN
				'Information; Backup Compression Default is at default setting.'
			ELSE 
				'Warning: Backup Compression Default is not at default setting. Evaluation is needed.'
		END AS [Backup Compression Default Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@optimize_for_adhoc_workloads AS [Optimize For Ad-hoc Workloads],
		CASE 
			WHEN @optimize_for_adhoc_workloads = 0 THEN
				'Information; Optimize For Ad-hoc Workloads is at default setting.'
			ELSE 
				'Warning: Optimize For Ad-hoc Workloads is not at default setting. Evaluation is needed.'
		END AS [Optimize For Ad-hoc Workloads Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@agent_xps AS [Agent XPs],
		CASE 
			WHEN @agent_xps = 1 THEN
				'Information; Agent XPs is at default setting.'
			ELSE 
				'Warning: Agent XPs is not at default setting. Evaluation is needed.'
		END AS [Agent XPs Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@sql_mail_xps AS [SQL Mail XPs],
		CASE 
			WHEN @sql_mail_xps = 0 THEN
				'Information; SQL Mail XPs is at default setting.'
			ELSE 
				'Warning: SQL Mail XPs is not at default setting. Evaluation is needed.'
		END AS [SQL Mail XPs Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@database_mail_xps AS [Database Mail XPs],
		CASE 
			WHEN @database_mail_xps = 0 THEN
				'Information; Database Mail XPs is at default setting.'
			ELSE 
				'Warning: Database Mail XPs is not at default setting. Evaluation is needed.'
		END AS [Database Mail XPs Comment];
INSERT INTO @tmp (Value, Comment)
	SELECT
		@xp_cmdshell AS [xp_cmdshell],
		CASE 
			WHEN @xp_cmdshell = 0 THEN
				'Information; xp_cmdshell is at default setting.'
			ELSE 
				'Warning: xp_cmdshell is not at default setting. Evaluation is needed.'
		END AS [xp_cmdshell Comment];
	
SELECT Value, Comment FROM @tmp;
