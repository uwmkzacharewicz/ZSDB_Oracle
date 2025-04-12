create or replace PROCEDURE EDIT_INVESTOR (
    p_id       IN NUMBER,
    p_client_code IN VARCHAR2,
    p_name     IN VARCHAR2,
    p_email   IN VARCHAR2,
    p_phone   IN VARCHAR2,
    p_national_id  IN VARCHAR2
) AS
    v_err_msg  VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    UPDATE Investor
    SET client_code = p_client_code, name = p_name, email = p_email, phone = p_phone, national_id = p_national_id
    WHERE investor_id = p_id;

    -- log sukcesu
    INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
    VALUES ('OK','UPDATE', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'INVESTOR', 'edit_investor', 'Edytowano inwestora: ' || p_name);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;

        -- log błędu
        BEGIN
            INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR','UPDATE', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'INVESTOR', 'edit_investor', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE_APPLICATION_ERROR(-20001, 'Błąd podczas edytowania inwestora: ' || v_err_msg);
END;