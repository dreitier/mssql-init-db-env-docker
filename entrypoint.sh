#!/bin/bash
# This script ensures that a default database and valid credentials are created.

# general connection data
DATABASE_PROTOCOL=${DATABASE_PROTOCOL:-tcp}
DATABASE_HOST=${DATABASE_HOST:-localhost}
DATABASE_PORT=${DATABASE_PORT:-1433}
MASTER_USERNAME=${MASTER_USERNAME:-sa}
MASTER_USERNAME_ARG="-U ${MASTER_USERNAME}"
MASTER_PASSWORD=${MASTER_PASSWORD:-Passw0rd!}
MASTER_PASSWORD_ARG="-P ${MASTER_PASSWORD}"
DATABASE_NAME=${DATABASE_NAME:-app}
DATABASE_LOGIN=${DATABASE_LOGIN:-app}
DATABASE_USER=${DATABASE_USER:-app_user}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-Passw0rd!}
DATABASE_TIMEOUT=${DATABASE_TIMEOUT:-5}
CONNECTION_USER="user ${MASTER_USERNAME}"
DATABASE_ROLES=${DATABASE_ROLES:-db_owner}

# server certificate
TRUST_SERVER_CERTIFICATE=${TRUST_SERVER_CERTIFICATE:-0}
TRUST_SERVER_CERTIFICATE_ARG=""

if [ "${TRUST_SERVER_CERTIFICATE}" -ne "0" ]; then
    TRUST_SERVER_CERTIFICATE_ARG="-C"
fi

# trusted connection
TRUSTED_CONNECTION=${TRUSTED_CONNECTION:-0}
TRUSTED_CONNECTION_ARG=""

if [ "${TRUSTED_CONNECTION}" -ne "0" ]; then
    TRUSTED_CONNECTION_ARG="-E"
    # TRUSTED_CONNECTION is mutually exckluse with the -P and -U flag
    MASTER_PASSWORD_ARG=""
    MASTER_USERNAME_ARG=""
    CONNECTION_USER="a trusted connection (no username and password)"
fi

# AzureAD authentication
AZURE_AD_AUTHENTICATION=${AZURE_AD_AUTHENTICATION:-0}
AZURE_AD_AUTHENTICATION_ARG=""

if [ "${AZURE_AD_AUTHENTICATION}" -ne "0" ]; then
    AZURE_AD_AUTHENTICATION_ARG="-G"
fi

CONNECTION_STRING=${DATABASE_PROTOCOL}:${DATABASE_HOST},${DATABASE_PORT}
echo "Trying to connect to ${CONNECTION_STRING} as ${CONNECTION_USER} ..."

SQLCMD=$(which sqlcmd)

# if sqlcmd is not in search path, fallback to the default installation path of sqlcmd
if [ -z "${SQLCMD}" ]; then
    SQLCMD=/opt/mssql-tools/bin/sqlcmd
fi

# - We are using `-b` for failing fast if anything is wrong in the batch script
# - To inject the variables with `-v` we need at least v15 of the command line tools
#   @see https://docs.microsoft.com/en-us/sql/ssms/scripting/sqlcmd-use-with-scripting-variables?view=sql-server-ver15
$SQLCMD \
    -S "${CONNECTION_STRING}" \
    ${MASTER_USERNAME_ARG} \
    ${MASTER_PASSWORD_ARG} \
    ${TRUST_SERVER_CERTIFICATE_ARG} \
    ${TRUSTED_CONNECTION_ARG} \
    ${AZURE_AD_AUTHENTICATION_ARG} \
    -b \
    -i ensure-database-and-roles-are-available.sql \
    -v DATABASE_NAME="${DATABASE_NAME}" \
    -v DATABASE_LOGIN="${DATABASE_LOGIN}" \
    -v DATABASE_USER="${DATABASE_USER}" \
    -v DATABASE_PASSWORD="${DATABASE_PASSWORD}" \
    -v DATABASE_ROLES="${DATABASE_ROLES},"

EXIT_CODE=$?

if [ "${EXIT_CODE}" = 0 ]; then
    echo "Database schema exists"
    exit 0
else
    echo "Failed to ensure that database schema exists"
    exit $EXIT_CODE
fi