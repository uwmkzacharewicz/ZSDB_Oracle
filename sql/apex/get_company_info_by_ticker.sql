DECLARE
  l_base_url   VARCHAR2(2000) := 'http://192.168.1.200:5001/get-company-info';
  l_ticker_in  VARCHAR2(100)  := :P2_FINDTICKER;
  l_response   CLOB;
  l_url        VARCHAR2(2000);

  l_name       VARCHAR2(400);
  l_sector     VARCHAR2(200);
  l_country    VARCHAR2(100);
  l_website    VARCHAR2(200);
BEGIN
  l_url := l_base_url || '?ticker=' || UTL_URL.ESCAPE(l_ticker_in);

  l_response := APEX_WEB_SERVICE.make_rest_request(
    p_url         => l_url,
    p_http_method => 'GET'
  );

  l_name    := JSON_VALUE(l_response, '$.name');
  l_sector  := JSON_VALUE(l_response, '$.sector');
  l_country := JSON_VALUE(l_response, '$.country');
  l_website := JSON_VALUE(l_response, '$.website');

  IF l_name IS NULL THEN
    :P2_ERROR_MSG := 'Nie znaleziono danych dla "' || l_ticker_in || '"';

    -- Wyczyść inne pola
    :P2_NAME    := NULL;
    :P2_TICKER  := NULL;
    :P2_SECTOR  := NULL;
    :P2_COUNTRY := NULL;
    :P2_WEBSITE := NULL;
  ELSE
    :P2_ERROR_MSG := NULL;

    :P2_NAME    := l_name;
    :P2_TICKER  := l_ticker_in;
    :P2_SECTOR  := l_sector;
    :P2_COUNTRY := l_country;
    :P2_WEBSITE := l_website;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    :P2_ERROR_MSG := 'Wystąpił błąd: ' || SQLERRM;
    :P2_NAME := NULL;
    :P2_TICKER := NULL;
    :P2_SECTOR := NULL;
    :P2_COUNTRY := NULL;
    :P2_WEBSITE := NULL;
END;
