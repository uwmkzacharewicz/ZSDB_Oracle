create or replace PROCEDURE generate_daily_portfolio_snapshots IS
  CURSOR c_investors IS
    SELECT investor_id FROM INVESTOR;

  v_total_value NUMBER(12, 2);
BEGIN
  FOR inv IN c_investors LOOP
    SELECT SUM(p.shares * get_current_stock_value(p.company_id))
    INTO v_total_value
    FROM PORTFOLIO p
    WHERE p.investor_id = inv.investor_id;

    INSERT INTO PORTFOLIOSNAPSHOT (INVESTOR_ID, SNAPSHOT_DATE, TOTAL_VALUE_PLN)
    VALUES (inv.investor_id, SYSDATE, v_total_value);
  END LOOP;
END;
