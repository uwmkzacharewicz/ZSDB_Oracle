create or replace PROCEDURE  LOG_COMPANY_DELETE (
    p_company_id   IN NUMBER,
    p_status       IN VARCHAR2,
    p_operation    IN VARCHAR2,
    p_table_name   IN VARCHAR2,
    p_action_detail IN VARCHAR2,
    p_message      IN CLOB
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO log (
        status,
        operation,
        user_name,
        table_name,
        action_detail,
        message
    ) VALUES (
        p_status,
        p_operation,
        SYS_CONTEXT('USERENV','SESSION_USER'),
        p_table_name,
        p_action_detail,
        p_message
    );
    COMMIT;  -- Zatwierdzamy transakcję
EXCEPTION
    WHEN OTHERS THEN
       ROLLBACK; -- W przypadku błędu wycofujemy  transakcję
       NULL;
END;

