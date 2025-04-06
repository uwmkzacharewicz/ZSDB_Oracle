import os
import ftplib
import pandas as pd
from config.settings import ftp_conf
from utils import get_connection, get_actual_currency_rate

# Ustawienia
REMOTE_FILENAME = "stock_prices.csv"
LOCAL_DIR = "archive"
os.makedirs(LOCAL_DIR, exist_ok=True)
LOCAL_PATH = os.path.join(LOCAL_DIR, REMOTE_FILENAME)

def download_csv_file():
    print("🔌 Łączenie z FTP...")

    try:
        ftp = ftplib.FTP()
        ftp.connect(ftp_conf["host"])
        ftp.login(ftp_conf["user"], ftp_conf["password"])
        ftp.cwd(ftp_conf["remote_dir"])

        print(f"Katalog FTP: {ftp.pwd()}")
        print(f"Pobieranie pliku: {REMOTE_FILENAME}")

        files = ftp.nlst()
        csv_files = [f for f in files if f.lower().endswith('.csv')]

        for filename in csv_files:
            local_path = os.path.join(LOCAL_DIR, filename)
            with open(local_path, 'wb') as f:
                ftp.retrbinary(f"RETR " + filename, f.write)
            print(f"⬇️  Pobrano: {filename}")

        with open(LOCAL_PATH, "wb") as f:
            ftp.retrbinary(f"RETR {REMOTE_FILENAME}", f.write)

        ftp.quit()
        print(f"✅ Plik zapisany lokalnie jako: {LOCAL_PATH}")
        return csv_files

    except Exception as e:
        print(f"❌ Błąd FTP: {e}")


def import_csv_to_oracle(file_path):
    print(f"📂 Przetwarzam plik: {file_path}")
    try:
        df = pd.read_csv(
            file_path,
            sep=',',
            decimal='.',
            parse_dates=['TRADE_DATE'],
            dayfirst=False
        )
    except Exception as e:
        print(f"❌ Błąd odczytu pliku {file_path}: {e}")
        return

    df = df.dropna(subset=[
        'COMPANY_ID', 'TRADE_DATE', 'OPEN_PRICE',
        'HIGH_PRICE', 'LOW_PRICE', 'CLOSE_PRICE', 'VOLUME'
    ])

    print(df.dtypes)

    inserted = 0
    conn = get_connection()
    cursor = conn.cursor()

    usd_to_pln = get_actual_currency_rate("USD")

    for _, row in df.iterrows():
        close_price = float(row['CLOSE_PRICE'])
        close_price_pln = close_price * usd_to_pln if not pd.isna(close_price) else None

        try:
            cursor.callproc("insert_stock_price", [
                int(row['COMPANY_ID']),
                row['TRADE_DATE'],
                float(row['OPEN_PRICE']),
                float(row['HIGH_PRICE']),
                float(row['LOW_PRICE']),
                close_price,
                int(row['VOLUME']),
                row.get('CURRENCY', 'USD'),
                close_price_pln,
                row.get('SOURCE', 'csv')
            ])
            inserted += 1
        except Exception as e:
            print(f"❗ Błąd podczas wstawiania rekordu: {e}")

    conn.commit()
    cursor.close()
    conn.close()

    print(f"✅ Dodano {inserted} rekordów z pliku {file_path}.")



def main():
    files = download_csv_file()
    for filename in files:
        path = os.path.join(LOCAL_DIR, filename)
        import_csv_to_oracle(path)

if __name__ == "__main__":
    main()
