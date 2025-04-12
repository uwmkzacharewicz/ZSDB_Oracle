CREATE OR REPLACE TRIGGER trg_generate_summary_after_snapshot
AFTER INSERT ON PORTFOLIOSNAPSHOT
FOR EACH ROW
BEGIN
  generate_portfolio_summary('MONTH', :NEW.investor_id);
  generate_portfolio_summary('QUARTER', :NEW.investor_id);
  generate_portfolio_summary('YEAR', :NEW.investor_id);
END;
/
