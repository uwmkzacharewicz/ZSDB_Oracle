CREATE OR REPLACE VIEW v_company_stock_prices_all AS
SELECT
    c.company_id,
    c.name AS company_name,
    c.ticker,
    s.trade_date,
    s.open_price,
    s.high_price,
    s.low_price,
    s.close_price,
    ROUND(s.close_price * get_exchange_rate('USD'), 2) AS close_price_pln,
    s.volume
FROM (
    SELECT company_id, trade_date, open_price, high_price, low_price, close_price, volume
    FROM STOCKPRICE
    UNION ALL
    SELECT company_id, trade_date, open_price, high_price, low_price, close_price, volume
    FROM STOCKPRICE_ARCHIVE
) s
JOIN COMPANY c ON s.company_id = c.company_id;