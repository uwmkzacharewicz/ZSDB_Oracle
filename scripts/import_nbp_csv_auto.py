#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import csv
import datetime
import requests
import os
import shutil
from utils import get_connection

NBP_CSV_URL = "https://static.nbp.pl/dane/kursy/Archiwum/archiwum_tab_a_2025.csv"
LOCAL_CSV_PATH = os.path.join(os.path.dirname(__file__), "../tmp/archiwum_tab_a_2025.csv")
ARCHIVE_CSV_PATH = os.path.join(os.path.dirname(__file__), "../archive/nbp/archiwum_tab_a_2025.csv")

CURRENCY_MAP = {
    "USD": "1USD",
    "EUR": "1EUR"
}

def download_csv():
    try:
        response = requests.get(NBP_CSV_URL, timeout=10)
        response.raise_for_status()

        os.makedirs(os.path.dirname(LOCAL_CSV_PATH), exist_ok=True)
        os.makedirs(os.path.dirname(ARCHIVE_CSV_PATH), exist_ok=True)

        with open(LOCAL_CSV_PATH, "wb") as f:
            f.write(response.content)

        # Kopiujemy do katalogu archiwum
        shutil.copy2(LOCAL_CSV_PATH, ARCHIVE_CSV_PATH)
        print(f"Plik CSV pobrany: {LOCAL_CSV_PATH}")
        print(f"Skopiowano do archiwum: {ARCHIVE_CSV_PATH}")
        return True
    except Exception as e:
        print(f"Błąd podczas pobierania pliku NBP: {e}")
        return False

def parse_date(date_str):
    return datetime.datetime.strptime(date_str, "%Y%m%d").date()

def import_exchange_rates():
    if not os.path.exists(LOCAL_CSV_PATH):
        print("Brak pliku CSV.")
        return

    with open(LOCAL_CSV_PATH, encoding="iso-8859-1") as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        headers = next(reader)

        currency_indices = {}
        for csv_col, iso_code in CURRENCY_MAP.items():
            try:
                idx = headers.index(csv_col)
                currency_indices[iso_code] = idx
            except ValueError:
                print(f"Nie znaleziono kolumny {csv_col} w CSV.")

        conn = get_connection()
        cursor = conn.cursor()

        inserted = 0
        for row in reader:
            if not row or not row[0].isdigit():
                continue

            try:
                rate_date = parse_date(row[0])
                if rate_date != datetime.date.today():
                    continue  # tylko dzisiejsze kursy

                for iso_code, idx in currency_indices.items():
                    rate_str = row[idx].strip().replace(",", ".")
                    if rate_str:
                        rate = float(rate_str)

                        cursor.callproc("insert_exchange_rate", [iso_code, rate])
                        inserted += 1
                        print(f"{iso_code} {rate_date} = {rate}")
            except Exception as e:
                print(f"Błąd w wierszu: {e}")

        conn.commit()
        cursor.close()
        conn.close()
        print(f"Zaimportowano {inserted} rekordów.")

if __name__ == "__main__":
    if download_csv():
        import_exchange_rates()
