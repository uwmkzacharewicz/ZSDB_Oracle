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


SELECT JOB_NAME, ENABLED, STATE, LAST_START_DATE, NEXT_RUN_DATE
FROM USER_SCHEDULER_JOBS;

SELECT JOB_NAME, STATUS, ACTUAL_START_DATE, RUN_DURATION, ERROR#
FROM USER_SCHEDULER_JOB_RUN_DETAILS
ORDER BY ACTUAL_START_DATE DESC;




SELECT * FROM test_scheduler_log ORDER BY log_time DESC;
