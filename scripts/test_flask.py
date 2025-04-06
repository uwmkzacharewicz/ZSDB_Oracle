from flask import Flask, jsonify
from flask import request
import yfinance as yf
import os
import ftplib
import pandas as pd
from config.settings import ftp_conf
from utils import get_connection, get_actual_currency_rate

from flask import jsonify
from import_from_csv import download_csv_file, import_csv_to_oracle
from update_stock_prices import update_stock_prices



app = Flask(__name__)

@app.route("/ping", methods=["GET"])
def ping():
    """Prosty endpoint testowy, zwraca status JSON."""
    return jsonify({"status": "ok", "message": "It works!"})

@app.route("/get-rate", methods=["GET"])
def get_rate():
    usd_to_pln = get_actual_currency_rate("USD")
    if not usd_to_pln:
        return jsonify({"error": "Nie udało się pobrać kursu USD/PLN."}), 500
    return jsonify({"rate": usd_to_pln})

@app.route("/check-company-ticker", methods=["GET"])
def check_company_ticker():
    """Sprawdza, czy ticker spółki istnieje w yfinance."""
    ticker = request.args.get("ticker")
    if not ticker:
        return jsonify({"error": "Brak tickera w zapytaniu."}), 400

    try:
        data = yf.Ticker(ticker)
        hist = data.history(period="1d")

        # Bezpieczna obsługa braku danych
        if hist is None or hist.empty:
            return jsonify({"exists": False})
        return jsonify({"exists": True})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/download-csv", methods=["GET"])
def download_csv():
    try:
        # Krok 1: Pobierz pliki z FTP
        files = download_csv_file()

        if not files:
            return jsonify({"status": "Brak plików do pobrania lub wystąpił błąd."}), 500

        # Krok 2: Przetwórz każdy plik
        for filename in files:
            file_path = os.path.join("archive", filename)
            import_csv_to_oracle(file_path)

        return jsonify({"status": "Import zakonczony", "files": files}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/update-stock", methods=["GET"])
def update_stock():
    try:
        update_stock_prices()
        return jsonify({"status": "ok", "message": "Import zakończony."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route("/update-exchange-rate", methods=["GET"])
def update_exchange_rate():
    try:
        usd_to_pln = get_actual_currency_rate("USD")
        update_exchange_rate()
        if not usd_to_pln:
            return jsonify({"error": "Nie udało się pobrać kursu USD/PLN."}), 500
        return jsonify({"rate": usd_to_pln})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    # uruchamiamy na porcie 5001, nasłuchujemy na 0.0.0.0 (wszystkie interfejsy)
    app.run(host="0.0.0.0", port=5001, debug=True)
