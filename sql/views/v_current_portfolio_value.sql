CREATE OR REPLACE VIEW v_current_portfolio_value AS
SELECT
    p.investor_id,
    i.name AS investor_name,
    i.email AS investor_email,
    i.client_code,
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
JOIN INVESTOR i ON p.investor_id = i.investor_id
GROUP BY p.investor_id, i.name, i.email, i.client_code;