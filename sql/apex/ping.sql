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
  l_name VARCHAR2(100);
    l_ticker VARCHAR2(100);
    l_sector VARCHAR2(100);
    l_country VARCHAR2(100);
    l_website VARCHAR2(100);
BEGIN
  l_response := APEX_WEB_SERVICE.make_rest_request(
    p_url         => l_url,
    p_http_method => 'GET'
  );

    l_name := JSON_VALUE(l_response, '$.longName');
    l_ticker := JSON_VALUE(l_response, '$.ticker');
    l_sector := JSON_VALUE(l_response, '$.sector');
    l_country := JSON_VALUE(l_response, '$.country');
    l_website := JSON_VALUE(l_response, '$.website');

    :P2_NAME := l_name;
    :P2_TICKER := l_ticker;
    :P2_SECTOR := l_sector;
    :P2_COUNTRY := l_country;
    :P2_WEBSITE := l_website;

END;



