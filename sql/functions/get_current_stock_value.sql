CREATE OR REPLACE FUNCTION get_current_stock_value(p_company_id IN NUMBER)
RETURN NUMBER
IS
    v_close_price STOCKPRICE.close_price%TYPE;
    v_rate_to_pln EXCHANGERATE.rate_to_pln%TYPE;
    v_result NUMBER;
BEGIN
    -- pobierz ostatnią cenę akcji
    SELECT close_price INTO v_close_price
    FROM STOCKPRICE
    WHERE company_id = p_company_id
    ORDER BY trade_date DESC
    FETCH FIRST 1 ROWS ONLY;

    -- pobierz kurs USD/PLN
    SELECT rate_to_pln INTO v_rate_to_pln
    FROM EXCHANGERATE
    WHERE currency = 'USD'
    ORDER BY rate_date DESC
    FETCH FIRST 1 ROWS ONLY;

    -- oblicz wartość
    v_result := ROUND(v_close_price * v_rate_to_pln, 2);

    RETURN v_result;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
/
