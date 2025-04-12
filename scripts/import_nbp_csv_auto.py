import csv
import datetime
import requests
import os
from utils import get_connection  # ← korzystamy z Twojej funkcji

NBP_CSV_URL = "https://static.nbp.pl/dane/kursy/Archiwum/archiwum_tab_a_2025.csv"
LOCAL_CSV_PATH = "/archive/archiwum_tab_a_2025.csv"

CURRENCY_MAP = {
    "USD": "dolar amerykański",
    "EUR": "euro",
    "CHF": "frank szwajcarski",
    "GBP": "funt szterling",
    "JPY": "jen (100)"
    # Dodaj więcej, jeśli chcesz
}

def download_csv():
    try:
        response = requests.get(NBP_CSV_URL, timeout=10)
        response.raise_for_status()
        with open(LOCAL_CSV_PATH, "wb") as f:
            f.write(response.content)
        print(f"✅ Plik CSV pobrany: {LOCAL_CSV_PATH}")
        return True
    except Exception as e:
        print(f"❌ Błąd podczas pobierania pliku NBP: {e}")
        return False

def parse_date(date_str):
    return datetime.datetime.strptime(date_str, "%d-%m-%Y").date()

def import_exchange_rates():
    if not os.path.exists(LOCAL_CSV_PATH):
        print("❌ Brak pliku CSV.")
        return

    with open(LOCAL_CSV_PATH, encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        headers = next(reader)

        currency_indices = {}
        for iso in CURRENCY_MAP.keys():
            try:
                idx = headers.index(iso)
                currency_indices[iso] = idx
            except ValueError:
                print(f"⚠️ Nie znaleziono kolumny {iso} w CSV.")

        conn = get_connection()
        cursor = conn.cursor()

        inserted = 0
        for row in reader:
            if not row or len(row) < 2:
                continue

            try:
                rate_date = parse_date(row[0])
                for iso, idx in currency_indices.items():
                    rate_str = row[idx].strip().replace(",", ".")
                    if rate_str:
                        rate = float(rate_str)

                        cursor.execute("""
                            SELECT COUNT(*) FROM EXCHANGERATE
                            WHERE CURRENCY = :1 AND RATE_DATE = :2
                        """, [iso, rate_date])
                        if cursor.fetchone()[0] == 0:
                            cursor.execute("""
                                INSERT INTO EXCHANGERATE (CURRENCY, RATE_TO_PLN, RATE_DATE)
                                VALUES (:1, :2, :3)
                            """, [iso, rate, rate_date])
                            inserted += 1
                            print(f"✅ {iso} {rate_date} = {rate}")
            except Exception as e:
                print(f"❌ Błąd w wierszu: {e}")

        conn.commit()
        cursor.close()
        conn.close()
        print(f"🎉 Zaimportowano {inserted} rekordów.")

if __name__ == "__main__":
    if download_csv():
        import_exchange_rates()
