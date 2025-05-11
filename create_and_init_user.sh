#!/bin/bash

# Sprawdzenie użytkownika
if [ "$(whoami)" != "oracle" ]; then
  echo "Uruchom jako użytkownik 'oracle'."
  exit 1
fi

# Sprawdzenie argumentów
if [ $# -ne 2 ]; then
  echo "Użycie: $0 nazwa_użytkownika hasło"
  exit 2
fi

USER_NAME="$1"
USER_PASSWORD="$2"
TABLESPACE="${USER_NAME}_tbs"
DATAFILE="/opt/oracle/oradata/XE/XEPDB1/${TABLESPACE}01.dbf"
SCRIPT_PATH="$(dirname "$0")/start.sql"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Brak pliku: $SCRIPT_PATH"
  exit 3
fi

if [ ${#USER_PASSWORD} -lt 8 ]; then
  echo "Hasło musi mieć co najmniej 8 znaków."
  exit 4
fi

# Tworzenie użytkownika + tablespace
sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;

-- Tworzenie tablespace
CREATE TABLESPACE $TABLESPACE
  DATAFILE '$DATAFILE' SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;

-- Tworzenie użytkownika
CREATE USER $USER_NAME IDENTIFIED BY "$USER_PASSWORD"
  DEFAULT TABLESPACE $TABLESPACE
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON $TABLESPACE;

-- Uprawnienia
GRANT CONNECT, RESOURCE TO $USER_NAME;
GRANT CREATE SESSION TO $USER_NAME;
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO $USER_NAME;
GRANT CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO $USER_NAME;
GRANT CREATE MATERIALIZED VIEW, CREATE JOB TO $USER_NAME;
GRANT EXECUTE ON DBMS_SCHEDULER TO $USER_NAME;
GRANT UNLIMITED TABLESPACE TO $USER_NAME;
GRANT SELECT_CATALOG_ROLE TO $USER_NAME;
GRANT EXECUTE ANY PROCEDURE TO $USER_NAME;
EOF

# Wczytywanie DDL z pliku
#sqlplus $USER_NAME/"$USER_PASSWORD"@XEPDB1 <<EOF
#SET FEEDBACK ON
#SET DEFINE OFF
#@$SCRIPT_PATH
#EXIT;
#EOF

# IP lokalny do połączenia
#LOCAL_IP=$(ip addr | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -E '^(192\.168|100\.)' | head -n 1)


# Ustal lokalny adres IP
LOCAL_IP=$(ip addr | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -E '^(192\.168|100\.)' | head -n 1)

# Składnia połączenia SQL*Plus
CONNECT_STRING="$USER_NAME/$USER_PASSWORD@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${LOCAL_IP:-127.0.0.1})(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=XEPDB1)))"

# Wczytywanie DDL z pliku .sql
sqlplus -S "$CONNECT_STRING" @"$SCRIPT_PATH"


echo ""
echo "Użytkownik $USER_NAME został utworzony i baza też powinna być :)"
echo "----------------------------------------"
echo "Host:               100.95.65.78"
echo "Port:               1521"
echo "Service Name:       XEPDB1"
echo "Username:           $USER_NAME"
echo "Password:           $USER_PASSWORD"
echo "----------------------------------------"
