
-- in [master] database: 
-- create the login from AAD.
CREATE LOGIN [<user>@<tenant>.onmicrosoft.com] FROM EXTERNAL PROVIDER;
-- Add the login to the ##MS_ServerStateReader## role so the login can query all relevant DMVs
ALTER SERVER ROLE [##MS_ServerStateReader##]
	ADD MEMBER [<user>@<tenant>.onmicrosoft.com];

-- In user database: 
-- create the db user
CREATE USER <db-user-name> FROM LOGIN [<user>@<tenant>.onmicrosoft.com];
-- grant reader access to the data
ALTER ROLE db_datareader ADD MEMBER perftuner;


-- https://learn.microsoft.com/en-us/azure/azure-sql/database/security-server-roles?view=azuresql

--GRANT VIEW DATABASE PERFORMANCE STATE TO perftuner;
--GRANT VIEW DATABASE STATE TO perftuner;
--REVOKE VIEW DATABASE PERFORMANCE STATE TO perftuner;
--REVOKE VIEW DATABASE STATE TO perftuner;

-- This one is needed if to trace calls. 
GRANT ALTER ANY DATABASE EVENT SESSION TO perftuner;