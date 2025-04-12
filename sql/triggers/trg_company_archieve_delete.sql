create or replace TRIGGER TRG_COMPANY_ARCHIVE_DELETE
BEFORE DELETE ON company
FOR EACH ROW
BEGIN
    INSERT INTO company_archive (company_id, name, ticker, sector, country, website, deleted_at, deleted_by)
    VALUES (
        :OLD.company_id,
        :OLD.name,
        :OLD.ticker,
        :OLD.sector,
        :OLD.country,
        :OLD.website,
        SYSTIMESTAMP,
        SYS_CONTEXT('USERENV','SESSION_USER')
    );

    log_company_delete(
         p_company_id    => :OLD.company_id,
         p_status        => 'OK',
         p_operation     => 'DELETE',
         p_table_name    => 'COMPANY',
         p_action_detail => 'Usunięto rekord COMPANY_ID=' || TO_CHAR(:OLD.company_id),
         p_message       => 'Rekord przeniesiony do COMPANY_ARCHIVE'
    );
EXCEPTION
    WHEN OTHERS THEN
       RAISE;
END;