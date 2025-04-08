CREATE OR REPLACE FUNCTION calculate_new_avg_price (
    p_current_avg    IN NUMBER,
    p_current_shares IN NUMBER,
    p_new_price      IN NUMBER,
    p_new_shares     IN NUMBER
) RETURN NUMBER
IS
    v_total_cost   NUMBER;
    v_total_shares NUMBER;
BEGIN
    v_total_cost := (p_current_avg * p_current_shares) + (p_new_price * p_new_shares);
    v_total_shares := p_current_shares + p_new_shares;

    IF v_total_shares = 0 THEN
        RETURN 0;  -- lub NULL, jeśli nie ma akcji
    ELSE
        RETURN ROUND(v_total_cost / v_total_shares, 2);
    END IF;
END;
