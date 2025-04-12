create or replace PROCEDURE         "EDIT_COMPANY" (
    p_id       IN NUMBER,
    p_name     IN VARCHAR2,
    p_ticker   IN VARCHAR2,
    p_sector   IN VARCHAR2,
    p_country  IN VARCHAR2,
    p_website  IN VARCHAR2
) AS
    v_err_msg  VARCHAR2(4000);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    UPDATE Company
    SET name = p_name, ticker = p_ticker, sector = p_sector, country = p_country, website = p_website
    WHERE company_id = p_id;

    -- log sukcesu
    INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
    VALUES ('OK','UPDATE', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'COMPANY', 'edit_company', 'Edytowano firmę: ' || p_name);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_err_msg := SQLERRM;

        -- log błędu
        BEGIN
            INSERT INTO Log (status, operation, user_name, table_name, action_detail, message)
            VALUES ('ERROR','UPDATE', SYS_CONTEXT('USERENV', 'SESSION_USER'), 'COMPANY', 'edit_company', TO_CLOB(v_err_msg));
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE_APPLICATION_ERROR(-20001, 'Błąd podczas edytowania firmy: ' || v_err_msg);
END;