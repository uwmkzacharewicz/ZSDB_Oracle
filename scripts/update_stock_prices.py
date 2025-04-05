#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from utils import *
import oracledb
import yfinance as yf
import datetime
import sys
import os


def main():
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT company_id, ticker FROM Company")
        companies = cursor.fetchall()
        print(f"Znaleziono {len(companies)} firm w bazie.")

        # 3) Pobierz kurs USD/PLN, jeśli potrzebny:
        usd_to_pln = get_actual_currency_rate("USD")
        if not usd_to_pln:
            print("❌ Nie udało się pobrać kursu USD/PLN. Anuluję pobieranie notowań.")
            return

        print(f"Kurs USD/PLN: {usd_to_pln}")

        # 4) Dla każdej firmy pobierz dane z yfinance (np. za ostatnie 5 dni):
        for company_id, ticker in companies:
            print(f"➡ Pobieram notowania dla spółki {ticker} (company_id={company_id})...")
            try:
                data = yf.Ticker(ticker)
                hist = data.history(period="5d")  # np. 5 dni

                if hist.empty:
                    print(f"   ⚠ Brak danych w yfinance dla {ticker}. Pomijam.")
                    continue

                # 5) Iteruj po wierszach DataFrame i wstaw do tabeli StockPrice
                rows_inserted = 0
                for date, row in hist.iterrows():
                    trade_date = date.to_pydatetime()
                    open_price = float(row['Open'])
                    high_price = float(row['High'])
                    low_price  = float(row['Low'])
                    close_usd  = float(row['Close'])
                    volume     = int(row['Volume']) if not (row['Volume'] is None) else 0

                    close_pln = round(close_usd * usd_to_pln, 2)

                    cursor.execute("""
                        INSERT INTO StockPrice (
                          company_id,
                          trade_date,
                          open_price,
                          high_price,
                          low_price,
                          close_price,
                          volume,
                          currency,
                          close_price_pln,
                          source
                        )
                        VALUES (:cid, :td, :op, :hp, :lp, :cp, :vol, 'USD', :cppln, 'yfinance')
                    """, {
                        'cid': company_id,
                        'td': trade_date,
                        'op': open_price,
                        'hp': high_price,
                        'lp': low_price,
                        'cp': close_usd,
                        'vol': volume,
                        'cppln': close_pln
                    })

                    rows_inserted += 1

                conn.commit()
                print(f"   ✅ Dodano {rows_inserted} wierszy notowań dla {ticker}")

            except Exception as e:
                print(f"   ❌ Błąd przy pobieraniu danych dla {ticker}: {e}")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Błąd główny: {e}")


if __name__ == "__main__":
    main()
