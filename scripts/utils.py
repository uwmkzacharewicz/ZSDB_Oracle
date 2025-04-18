import requests
import oracledb
import json
import sys
import os
import ftplib
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from config.settings import ftp_conf, oracle_conf

# nawiązanie połączenia z bazą danych
def get_connection():
    if not oracle_conf:
        raise ValueError("❌ Brak konfiguracji bazy danych dla aktywnego środowiska.")

    try:
        conn = oracledb.connect(
            user=oracle_conf["user"],
            password=oracle_conf["password"],
            dsn=oracle_conf["dsn"]
        )
        return conn
    except oracledb.Error as e:
        print(f"Błąd połączenia z bazą danych: {e}")
        raise

def get_ftp_connection():
    ftp = ftplib.FTP()
    ftp.connect(ftp_conf["host"])
    ftp.login(ftp_conf["user"], ftp_conf["password"])
    ftp.cwd(ftp_conf["remote_dir"])
    return ftp



def get_actual_currency_rate(currency_code):
    url = f"https://api.nbp.pl/api/exchangerates/rates/a/{currency_code}/?format=json"
    try:
        request = requests.get(url, timeout=10)
        request.raise_for_status()
        data = request.json()
        exchange_rate = data['rates'][0]['mid']
        print(f"Kurs {currency_code}/PLN: {exchange_rate}")
        return exchange_rate
    except requests.exceptions.RequestException as e:
        print(f"Błąd podczas pobierania danych z NBP: {e}")
    except KeyError:
        print("Nieoczekiwana struktura odpowiedzi z NBP.")
    return None

def save_currency_rate_to_db(currency_code):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        rate = get_actual_currency_rate(currency_code)
        if rate is None:
            print(f"❌ Nie udało się pobrać kursu {currency_code}/PLN.")
            return

        cursor.callproc("insert_exchange_rate", [currency_code, rate])
        conn.commit()
        print(f"✅ Zapisano kurs {currency_code}/PLN do bazy danych.")

    except Exception as e:
        print(f"Błąd podczas zapisu kursu do bazy: {e}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()



