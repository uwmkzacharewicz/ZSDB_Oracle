#!/bin/bash

# Sprawdzenie, czy uruchomiono jako użytkownik oracle
if [ "$(whoami)" != "oracle" ]; then
  echo "Ten skrypt musi być uruchomiony jako użytkownik 'oracle'."
  echo "Zaloguj się jako 'oracle' i spróbuj ponownie."
  exit 1
fi

# Sprawdzenie, czy podano 2 (uzytkownik, haslo) argumenty
if [ $# -ne 2 ]; then
  echo "Użycie: $0 nazwa_użytkownika hasło_użytkownika"
  exit 2
fi

USER_NAME="$1"
USER_PASSWORD="$2"
TABLESPACE="${USER_NAME}_tbs"
DATAFILE="/opt/oracle/oradata/XE/XEPDB1/${TABLESPACE}01.dbf"

# Opcjonalna walidacja hasła
if [ ${#USER_PASSWORD} -lt 8 ]; then
  echo "Hasło musi mieć co najmniej 8 znaków."
  exit 3
fi

# Uruchomienie SQL*Plus jako SYSDBA
sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;

-- Tworzenie tablespace
CREATE TABLESPACE $TABLESPACE 
    DATAFILE '$DATAFILE' 
    SIZE 100M 
    AUTOEXTEND ON 
    NEXT 50M 
    MAXSIZE UNLIMITED;

-- Tworzenie użytkownika
CREATE USER $USER_NAME IDENTIFIED BY "$USER_PASSWORD"
    DEFAULT TABLESPACE $TABLESPACE
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON $TABLESPACE;

-- Nadanie uprawnień
GRANT CONNECT TO $USER_NAME;
GRANT RESOURCE TO $USER_NAME;
GRANT CREATE SESSION TO $USER_NAME;
GRANT CREATE TABLE TO $USER_NAME;
GRANT CREATE VIEW TO $USER_NAME;
GRANT CREATE SEQUENCE TO $USER_NAME;
GRANT CREATE SYNONYM TO $USER_NAME;
GRANT CREATE PROCEDURE TO $USER_NAME;
GRANT CREATE TRIGGER TO $USER_NAME;
GRANT CREATE TYPE TO $USER_NAME;
GRANT CREATE MATERIALIZED VIEW TO $USER_NAME;
GRANT CREATE JOB TO $USER_NAME;
GRANT EXECUTE ON DBMS_SCHEDULER TO $USER_NAME;
GRANT SELECT_CATALOG_ROLE TO $USER_NAME;
GRANT EXECUTE ANY PROCEDURE TO $USER_NAME;
GRANT UNLIMITED TABLESPACE TO $USER_NAME;
EXIT;
EOF



#!/bin/bash

# Sprawdzenie, czy uruchomiono jako użytkownik oracle
if [ "$(whoami)" != "oracle" ]; then
  echo "Ten skrypt musi być uruchomiony jako użytkownik 'oracle'."
  echo "Zaloguj się jako 'oracle' i spróbuj ponownie."
  exit 1
fi

# Sprawdzenie, czy podano dwa argumenty
if [ $# -ne 2 ]; then
  echo "Użycie: $0 nazwa_użytkownika hasło_użytkownika"
  exit 2
fi

USER_NAME="$1"
USER_PASSWORD="$2"
TABLESPACE="${USER_NAME}_tbs"
DATAFILE="/opt/oracle/oradata/XE/XEPDB1/${TABLESPACE}01.dbf"

# Opcjonalna walidacja hasła
if [ ${#USER_PASSWORD} -lt 8 ]; then
  echo "Hasło musi mieć co najmniej 8 znaków."
  exit 3
fi

# Uruchomienie SQL*Plus jako SYSDBA
sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;

-- Tworzenie tablespace
CREATE TABLESPACE $TABLESPACE 
    DATAFILE '$DATAFILE' 
    SIZE 100M 
    AUTOEXTEND ON 
    NEXT 50M 
    MAXSIZE UNLIMITED;

-- Tworzenie użytkownika
CREATE USER $USER_NAME IDENTIFIED BY "$USER_PASSWORD"
    DEFAULT TABLESPACE $TABLESPACE
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON $TABLESPACE;

-- Nadanie uprawnień
GRANT CONNECT TO $USER_NAME;
GRANT RESOURCE TO $USER_NAME;
GRANT CREATE SESSION TO $USER_NAME;
GRANT CREATE TABLE TO $USER_NAME;
GRANT CREATE VIEW TO $USER_NAME;
GRANT CREATE SEQUENCE TO $USER_NAME;
GRANT CREATE SYNONYM TO $USER_NAME;
GRANT CREATE PROCEDURE TO $USER_NAME;
GRANT CREATE TRIGGER TO $USER_NAME;
GRANT CREATE TYPE TO $USER_NAME;
GRANT CREATE MATERIALIZED VIEW TO $USER_NAME;
GRANT CREATE JOB TO $USER_NAME;
GRANT EXECUTE ON DBMS_SCHEDULER TO $USER_NAME;
GRANT SELECT_CATALOG_ROLE TO $USER_NAME;
GRANT EXECUTE ANY PROCEDURE TO $USER_NAME;
GRANT UNLIMITED TABLESPACE TO $USER_NAME;
EXIT;
EOF


LOCAL_IP=$(ip addr | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -E '^(192\.168|100\.)' | head -n 1)


echo ""
echo "Użytkownik został pomyślnie utworzony!"
echo "Dane logowania do bazy danych:"
echo "----------------------------------------"
echo "Host (adres IP):    ${LOCAL_IP:-<nie znaleziono>}"
echo "Port:               1521"
echo "Service Name:       XEPDB1"
echo "Username:           $USER_NAME"
echo "Password:           $USER_PASSWORD"
echo "----------------------------------------"
