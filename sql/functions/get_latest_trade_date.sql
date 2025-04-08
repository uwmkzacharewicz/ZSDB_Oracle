CREATE OR REPLACE FUNCTION get_latest_trade_date(
    p_company_id IN NUMBER
)
RETURN DATE
AS
    v_date DATE;
BEGIN
    SELECT trade_date
      INTO v_date
      FROM stockprice
     WHERE company_id = p_company_id
    ;
    RETURN v_date;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
