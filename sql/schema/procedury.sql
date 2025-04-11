
--------------------------------------------------------
-- PROCEDURY
--------------------------------------------------------
-- Procedura dodająca nową firmę do bazy danych
-- oraz logująca operację w tabeli LOG
-- Parametry:
-- p_name     - nazwa firmy
-- p_ticker   - ticker giełdowy
-- p_sector   - sektor działalności
-- p_country  - kraj siedziby
-- p_website  - strona internetowa

CREATE OR REPLACE PROCEDURE ADD_COMPANY (
    p_name     IN VARCHAR2,
    p_ticker   IN VARCHAR2,
    p_sector   IN VARCHAR2,
    p_country  IN VARCHAR2,
    p_website  IN VARCHAR2
) AS
    v_err_msg  VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO Company (name, ticker, sector, country, website)
    VALUES (p_name, p_ticker, p_sector, p_country, p_website);

    -- log sukcesu
    INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
    VALUES ('OK','INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'COMPANY', 'add_company', 'Dodano firmę: ' || p_name);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;

        -- log błędu
        BEGIN
            INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR','INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'COMPANY', 'add_company', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE_APPLICATION_ERROR(-20001, 'Błąd podczas dodawania firmy: ' || v_err_msg);
END;
/


-- Procedura dodająca nowego inwestora do bazy danych
-- oraz logująca operację w tabeli LOG
-- Parametry:
-- p_client_code - kod klienta
-- p_name        - imię i nazwisko inwestora
-- p_email       - adres e-mail inwestora
-- p_phone       - numer telefonu inwestora
-- p_national_id - numer PESEL lub inny identyfikator

CREATE OR REPLACE PROCEDURE ADD_INVESTOR (
    p_client_code IN VARCHAR2,
    p_name     IN VARCHAR2,
    p_email   IN VARCHAR2,
    p_phone   IN VARCHAR2,
    p_national_id  IN VARCHAR2
) AS
    v_err_msg  VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO Investor (client_code, name, email, phone, national_id)
    VALUES (p_client_code, p_name, p_email, p_phone, p_national_id);

    -- log sukcesu
    INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
    VALUES ('OK','INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'INVESTOR', 'add_investor', 'Dodano inwestora: ' || p_name);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;

        -- log błędu
        BEGIN
            INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR','INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'INVESTOR', 'add_investor', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE_APPLICATION_ERROR(-20001, 'Błąd podczas dodawania inwestora: ' || v_err_msg);
END;

-- Procedura dodająca nową transakcję do bazy danych
-- oraz logująca operację w tabeli LOG
-- Parametry:
-- p_investor_id      - ID inwestora
-- p_company_id       - ID firmy
-- p_operation        - operacja ('BUY' lub 'SELL')
-- p_shares           - liczba akcji
-- p_price_per_share  - cena za akcję
-- p_commission_pct   - procent prowizji (domyślnie 0)
-- Procedura ta aktualizuje również portfel inwestora
-- oraz dodaje wpis do tabeli TRANSACTION
CREATE OR REPLACE PROCEDURE MAKE_TRANSACTION (
    p_investor_id      IN NUMBER,
    p_company_id       IN NUMBER,
    p_operation        IN VARCHAR2,  -- 'BUY' lub 'SELL'
    p_shares           IN NUMBER,
    p_price_per_share  IN NUMBER,
    p_commission_pct   IN NUMBER DEFAULT 0
) AS
    v_total_value   NUMBER(12, 2);
    v_err_msg       VARCHAR2(4000);
    v_existing_shares NUMBER;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- Oblicz wartość transakcji z uwzględnieniem prowizji
    v_total_value := p_shares * p_price_per_share * (1 + p_commission_pct / 100);

    IF p_operation = 'SELL' THEN
        -- Sprawdź czy inwestor ma wystarczającą liczbę akcji
        SELECT NVL(shares, 0) INTO v_existing_shares
        FROM Portfolio
        WHERE investor_id = p_investor_id AND company_id = p_company_id;

        IF v_existing_shares < p_shares THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nie można sprzedać więcej akcji niż posiadanych.');
        END IF;

        -- Zmniejsz stan posiadania
        UPDATE Portfolio
        SET shares = shares - p_shares,
            avg_price = CASE WHEN shares - p_shares > 0 THEN avg_price ELSE NULL END,
            last_updated = CURRENT_TIMESTAMP
        WHERE investor_id = p_investor_id AND company_id = p_company_id;

    ELSIF p_operation = 'BUY' THEN
        -- Jeśli istnieje rekord, aktualizuj; jeśli nie, dodaj
        BEGIN
            SELECT shares INTO v_existing_shares
            FROM Portfolio
            WHERE investor_id = p_investor_id AND company_id = p_company_id;

            UPDATE Portfolio
            SET
                shares = shares + p_shares,
                avg_price = ROUND(((avg_price * shares) + (p_price_per_share * p_shares)) / (shares + p_shares), 2),
                last_updated = CURRENT_TIMESTAMP
            WHERE investor_id = p_investor_id AND company_id = p_company_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO Portfolio (investor_id, company_id, shares, avg_price)
                VALUES (p_investor_id, p_company_id, p_shares, p_price_per_share);
        END;
    ELSE
        RAISE_APPLICATION_ERROR(-20006, 'Nieznana operacja. Dozwolone: BUY lub SELL.');
    END IF;

    -- Dodaj wpis transakcji
    INSERT INTO Transaction (
        investor_id, company_id, operation, shares,
        price_per_share, total_value, transaction_date
    ) VALUES (
        p_investor_id, p_company_id, p_operation, p_shares,
        p_price_per_share, v_total_value, SYSDATE
    );

    -- Dodaj log
    INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
    VALUES ('OK', 'INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'TRANSACTION',
            'make_transaction', 'Transakcja: ' || p_operation || ' ' || p_shares || ' akcji');

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;
        BEGIN
            INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR', 'INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'TRANSACTION',
                    'make_transaction', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        RAISE_APPLICATION_ERROR(-20010, 'Błąd transakcji: ' || v_err_msg);
END;

-- Procedura dodająca nową cenę akcji do bazy danych
-- oraz logująca operację w tabeli LOG
-- Parametry:
-- p_company_id        - ID firmy
-- p_trade_date        - data transakcji
-- p_open_price        - cena otwarcia
-- p_high_price        - cena maksymalna
-- p_low_price         - cena minimalna
-- p_close_price       - cena zamknięcia
-- p_volume            - wolumen
-- p_currency          - waluta
-- p_close_price_pln   - cena zamknięcia w PLN
-- Procedura ta sprawdza, czy dla danej firmy i daty
-- już istnieje wpis w tabeli STOCKPRICE. Jeśli tak, to
-- aktualizuje go, jeśli nie, to dodaje nowy wpis.

CREATE OR REPLACE PROCEDURE insert_stock_price (
    p_company_id        IN NUMBER,
    p_trade_date        IN DATE,
    p_open_price        IN NUMBER,
    p_high_price        IN NUMBER,
    p_low_price         IN NUMBER,
    p_close_price       IN NUMBER,
    p_volume            IN NUMBER,
    p_currency          IN VARCHAR2,
    p_close_price_pln   IN NUMBER
) AS
    v_err_msg       VARCHAR2(4000);
    v_current_date  DATE;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- Krok 1: Sprawdź, czy mamy już rekord w STOCK_PRICE dla spółki
    v_current_date := get_latest_trade_date(p_company_id);

    IF v_current_date IS NULL THEN
        -- Brak rekordu, wstawiamy 1. raz
        INSERT INTO STOCKPRICE (
            COMPANY_ID, TRADE_DATE, OPEN_PRICE, HIGH_PRICE, LOW_PRICE,
            CLOSE_PRICE, VOLUME, CURRENCY, CLOSE_PRICE_PLN, SOURCE
        )
        VALUES (
            p_company_id, p_trade_date, p_open_price, p_high_price, p_low_price,
            p_close_price, p_volume, p_currency, p_close_price_pln, 'yfinance'
        );

        INSERT INTO LOG (
            STATUS, OPERATION, USER_NAME, TABLE_NAME, ACTION_DETAIL, MESSAGE
        )
        VALUES (
            'OK', 'INSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'),
            'STOCKPRICE', 'insert_stock_price',
            'Pierwszy zapis danych notowań dla spółki ID: ' || p_company_id
        );
        COMMIT;

    ELSIF p_trade_date > v_current_date THEN
        -- Nowsze dane: archiwizujemy stary, usuwamy go i wstawiamy nowy
        INSERT INTO STOCKPRICE_ARCHIVE (
            COMPANY_ID, TRADE_DATE, OPEN_PRICE, HIGH_PRICE, LOW_PRICE, CLOSE_PRICE,
            VOLUME, CURRENCY, CLOSE_PRICE_PLN, DELETED_BY, NOTE
        )
        SELECT COMPANY_ID, TRADE_DATE, OPEN_PRICE, HIGH_PRICE, LOW_PRICE, CLOSE_PRICE,
               VOLUME, CURRENCY, CLOSE_PRICE_PLN,
               SYS_CONTEXT('USERENV', 'SESSION_USER'),
               'Zastąpiono nowym rekordem (nowsza data)'
        FROM STOCKPRICE
        WHERE COMPANY_ID = p_company_id;

        DELETE FROM STOCKPRICE
        WHERE COMPANY_ID = p_company_id;

        INSERT INTO STOCKPRICE (
            COMPANY_ID, TRADE_DATE, OPEN_PRICE, HIGH_PRICE, LOW_PRICE,
            CLOSE_PRICE, VOLUME, CURRENCY, CLOSE_PRICE_PLN, SOURCE
        )
        VALUES (
            p_company_id, p_trade_date, p_open_price, p_high_price, p_low_price,
            p_close_price, p_volume, p_currency, p_close_price_pln, 'yfinance'
        );

        INSERT INTO LOG (
            STATUS, OPERATION, USER_NAME, TABLE_NAME, ACTION_DETAIL, MESSAGE
        )
        VALUES (
            'OK', 'UPSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'),
            'STOCKPRICE', 'insert_stock_price',
            'Zaktualizowano danymi nowszymi (firma ID: ' || p_company_id || ')'
        );

        COMMIT;

    ELSIF p_trade_date = v_current_date THEN
        -- Taka sama data = nic nie robimy, tylko log
        INSERT INTO LOG (
            STATUS, OPERATION, USER_NAME, TABLE_NAME, ACTION_DETAIL, MESSAGE
        )
        VALUES (
            'INFO', 'SKIP_SAME_DATE', SYS_CONTEXT('USERENV', 'SESSION_USER'),
            'STOCKPRICE', 'insert_stock_price',
            'Dane dla spółki ID: ' || p_company_id ||
            ' z datą ' || TO_CHAR(p_trade_date,'YYYY-MM-DD') ||
            ' już istnieją - pomijam.'
        );
        COMMIT;

    ELSE
        -- p_trade_date < v_current_date => dane są starsze
        INSERT INTO LOG (
            STATUS, OPERATION, USER_NAME, TABLE_NAME, ACTION_DETAIL, MESSAGE
        )
        VALUES (
            'INFO', 'SKIP_OLDER_DATE', SYS_CONTEXT('USERENV', 'SESSION_USER'),
            'STOCKPRICE', 'insert_stock_price',
            'Przyszły starsze dane (firma ID: ' || p_company_id ||
            ' z datą ' || TO_CHAR(p_trade_date,'YYYY-MM-DD') || ') - ignoruję.'
        );
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;
        -- log błędu
        BEGIN
            INSERT INTO LOG (
                STATUS, OPERATION, USER_NAME, TABLE_NAME, ACTION_DETAIL, MESSAGE
            )
            VALUES (
                'ERROR', 'UPSERT', SYS_CONTEXT('USERENV', 'SESSION_USER'),
                'STOCKPRICE', 'insert_stock_price', TO_CLOB(v_err_msg)
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        RAISE_APPLICATION_ERROR(-20001, 'Błąd insert_stock_price: ' || v_err_msg);
END;

-- Procedura dodająca nowy kurs wymiany do bazy danych
-- oraz logująca operację w tabeli LOG
-- Parametry:
-- p_currency     - waluta
-- p_rate_to_pln  - kurs wymiany do PLN
-- Procedura ta sprawdza, czy dla danej waluty i daty
-- już istnieje wpis w tabeli EXCHANGERATE. Jeśli tak, to
-- pomija dodanie, jeśli nie, to dodaje nowy wpis.
CREATE OR REPLACE PROCEDURE insert_exchange_rate(
    p_currency     IN VARCHAR2,
    p_rate_to_pln  IN NUMBER
)
IS
    v_exists   NUMBER;
    v_user     VARCHAR2(50);
    v_err_msg  VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');

    -- Sprawdź czy dla danej waluty i daty już istnieje wpis
    SELECT COUNT(*) INTO v_exists
    FROM EXCHANGERATE
    WHERE CURRENCY = p_currency AND RATE_DATE = TRUNC(SYSDATE);

    IF v_exists = 0 THEN
        INSERT INTO EXCHANGERATE (CURRENCY, RATE_TO_PLN, RATE_DATE)
        VALUES (p_currency, p_rate_to_pln, TRUNC(SYSDATE));

        INSERT INTO LOG (status, operation, user_name, table_name, action_detail, message)
        VALUES ('OK', 'INSERT', v_user, 'EXCHANGERATE', 'insert_exchange_rate',
                'Dodano kurs ' || p_currency || ' = ' || p_rate_to_pln || ' PLN');

        COMMIT;
    ELSE
        INSERT INTO LOG (status, operation, user_name, table_name, action_detail, message)
        VALUES ('OK', 'SKIPPED', v_user, 'EXCHANGERATE', 'insert_exchange_rate',
                'Pominięto dodanie – kurs ' || p_currency || ' już istnieje dla dzisiejszej daty.');

        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;
        BEGIN
            INSERT INTO LOG (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR', 'INSERT', v_user, 'EXCHANGERATE', 'insert_exchange_rate', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        RAISE_APPLICATION_ERROR(-20001, 'Błąd przy dodawaniu kursu: ' || v_err_msg);
END;
