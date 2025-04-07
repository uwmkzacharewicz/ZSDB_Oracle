CREATE OR REPLACE VIEW v_current_portfolio_value AS
SELECT
    p.investor_id,
    SUM(
        p.shares
        * (SELECT s.close_price
             FROM STOCKPRICE s
            WHERE s.company_id = p.company_id
            ORDER BY s.trade_date DESC
            FETCH FIRST 1 ROWS ONLY)
        * (SELECT e.rate_to_pln
             FROM EXCHANGERATE e
            WHERE e.currency = 'USD'
            ORDER BY e.rate_date DESC
            FETCH FIRST 1 ROWS ONLY)
    ) AS total_value_pln
FROM PORTFOLIO p
GROUP BY p.investor_id;
