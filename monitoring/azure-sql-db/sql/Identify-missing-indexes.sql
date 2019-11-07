select d.*
		, s.avg_total_user_cost
		, s.avg_user_impact
		, s.last_user_seek
		,s.unique_compiles
from sys.dm_db_missing_index_group_stats s
		,sys.dm_db_missing_index_groups g
		,sys.dm_db_missing_index_details d
where s.group_handle = g.index_group_handle
and d.index_handle = g.index_handle
order by s.avg_user_impact desc
go
--- suggested index columns & usage
declare @handle int

select @handle = d.index_handle
from sys.dm_db_missing_index_group_stats s
		,sys.dm_db_missing_index_groups g
		,sys.dm_db_missing_index_details d
where s.group_handle = g.index_group_handle
and d.index_handle = g.index_handle

select * 
from sys.dm_db_missing_index_columns(@handle)
order by column_id
