#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from utils import *
import oracledb
import yfinance as yf
import pandas as pd
import datetime
import sys
import os

ARCHIVE_DIR = os.path.join(os.path.dirname(__file__), "..", "archive")
os.makedirs(ARCHIVE_DIR, exist_ok=True)

def main():
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT company_id, ticker FROM Company")
        companies = cursor.fetchall()
        print(f"Znaleziono {len(companies)} firm w bazie.")

        usd_to_pln = get_actual_currency_rate("USD")
        if not usd_to_pln:
            print("❌ Nie udało się pobrać kursu USD/PLN. Anuluję pobieranie notowań.")
            return

        print(f"Kurs USD/PLN: {usd_to_pln}")

        for company_id, ticker in companies:
            print(f"➡ Pobieram notowania dla spółki {ticker} (company_id={company_id})...")
            try:
                data = yf.Ticker(ticker)
                hist = data.history(period="5d")

                if hist.empty:
                    print(f"   ⚠ Brak danych w yfinance dla {ticker}. Pomijam.")
                    continue

                # 🆕 WALIDACJA
                hist = hist.dropna(subset=['Open', 'High', 'Low', 'Close', 'Volume'])
                if hist.empty:
                    print(f"   ⚠ Dane po walidacji puste (NaN-y usunięte). Pomijam.")
                    continue

                # 🆕 CSV
                archive_file = os.path.join(ARCHIVE_DIR, f"{ticker}_{datetime.date.today()}.csv")
                hist.to_csv(archive_file)
                print(f"   📁 Zarchiwizowano dane do: {archive_file}")

                # ŁADOWANIE do bazy
                rows_inserted = 0
                # 5) Iteruj po wierszach DataFrame i wywołuj procedurę
                for date, row in hist.iterrows():
                    trade_date = date.to_pydatetime()
                    open_price = float(row['Open'])
                    high_price = float(row['High'])
                    low_price = float(row['Low'])
                    close_usd = float(row['Close'])
                    volume = int(row['Volume']) if pd.notna(row['Volume']) else 0
                    close_pln = round(close_usd * usd_to_pln, 2)

                    try:
                        cursor.callproc("insert_stock_price", [
                            company_id,
                            trade_date,
                            open_price,
                            high_price,
                            low_price,
                            close_usd,
                            volume,
                            'USD',
                            close_pln
                        ])
                        rows_inserted += 1
                    except oracledb.Error as e:
                        print(f"      ❌ Błąd podczas wstawiania danych dla {ticker} w dniu {trade_date}: {e}")
                conn.commit()
                print(f"   ✅ Dodano {rows_inserted} wierszy dla {ticker}.")
            except Exception as e:
                print(f"   ❌ Błąd przy pobieraniu danych dla {ticker}: {e}")
                continue
        print("✅ Import notowań zakończony.")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Błąd główny: {e}")


if __name__ == "__main__":
    main()
