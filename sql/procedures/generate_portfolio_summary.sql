create or replace PROCEDURE generate_portfolio_summary(
    p_period_type IN VARCHAR2,
    p_investor_id IN NUMBER DEFAULT NULL
) IS
BEGIN
  MERGE INTO PORTFOLIO_SUMMARY s
  USING (
    SELECT
      investor_id,
      UPPER(p_period_type) AS period_type,
      MAX(snapshot_date) AS latest_date,
      TO_NUMBER(TO_CHAR(MAX(snapshot_date), 'YYYY')) AS period_year,
      CASE UPPER(p_period_type)
        WHEN 'MONTH' THEN TO_NUMBER(TO_CHAR(MAX(snapshot_date), 'MM'))
        WHEN 'QUARTER' THEN CEIL(TO_NUMBER(TO_CHAR(MAX(snapshot_date), 'MM')) / 3)
        WHEN 'YEAR' THEN 1
      END AS period_number,
      CASE UPPER(p_period_type)
        WHEN 'MONTH' THEN TO_CHAR(MAX(snapshot_date), 'YYYY-MM')
        WHEN 'QUARTER' THEN TO_CHAR(MAX(snapshot_date), 'YYYY') || '-Q' || TO_CHAR(CEIL(TO_NUMBER(TO_CHAR(MAX(snapshot_date), 'MM')) / 3))
        WHEN 'YEAR' THEN TO_CHAR(MAX(snapshot_date), 'YYYY')
      END AS period_label
    FROM (
      SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT
      WHERE p_investor_id IS NULL OR investor_id = p_investor_id
      UNION ALL
      SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT_ARCHIVE
      WHERE p_investor_id IS NULL OR investor_id = p_investor_id
    )
    GROUP BY investor_id,
      CASE UPPER(p_period_type)
        WHEN 'MONTH' THEN TO_CHAR(snapshot_date, 'YYYY-MM')
        WHEN 'QUARTER' THEN TO_CHAR(snapshot_date, 'YYYY') || '-Q' || TO_CHAR(CEIL(TO_NUMBER(TO_CHAR(snapshot_date, 'MM')) / 3))
        WHEN 'YEAR' THEN TO_CHAR(snapshot_date, 'YYYY')
      END
  ) latest
  ON (
    s.investor_id = latest.investor_id AND
    s.period_type = latest.period_type AND
    s.period_label = latest.period_label
  )
  WHEN MATCHED THEN
    UPDATE SET
      total_value_pln = (
        SELECT total_value_pln FROM (
          SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT
          WHERE p_investor_id IS NULL OR investor_id = latest.investor_id
          UNION ALL
          SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT_ARCHIVE
          WHERE p_investor_id IS NULL OR investor_id = latest.investor_id
        )
        WHERE investor_id = latest.investor_id AND snapshot_date = latest.latest_date
        FETCH FIRST 1 ROWS ONLY
      ),
      average_price_pln = get_average_value_pln(
        latest.investor_id,
        latest.period_type,
        latest.period_label
      ),
      generated_at = SYSTIMESTAMP
  WHEN NOT MATCHED THEN
    INSERT (
      investor_id,
      period_type,
      period_label,
      period_year,
      period_number,
      total_value_pln,
      average_price_pln,
      generated_at
    ) VALUES (
      latest.investor_id,
      latest.period_type,
      latest.period_label,
      latest.period_year,
      latest.period_number,
      (
        SELECT total_value_pln FROM (
          SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT
          WHERE p_investor_id IS NULL OR investor_id = latest.investor_id
          UNION ALL
          SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT_ARCHIVE
          WHERE p_investor_id IS NULL OR investor_id = latest.investor_id
        )
        WHERE investor_id = latest.investor_id AND snapshot_date = latest.latest_date
        FETCH FIRST 1 ROWS ONLY
      ),
      get_average_value_pln(
        latest.investor_id,
        latest.period_type,
        latest.period_label
      ),
      SYSTIMESTAMP
    );
END;