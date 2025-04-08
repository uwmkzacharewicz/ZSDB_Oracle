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
