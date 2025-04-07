BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_TEST_INSERT',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN
                            INSERT INTO test_scheduler_log (message)
                            VALUES (''Job działa o '' || TO_CHAR(SYSTIMESTAMP, ''YYYY-MM-DD HH24:MI:SS.FF''));
                            COMMIT;
                        END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY; INTERVAL=1',
    enabled         => TRUE
  );
END;
/

SELECT job_name, enabled, state, last_start_date, next_run_date
FROM user_scheduler_jobs;



SELECT * FROM test_scheduler_log ORDER BY log_time DESC;
