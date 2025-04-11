BEGIN
  FOR rec IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

BEGIN
    FOR rec IN (SELECT object_name, object_type FROM user_objects) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || rec.object_type || ' "' || rec.object_name || '"';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Nie udało się usunąć: ' || rec.object_type || ' ' || rec.object_name || ' - ' || SQLERRM);
        END;
    END LOOP;
END;
/

