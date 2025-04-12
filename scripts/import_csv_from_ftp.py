#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import pandas as pd
import ftplib
from datetime import datetime
from utils import get_connection
from config.settings import ftp_conf

# === Katalog lokalny do pobierania CSV ===
LOCAL_DIR = './downloads'
os.makedirs(LOCAL_DIR, exist_ok=True)

# === POBIERZ WSZYSTKIE CSV Z FTP ===
def download_csv_files():
    ftp = ftplib.FTP()
    ftp.connect(ftp_conf["host"])
    ftp.login(ftp_conf["user"], ftp_conf["password"])
    ftp.cwd(ftp_conf["remote_dir"])

    files = ftp.nlst()
    csv_files = [f for f in files if f.lower().endswith('.csv')]

    print(f"🔗 Połączono z FTP. Znaleziono {len(csv_files)} plików CSV.")

    for filename in csv_files:
        local_path = os.path.join(LOCAL_DIR, filename)
        with open(local_path, 'wb') as f:
            ftp.retrbinary(f"RETR " + filename, f.write)
        print(f"⬇️  Pobrano: {filename}")

    ftp.quit()
    return csv_files

# === IMPORTUJ JEDEN PLIK CSV DO BAZY ===
def import_csv_to_oracle(file_path):
    print(f"Przetwarzam plik: {file_path}")
    try:
        df = pd.read_csv(
            file_path,
            sep=',',
            decimal='.',
            parse_dates=['TRADE_DATE'],
            dayfirst=True
        )
    except Exception as e:
        print(f"Błąd odczytu pliku {file_path}: {e}")
        return

    df = df.dropna(subset=[
        'COMPANY_ID', 'TRADE_DATE', 'OPEN_PRICE',
        'HIGH_PRICE', 'LOW_PRICE', 'CLOSE_PRICE', 'VOLUME'
    ])

    inserted = 0
    conn = get_connection()
    cursor = conn.cursor()

    for _, row in df.iterrows():
        try:
            cursor.callproc("insert_stock_price", [
                int(row['COMPANY_ID']),
                row['TRADE_DATE'],
                float(row['OPEN_PRICE']),
                float(row['HIGH_PRICE']),
                float(row['LOW_PRICE']),
                float(row['CLOSE_PRICE']),
                int(row['VOLUME']),
                row.get('CURRENCY', 'USD'),
                row.get('CLOSE_PRICE_PLN'),
                row.get('SOURCE', 'csv')
            ])
            inserted += 1
        except Exception as e:
            print(f"Błąd podczas wstawiania rekordu: {e}")

    conn.commit()
    cursor.close()
    conn.close()

    print(f"Zaimportowano {inserted} rekordów z {os.path.basename(file_path)}")

# === GŁÓWNA FUNKCJA ===
def main():
    files = download_csv_files()
    for filename in files:
        path = os.path.join(LOCAL_DIR, filename)
        import_csv_to_oracle(path)

if __name__ == "__main__":
    main()
