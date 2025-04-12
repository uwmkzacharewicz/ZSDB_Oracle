create or replace PROCEDURE delete_company (
    p_id       IN NUMBER,
    p_name     IN VARCHAR2
) AS
    v_err_msg  VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    DELETE FROM Company WHERE company_id=p_id;

    -- log sukcesu
    INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
    VALUES ('OK','DELETE', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'COMPANY', 'delete_company', 'Usunięto firmę: ' || p_name);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;

        -- log błędu
        BEGIN
            INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR','DELETE', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'COMPANY', 'delete_company', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE_APPLICATION_ERROR(-20001, 'Błąd podczas usuwania firmy: ' || v_err_msg);
END;