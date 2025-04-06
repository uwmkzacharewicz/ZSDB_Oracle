#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import pandas as pd
import oracledb  # jeśli używasz bazy Oracle przez oracledb
import os
from datetime import date

# Zakładam, że masz moduł "db_utils.py" z funkcją get_connection(), tak jak w poprzednich przykładach
# from utils.db_utils import get_connection

# Folder archiwum
ARCHIVE_DIR = os.path.join(os.path.dirname(__file__), "archive")
os.makedirs(ARCHIVE_DIR, exist_ok=True)

# Słownik z listą plików i linków z dropbox
DROPBOX_FILES = [
    {
        "file_name": "company_ABC.csv",
        "company_id": 101,
        "dropbox_url": "https://www.dropbox.com/s/<abc123>/company_ABC.csv?dl=1",
        "type": "csv"
    },
    {
        "file_name": "market_data.json",
        "company_id": 999,   # lub inny usage
        "dropbox_url": "https://www.dropbox.com/s/<def456>/market_data.json?dl=1",
        "type": "json"
    }
]

def main():
    """
    Przykładowy skrypt pobierający pliki CSV/JSON z Dropbox, wczytujący do pandas,
    i (opcjonalnie) ładujący do bazy lub zapisujący do pliku archiwum.
    """

    # Jeśli chcesz łączyć się z bazą Oracle, odkomentuj:
    # conn = get_connection()
    # cursor = conn.cursor()

    for item in DROPBOX_FILES:
        file_name  = item["file_name"]
        url        = item["dropbox_url"]
        file_type  = item["type"]        # 'csv' lub 'json'
        company_id = item["company_id"]

        print(f"\n🔽 Pobieram plik {file_name} z Dropbox: {url}")
        try:
            r = requests.get(url, timeout=30)
            r.raise_for_status()  # Błąd, jeśli HTTP != 200
        except Exception as e:
            print(f"❌ Błąd przy pobieraniu: {e}")
            continue

        # Mamy w r.content treść pliku
        # Zapiszmy na dysk tymczasowo (opcjonalnie), albo wczytujemy od razu do pandas
        try:
            if file_type == "csv":
                # Pandas odczyta z bajtów (BytesIO), parse_dates -> kolumny z datą
                from io import StringIO
                df = pd.read_csv(
                    StringIO(r.text),
                    parse_dates=["Date"],  # dopasuj do kolumn
                    # sep=','  # jeśli standardowy CSV
                )
            elif file_type == "json":
                df = pd.read_json(
                    r.content,  # r.text też zadziała
                    convert_dates=["Date"]  # dopasuj do kluczy
                )
            else:
                print(f"⚠ Nieznany typ pliku: {file_type}, pomijam.")
                continue
        except Exception as e:
            print(f"❌ Błąd parsowania pliku w pandas: {e}")
            continue

        if df.empty:
            print("⚠ Plik jest pusty (lub nie ma wymaganych kolumn), pomijam.")
            continue

        print(f"📋 Załadowano DataFrame z {len(df)} rekordami.")

        # (Opcjonalnie) Archiwizuj ten plik - zapisz do folderu "archive"
        archive_path = os.path.join(ARCHIVE_DIR, f"{file_name}_{date.today()}")
        # np. dopisujemy datę do nazwy
        if file_type == "csv":
            archive_path += ".csv"
            df.to_csv(archive_path, index=False)
        else:
            archive_path += ".json"
            df.to_json(archive_path, orient="records", date_format="iso")

        print(f"📁 Plik zarchiwizowany w: {archive_path}")

        # (Opcjonalnie) Walidacja danych, usuwanie NaN
        if all(col in df.columns for col in ["Open","High","Low","Close","Volume"]):
            df = df.dropna(subset=["Open","High","Low","Close","Volume"])
        else:
            print("⚠ Brak kolumn giełdowych (Open, High, Low, ...), nie można walidować.")
            # ewentualnie continue

        # (Opcjonalnie) Wstaw do bazy
        """
        for idx, row in df.iterrows():
            trade_date  = row["Date"]
            open_price  = float(row["Open"])
            high_price  = float(row["High"])
            ...
            # wywołanie procedury:
            try:
                cursor.callproc("insert_stock_price", [
                    company_id,
                    trade_date,
                    open_price,
                    high_price,
                    ...
                ])
            except oracledb.Error as db_err:
                print(f"   ❌ Błąd DB: {db_err}")

        conn.commit()
        print(f"   ✅ Zaimportowano do bazy plik {file_name}.")
        """

    # Na koniec
    # cursor.close()
    # conn.close()
    print("\n✅ Import z Dropbox zakończony.")

if __name__ == "__main__":
    main()
