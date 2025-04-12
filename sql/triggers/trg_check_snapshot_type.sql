create or replace TRIGGER trg_check_snapshot_type
BEFORE INSERT OR UPDATE ON PORTFOLIOSNAPSHOT
FOR EACH ROW
BEGIN
  IF :NEW.SNAPSHOT_TYPE IS NULL OR UPPER(:NEW.SNAPSHOT_TYPE) NOT IN ('DAILY', 'MANUAL', 'SYSTEM') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Nieprawidłowy typ SNAPSHOT_TYPE. Dozwolone: DAILY, MANUAL, SYSTEM.');
  END IF;
END;