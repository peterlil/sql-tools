
DECLARE @instance varchar(1) = '1',
	@sql nvarchar(max)

WHILE (1 = 1)
BEGIN
	SET @sql = N'
		SELECT *
		INTO dbo.Customer' + @instance + ' 
		FROM SalesLT.Customer
		ORDER BY EmailAddress DESC
		WAITFOR DELAY ''00:00:01.000''
		DROP TABLE dbo.Customer' + @instance

	EXEC sp_executesql @sql
	WAITFOR DELAY '00:00:05.000'

	SET @sql = N'
		SELECT *
		INTO dbo.Product' + @instance + ' 
		FROM SalesLT.Product
		ORDER BY EmailAddress DESC
		WAITFOR DELAY ''00:00:01.000''
		DROP TABLE dbo.Product' + @instance

	EXEC sp_executesql @sql
	WAITFOR DELAY '00:00:05.000'


	SET @sql = N'
		SELECT *
		INTO dbo.SalesOrderDetail' + @instance + ' 
		FROM SalesLT.SalesOrderDetail
		ORDER BY EmailAddress DESC
		WAITFOR DELAY ''00:00:01.000''
		DROP TABLE dbo.SalesOrderDetail' + @instance

	EXEC sp_executesql @sql
	WAITFOR DELAY '00:00:05.000'
END