import csv
import datetime
import oracledb
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

CSV_PATH = "/tmp/archiwum_tab_a_2025.csv"

CURRENCY_MAP = {
    "USD": "dolar amerykański",
    "EUR": "euro"
}

def parse_date(date_str):
    return datetime.datetime.strptime(date_str, "%d-%m-%Y").date()

def import_exchange_rates():
    with open(CSV_PATH, encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        headers = next(reader)  # nagłówki

        # Znajdź indeksy walut
        currency_indices = {}
        for iso, name in CURRENCY_MAP.items():
            try:
                idx = headers.index(iso)
                currency_indices[iso] = idx
            except ValueError:
                print(f"Nie znaleziono kolumny {iso} w pliku CSV")

        conn = oracledb.connect(user="karol", password="...", dsn="...")
        cursor = conn.cursor()

        for row in reader:
            if not row or len(row) < 2:
                continue

            try:
                rate_date = parse_date(row[0])
                for iso, idx in currency_indices.items():
                    rate_str = row[idx].strip().replace(",", ".")
                    if rate_str:
                        rate = float(rate_str)

                        # sprawdź, czy rekord już istnieje
                        cursor.execute("""
                            SELECT COUNT(*) FROM EXCHANGERATE
                            WHERE CURRENCY = :1 AND RATE_DATE = :2
                        """, [iso, rate_date])
                        exists = cursor.fetchone()[0]

                        if not exists:
                            cursor.execute("""
                                INSERT INTO EXCHANGERATE (CURRENCY, RATE_TO_PLN, RATE_DATE)
                                VALUES (:1, :2, :3)
                            """, [iso, rate, rate_date])
                            print(f"{iso} z {rate_date}: {rate}")
            except Exception as e:
                print(f"Błąd w wierszu: {e}")

        conn.commit()
        cursor.close()
        conn.close()
        print("Import zakończony.")

if __name__ == "__main__":
    import_exchange_rates()
