CREATE EVENT SESSION [Depricated feature usage] ON SERVER 
ADD EVENT sqlserver.deprecation_announcement(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username)),
ADD EVENT sqlserver.deprecation_final_support(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username)) 
ADD TARGET package0.event_file(SET filename=N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\Depricated feature usage.xel')
WITH (STARTUP_STATE=OFF)
GO


