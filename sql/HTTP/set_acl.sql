-- Jako SYS

SELECT username
FROM dba_users
WHERE username LIKE 'APEX_%';


BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
    acl         => 'flask_acl.xml',
    description => 'ACL for Flask test',
    principal   => 'APEX_240200',
    is_grant    => TRUE,
    privilege   => 'connect'
  );
END;
/
COMMIT;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
    acl        => 'flask_acl.xml',
    host       => '192.168.1.200',
    lower_port => 5001,
    upper_port => 5001
  );
END;
/
COMMIT;

SELECT acl, host, lower_port, upper_port
FROM   dba_host_acls
WHERE  host = '192.168.1.200';

SELECT acl, principal, privilege
FROM   dba_network_acl_privileges
WHERE  principal = 'APEX_240200';

