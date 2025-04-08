DECLARE
  l_base_url VARCHAR2(2000) := 'http://192.168.1.200:5001/get-company-info';
  l_ticker   VARCHAR2(100) := :P2_TICKER;
  l_url      VARCHAR2(2000);
  l_response CLOB;
BEGIN
   l_url := l_base_url || '?ticker=' || UTL_URL.ESCAPE(l_ticker);
  l_response := APEX_WEB_SERVICE.make_rest_request(
    p_url         => l_url,
    p_http_method => 'GET'
  );

  :P2_NEW := l_response;
END;