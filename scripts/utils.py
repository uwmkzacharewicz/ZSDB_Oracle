import requests
import oracledb
import json
import os
from config.settings import CONFIG_FILE, ACTIVE_ENV


def load_config(env=ACTIVE_ENV):
    with open(CONFIG_FILE, "r") as file:
        config = json.load(file)
    return config.get(env)

# nawiązanie połączenia z bazą danych zgodnie z konfiguracją
def get_connection(env=ACTIVE_ENV):
    cfg = load_config(env)
    if not cfg:
        raise ValueError(f"Nie znaleziono konfiguracji dla środowiska '{env}'.")

    try:
        conn = oracledb.connect(
            user=cfg["user"],
            password=cfg["password"],
            dsn=cfg["dsn"]
        )
        return conn
    except oracledb.Error as e:
        print(f"Błąd połączenia z bazą danych ({env}): {e}")
        raise



def get_actual_currency_rate(currency_code):
    url = f"https://api.nbp.pl/api/exchangerates/rates/a/{currency_code}/?format=json"
    try:
        request = requests.get(url, timeout=10)
        request.raise_for_status()
        data = request.json()
        exchange_rate = data['rates'][0]['mid']
        print(f"Kurs {currency_code}/PLN: {exchange_rate}")
        return exchange_rate
    except requests.exceptions.RequestException as e:
        print(f"Błąd podczas pobierania danych z NBP: {e}")
    except KeyError:
        print("Nieoczekiwana struktura odpowiedzi z NBP.")
    return None

