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

def update_stock_prices():
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT company_id, ticker FROM Company")
        companies = cursor.fetchall()
        print(f"Znaleziono {len(companies)} firm w bazie.")

        usd_to_pln = get_actual_currency_rate("USD")
        if not usd_to_pln:
            print("Nie udało się pobrać kursu USD/PLN. Anuluję pobieranie notowań.")
            return

        print(f"Kurs USD/PLN: {usd_to_pln}")

        for company_id, ticker in companies:
            print(f"Pobieram notowania dla spółki {ticker} (company_id={company_id})...")
            try:
                data = yf.Ticker(ticker)
                hist = data.history(period="5d")

                if hist.empty:
                    print(f"Brak danych w yfinance dla {ticker}. Pomijam.")
                    continue

                # WALIDACJA, brak danych
                hist = hist.dropna(subset=['Open', 'High', 'Low', 'Close', 'Volume'])
                if hist.empty:
                    print(f"Dane po walidacji puste. Pomijam.")
                    continue

                # CSV
                archive_file = os.path.join(ARCHIVE_DIR, f"{ticker}_{datetime.date.today()}.csv")
                hist.to_csv(archive_file)
                print(f"Zarchiwizowano dane do: {archive_file}")

                # ŁADOWANIE do bazy
                rows_inserted = 0
                for date, row in hist.iterrows():
                    #trade_date = date.to_pydatetime()
                    trade_date = date.date()
                    open_price = float(row['Open'])
                    high_price = float(row['High'])
                    low_price = float(row['Low'])
                    close_usd = float(row['Close'])
                    volume = int(row['Volume']) if pd.notna(row['Volume']) else 0
                    close_pln = round(close_usd * usd_to_pln, 2)

                    # Walidacja logiki danych
                    if open_price < 0 or high_price < 0 or low_price < 0 or close_usd < 0 or volume < 0:
                        print(f"Nieprawidłowe dane dla {ticker} na {trade_date}. Pomijam.")
                        continue

                    if trade_date > datetime.date.today():
                        print(f"Data z przyszłości ({trade_date}) — pomijam.")
                        continue

                    if volume < 0:
                        print(f"Wolumen ujemny dla {ticker} - pomijam.")
                        continue

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
                            close_pln,
                            'yfinance',
                        ])

                    except oracledb.Error as e:
                        print(f"Błąd podczas wstawiania: {e}")
                conn.commit()
                print(f"Dodano {rows_inserted} wierszy dla {ticker}.")
            except Exception as e:
                print(f"Błąd przy pobieraniu danych dla {ticker}: {e}")
                continue
        print("Import notowań zakończony.")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Błąd główny: {e}")

def update_exchange_rate():
    try:
        conn = get_connection()
        cursor = conn.cursor()

        # Pobierz aktualny kurs USD/PLN
        usd_to_pln = get_actual_currency_rate("USD")
        if not usd_to_pln:
            print("Nie udało się pobrać kursu USD/PLN.")
            return

        # Zapisz kurs do bazy
        cursor.callproc("insert_exchange_rate", [usd_to_pln])
        conn.commit()
        print(f"Zaktualizowano kurs USD/PLN: {usd_to_pln}")

    except Exception as e:
        print(f"Błąd podczas aktualizacji kursu: {e}")
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    update_stock_prices()
