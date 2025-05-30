create or replace PROCEDURE         "ADD_INVESTOR" (
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
