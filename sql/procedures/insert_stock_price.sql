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
/
