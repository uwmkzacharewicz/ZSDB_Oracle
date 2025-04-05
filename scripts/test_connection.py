#!/usr/bin/env python
# -*- coding: utf-8 -*-
from utils import get_connection

def test_connection():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM DUAL")
        result = cursor.fetchone()
        if result[0] == 1:
            print("✅ Połączenie z bazą danych działa poprawnie.")
        else:
            print("❌ Błąd połączenia z bazą danych.")
    except Exception as e:
        print(f"❌ Błąd połączenia z bazą danych: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    test_connection()
