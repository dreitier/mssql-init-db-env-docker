# Sidecar container for creating a new Microsoft SQL Server database and application credentials
This Docker image can be used as a sidecard container to ensure that a database, user and login in a Microsoft SQL Server instance is created. This is useful, if you are using *Amazon RDS for SQL Server* and *Amazon Elastic Container Service* in a restricted AWS environment. Using this sidecar container is easier than deploying any AWS Lambda/CloudFormation custom resources.

## Functionality
- Database, login and user are only created once. If they are already present, they won't be touched.
- Roles are only upserted. If the user has already assigned any other, non-specified role that role is kept.

## Exit codes
- The Docker container exits with `0` if everything has been working properly.
- If any error occurred, the exit codes from `sqlcmd` will be used. The SQL script itself fails fast. If any error in the SQL statements occurs, it will exit instantly. Transactions are __not__ used.

## Environment variables
You can pass the following environment variables with `-e VARIABLE=VALUE` to the Docker container:

| Environment variable | Default | Description |
| --- | --- | --- |
| `DATABASE_HOST` | `localhost` | Host to connect to |
| `DATABASE_PORT` | `1433` | Port to use |
| `DATABASE_PROTOCOL` | `tcp` | Protocol to use |
| `MASTER_USERNAME` | `sa` | RDS instance's master username; you'll probably want to inject this with SSM when using AWS |
| `MASTER_PASSWORD` | `Passw0rd!` | RDS instance's master password; you'll probably want to inject this with SSM when using AWS |
| `DATABASE_NAME` | `app` | Name of the database |
| `DATABASE_LOGIN` | `app` | Login |
| `DATABASE_USER` | `app_user` | User |
| `DATABASE_PASSWORD` | `Passw0rd!` | Password of the `DATABASE_USER`; this will __not__ be updated. Rotating is not possible at the moment. |
| `DATABASE_TIMEOUT` | `5` | Timeout in seconds |
| `DATABASE_ROLES` | `db_owner` | Roles to assign for `DATABASE_USER`; separated with comma (`,`), whitespaces are __not__ allowed |
| `TRUST_SERVER_CERTIFICATE` | `0` | If `1`, the server certificate is trusted; enable this if you have self-signed certificates |
| `TRUSTED_CONNECTION` | `0` | If `1`, the connection is trusted. `MASTER_USERNAME` and `MASTER_PASSWORD` can then __not__ be used |
| `AZURE_AD_AUTHENTICATION` | `0` | If `1`, Azure AD is used for authentication |

## Docker

### Create build
`docker build -t dreitier/mssql-init-db-env:latest`
