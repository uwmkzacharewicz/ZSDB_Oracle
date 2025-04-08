DECLARE
  l_url      VARCHAR2(2000) := 'http://192.168.1.200:5001/ping';
  l_response CLOB;
BEGIN
  l_response := APEX_WEB_SERVICE.make_rest_request(
    p_url         => l_url,
    p_http_method => 'GET'
  );

  :P1_MSG := l_response;
END;

DECLARE
  l_url      VARCHAR2(2000) := 'http://192.168.1.200:5001/get-company-info';
  l_response CLOB;
BEGIN
  l_response := APEX_WEB_SERVICE.make_rest_request(
    p_url         => l_url,
    p_http_method => 'GET'
  );
  :P2_NEW := l_response;
END;

DECLARE
  l_url      VARCHAR2(2000) := 'http://192.168.1.200:5001/update-exchange-rate';
  l_response CLOB;
  l_rate     NUMBER;
BEGIN
  l_response := APEX_WEB_SERVICE.make_rest_request(
    p_url         => l_url,
    p_http_method => 'GET'
  );

  l_rate := JSON_VALUE(l_response, '$.rate');
  :P2_NEW := l_rate;
END;



