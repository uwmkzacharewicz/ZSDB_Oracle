create or replace FUNCTION get_average_value_pln (
  p_investor_id   IN NUMBER,
  p_period_type   IN VARCHAR2,
  p_period_label  IN VARCHAR2
) RETURN NUMBER IS
  v_avg NUMBER(12,2);
BEGIN
  SELECT ROUND(AVG(total_value_pln), 2)
  INTO v_avg
  FROM (
    SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT
    UNION ALL
    SELECT investor_id, snapshot_date, total_value_pln FROM PORTFOLIOSNAPSHOT_ARCHIVE
  )
  WHERE investor_id = p_investor_id
    AND (
      (p_period_type = 'MONTH'   AND TO_CHAR(snapshot_date, 'YYYY-MM') = p_period_label) OR
      (p_period_type = 'QUARTER' AND TO_CHAR(snapshot_date, 'YYYY') || '-Q' || TO_CHAR(CEIL(TO_NUMBER(TO_CHAR(snapshot_date, 'MM')) / 3)) = p_period_label) OR
      (p_period_type = 'YEAR'    AND TO_CHAR(snapshot_date, 'YYYY') = p_period_label)
    );

  RETURN v_avg;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END;
