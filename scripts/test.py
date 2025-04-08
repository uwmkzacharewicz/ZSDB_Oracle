import yfinance as yf

ticker = yf.Ticker("AAPL")
info = ticker.info

print(info["longName"])       # Apple Inc.
print(info["sector"])         # Technology
print(info["country"])        # United States
print(info["website"])        # https://www.apple.com/
print(info["currency"])       # USD


import requests

import requests


import requests

def search_ticker_by_name(name):
    url = f"https://query1.finance.yahoo.com/v1/finance/search?q={name}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    }
    response = requests.get(url, headers=headers)

    print("STATUS:", response.status_code)
    print("HEADERS:", response.headers)
    print("BODY:", response.text)

    if response.status_code == 200:
        results = response.json()
        return [(r['symbol'], r.get('shortname', r.get('longname', ''))) for r in results['quotes']]
    elif response.status_code == 429:
        raise Exception("Za dużo zapytań — odczekaj chwilę.")
    else:
        raise Exception(f"Niepoprawna odpowiedź HTTP: {response.status_code}")



tickers = search_ticker_by_name("Google")
for symbol, full_name in tickers:
    print(f"{symbol}: {full_name}")
