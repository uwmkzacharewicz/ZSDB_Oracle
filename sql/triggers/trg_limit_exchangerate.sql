CREATE OR REPLACE TRIGGER trg_limit_exchangerate
BEFORE INSERT ON EXCHANGERATE
FOR EACH ROW
DECLARE
    v_count NUMBER;
    v_oldest_id NUMBER;
    v_user VARCHAR2(50);
    v_err_msg VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');

    SELECT COUNT(*) INTO v_count FROM EXCHANGERATE;

    IF v_count >= 10 THEN
        SELECT RATE_ID INTO v_oldest_id
        FROM EXCHANGERATE
        WHERE RATE_DATE = (SELECT MIN(RATE_DATE) FROM EXCHANGERATE)
        FETCH FIRST 1 ROWS ONLY;

        -- Archiwizuj i usuń
        INSERT INTO EXCHANGERATE_ARCHIVE (RATE_ID, CURRENCY, RATE_TO_PLN, RATE_DATE)
        SELECT RATE_ID, CURRENCY, RATE_TO_PLN, RATE_DATE
        FROM EXCHANGERATE
        WHERE RATE_ID = v_oldest_id;

        DELETE FROM EXCHANGERATE WHERE RATE_ID = v_oldest_id;

        -- Loguj przeniesienie
        INSERT INTO LOG (status, operation, user_name, table_name, action_detail, message)
        VALUES ('OK', 'ARCHIVE', v_user, 'EXCHANGERATE', 'trg_limit_exchangerate',
                'Przeniesiono rekord RATE_ID=' || v_oldest_id || ' do EXCHANGERATE_ARCHIVE');

        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;
        BEGIN
            INSERT INTO LOG (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR', 'ARCHIVE', v_user, 'EXCHANGERATE', 'trg_limit_exchangerate', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        RAISE;
END;
