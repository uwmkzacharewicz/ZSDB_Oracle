
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_SNAPSHOT_TEST',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'generate_daily_portfolio_snapshots',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=23; BYMINUTE=59',
    enabled         => TRUE
  );
END;
/

-- odrazu uruchamiamy job
BEGIN
  DBMS_SCHEDULER.RUN_JOB('JOB_SNAPSHOT_TEST');
END;
/
