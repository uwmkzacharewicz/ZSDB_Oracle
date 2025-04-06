from datetime import datetime, timedelta
import requests
from config.settings import ftp_conf, oracle_conf
import requests
import oracledb
import json
import sys
import os
import ftplib
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

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


def get_historical_currency_rates(currency_code, days_back=10):
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=days_back)
    url = f"https://api.nbp.pl/api/exchangerates/rates/a/{currency_code}/{start_date}/{end_date}/?format=json"

    try:
        request = requests.get(url, timeout=10)
        request.raise_for_status()
        data = request.json()
        rates = data.get("rates", [])
        print(f"📥 Pobrano {len(rates)} kursów historycznych dla {currency_code}.")
        return rates
    except requests.exceptions.RequestException as e:
        print(f"Błąd podczas pobierania danych z NBP: {e}")
    except KeyError:
        print("Nieoczekiwana struktura odpowiedzi z NBP.")
    return []

def insert_historical_rates_to_db(currency_code, days_back=7):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        rates = get_historical_currency_rates(currency_code, days_back)
        for rate_entry in rates:
            rate_value = rate_entry['mid']
            rate_date = rate_entry['effectiveDate']  # format: 'YYYY-MM-DD'
            # Używamy zwykłego INSERT zamiast procedury, bo potrzebujemy ustawić konkretną datę
            cursor.execute("""
                INSERT INTO EXCHANGERATE (CURRENCY, RATE_TO_PLN, RATE_DATE)
                VALUES (:1, :2, TO_DATE(:3, 'YYYY-MM-DD'))
            """, (currency_code, rate_value, rate_date))
            print(f"✅ Wstawiono: {currency_code} = {rate_value} PLN z dnia {rate_date}")

        conn.commit()
        print(f"✅ Zapisano {len(rates)} kursów historycznych do bazy.")

    except Exception as e:
        print(f"❌ Błąd podczas zapisu danych do bazy: {e}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    insert_historical_rates_to_db("USD", days_back=10)
