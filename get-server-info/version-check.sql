-- SQL Server 2008 R2
DECLARE @product_version nvarchar(100);
SET @product_version = CONVERT(nvarchar(100), SERVERPROPERTY('productversion'))
PRINT @product_version;
IF (LEFT(@product_version, 4) = N'11.0')
BEGIN
	-- Min product level should be last CU -> 
	SELECT 
		SERVERPROPERTY('productversion') AS [SQL Server Version], 
		SERVERPROPERTY ('productlevel') AS [SQL Server Level], 
		SERVERPROPERTY ('edition') AS [SQL Server Edition],
		CASE 
			WHEN CAST((SUBSTRING(@product_version, 6, CHARINDEX('.', @product_version, 6) - 6)) AS int) > 2100 THEN
				'Either a late hotfix is installed or reference version number is not up to date! Verify if this is a problem!'
			WHEN CAST((SUBSTRING(@product_version, 6, CHARINDEX('.', @product_version, 6) - 6)) AS int) = 2100 THEN
				'Product version is ok!'
			WHEN CAST((SUBSTRING(@product_version, 6, CHARINDEX('.', @product_version, 6) - 6)) AS int) < 2100 THEN
				'Warning: Product version is not of the latest build.'
		END AS [Version comment]
END
ELSE
BEGIN
	IF (LEFT(@product_version, 5) = N'10.50')
	BEGIN
		-- Min product level should be last CU -> 
		SELECT 
			SERVERPROPERTY('productversion') AS [SQL Server Version], 
			SERVERPROPERTY ('productlevel') AS [SQL Server Level], 
			SERVERPROPERTY ('edition') AS [SQL Server Edition],
			CASE 
				WHEN CAST((SUBSTRING(@product_version, 7, CHARINDEX('.', @product_version, 7) - 7)) AS int) > 2806 THEN
					'Either a late hotfix is installed or reference version number is not up to date! Verify if this is a problem!'
				WHEN CAST((SUBSTRING(@product_version, 7, CHARINDEX('.', @product_version, 7) - 7)) AS int) = 2806 THEN
					'Product version is ok!'
				WHEN CAST((SUBSTRING(@product_version, 7, CHARINDEX('.', @product_version, 7) - 7)) AS int) < 2806 THEN
					'Warning: Product version is not of the latest build.'
			END AS [Version comment]
	END
END;