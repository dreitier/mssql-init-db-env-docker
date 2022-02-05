-- create database if it does not exist
PRINT "Checking database schema ... "
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = '$(DATABASE_NAME)')
    BEGIN
        CREATE DATABASE [$(DATABASE_NAME)]
        PRINT "  Database $(DATABASE_NAME) created"
    END
ELSE
    BEGIN
        PRINT "  Database $(DATABASE_NAME) already exists"
    END
GO

-- we need to use the master schema to create a login
USE [master]
GO

-- create server login if it does not exist
-- @see https://stackoverflow.com/a/6159882/2545275
PRINT "Checking database login ... "

IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '$(DATABASE_LOGIN)') 
    BEGIN
        CREATE LOGIN $(DATABASE_LOGIN) WITH PASSWORD = '$(DATABASE_PASSWORD)'
        PRINT "  Login $(DATABASE_LOGIN) created"
    END
ELSE 
    BEGIN
        PRINT "  Login $(DATABASE_LOGIN) already exists"
    END
GO

-- switch to our own/previously created database
USE [$(DATABASE_NAME)]
GO

-- and create user for the server login if it does not exist
PRINT "Checking database user ... "
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$(DATABASE_USER)') 
    BEGIN
        CREATE USER $(DATABASE_USER) FOR LOGIN $(DATABASE_LOGIN)
        PRINT "  User $(DATABASE_USER) for login $(DATABASE_LOGIN) created"
    END
ELSE
    BEGIN
        PRINT "  User $(DATABASE_USER) already exists"
    END
GO

-- add roles to our database user
-- @see https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-role-transact-sql?view=sql-server-ver15
-- https://www.admfactory.com/split-a-string-and-loop-in-sql-server/

-- inject database roles into variable so we can iterate over them
DECLARE @roles varchar(8000)
SET @roles = '$(DATABASE_ROLES)'

DECLARE @pos INT
SET @pos = 0

DECLARE @len INT
SET @len = 0

-- role
DECLARE @value varchar(8000)
-- dynamically generated SQL
DECLARE @sql nvarchar(max)

PRINT "Checking role assignment ..."

WHILE CHARINDEX(',', @roles, @pos+1)>0
BEGIN
    SET @len = CHARINDEX(',', @roles, @pos+1) - @pos
    SET @value = SUBSTRING(@roles, @pos, @len)
            
    PRINT "  Ensure that $(DATABASE_USER) is in role " + @value
    SET @sql = 'ALTER ROLE [' + @value + '] ADD MEMBER $(DATABASE_USER) '
    EXEC (@sql)

    SET @pos = CHARINDEX(',', @roles, @pos + @len) +1
END

-- echo table names in active database for debugging purposes
PRINT "Showing already existing tables in database $(DATABASE_NAME)..."
SELECT
  name AS table_name, crdate AS creation_date
FROM
  SYSOBJECTS
WHERE
  xtype = 'U';
GO