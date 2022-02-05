# we are not using mcr.microsoft.com/mssql-tools as this is pretty outdated: it's version does not support passing variables to SQL scripts (`-v` parameter)
FROM dreitier/mssql-tools:17.8

WORKDIR /
COPY entrypoint.sh /entrypoint.sh
COPY ensure-database-and-roles-are-available.sql /ensure-database-and-roles-are-available.sql

ENTRYPOINT ["/entrypoint.sh"]