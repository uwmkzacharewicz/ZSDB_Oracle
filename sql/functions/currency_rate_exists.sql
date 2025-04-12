create or replace FUNCTION currency_rate_exists (
    p_currency IN VARCHAR2,
    p_date     IN DATE
) RETURN BOOLEAN
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM EXCHANGERATE
    WHERE CURRENCY = p_currency
      AND RATE_DATE = TRUNC(p_date);

    RETURN v_count > 0;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE; 
END;