#!/bin/bash
#systemctl --user start podman.socket

echo "Configuring database connectivity for ${1}..."

export INFO=$(curl -s -k -L -X GET "https://api.atlas-controller.oraclecloud.com/ords/atlas/admin/database?type=${1}&hostname=`hostname`" -H 'accept: application/json')
export HOST=$(echo $INFO | jq -r '.database' | jq -r '.host')
export SERVICE=$(echo $INFO | jq -r '.database' | jq -r '.service')
export PASSWORD=$(echo $INFO | jq -r '.database' | jq -r '.password')

#export PASSWORD=My_Strong_Pa55word
#export HOST=db23c.micronautdata.vcnatlas.oraclevcn.com
#export SERVICE=pdb1.micronautdata.vcnatlas.oraclevcn.com

case "${1}" in
    "autonomous")
      curl -s -X POST "https://${HOST}.oraclecloudapps.com/ords/admin/_/sql" -H 'content-type: application/sql' -H 'accept: application/json' -basic -u admin:${PASSWORD} --data-ascii "create user micronaut_data_${RUNID} identified by \"Oracle_19_Password\" DEFAULT TABLESPACE DATA TEMPORARY TABLESPACE TEMP;alter user micronaut_data_${RUNID} quota unlimited on data;grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_${RUNID};"
      curl -s -X POST "https://${HOST}.oraclecloudapps.com/ords/admin/_/sql" -H 'content-type: application/sql' -H 'accept: application/json' -basic -u admin:${PASSWORD} --data-ascii "create user micronaut_data_${RUNID}_foo identified by \"Oracle_19_Password\" DEFAULT TABLESPACE DATA TEMPORARY TABLESPACE TEMP;alter user micronaut_data_${RUNID}_foo quota unlimited on data;grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_${RUNID}_foo;"
      curl -s -X POST "https://${HOST}.oraclecloudapps.com/ords/admin/_/sql" -H 'content-type: application/sql' -H 'accept: application/json' -basic -u admin:${PASSWORD} --data-ascii "create user micronaut_data_${RUNID}_bar identified by \"Oracle_19_Password\" DEFAULT TABLESPACE DATA TEMPORARY TABLESPACE TEMP;alter user micronaut_data_${RUNID}_bar quota unlimited on data;grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_${RUNID}_bar;"

      export JDBC_URL="jdbc:oracle:thin:@(description=(retry_count=5)(retry_delay=1)(address=(protocol=tcps)(port=1521)(host=${HOST}.oraclecloud.com))(connect_data=(service_name=${SERVICE}_tp.adb.oraclecloud.com))(security=(ssl_server_dn_match=no)))?oracle.jdbc.enableQueryResultCache=false&oracle.jdbc.thinForceDNSLoadBalancing=true&tcp.nodelay=yes"
      export JDBC_USER="micronaut_data_${RUNID}"
      export JDBC_PASSWORD="Oracle_19_Password"
      ;;
    *)
      /home/opc/sqlcl/bin/sql -s system/$PASSWORD@$HOST:1521/$SERVICE <<EOF
          create user micronaut_data_${RUNID} identified by "Oracle_19_Password" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
          alter user micronaut_data_${RUNID} quota unlimited on users;
          grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_${RUNID};
          -- foo
          create user micronaut_data_${RUNID}_foo identified by "Oracle_19_Password" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
          alter user micronaut_data_${RUNID}_foo quota unlimited on users;
          grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_${RUNID}_foo;
          -- bar
          create user micronaut_data_${RUNID}_bar identified by "Oracle_19_Password" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
          alter user micronaut_data_${RUNID}_bar quota unlimited on users;
          grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_${RUNID}_bar;
EOF

      export JDBC_URL="jdbc:oracle:thin:@${HOST}:1521/${SERVICE}"
      export JDBC_USER="micronaut_data_${RUNID}"
      export JDBC_PASSWORD="Oracle_19_Password"
      ;;
esac;

cat <<EOF > ./data-jdbc/src/test/resources/application.yml
test-resources:
  containers:
    mssql:
      accept-license: true
      startup-timeout: 300s
    mariadb:
      startup-timeout: 300s
    mysql:
      startup-timeout: 300s
    postgres:
      startup-timeout: 300s

datasources:
  default:
    url: ${JDBC_URL}
    username: ${JDBC_USER}
    password: ${JDBC_PASSWORD}
    driverClassName: oracle.jdbc.driver.OracleDriver
    schema-generate: CREATE
    db-type: oracle
    dialect: oracle
  foo:
    url: ${JDBC_URL}
    username: ${JDBC_USER}_foo
    password: ${JDBC_PASSWORD}
    driverClassName: oracle.jdbc.driver.OracleDriver
    schema-generate: CREATE
    db-type: oracle
    dialect: oracle
  bar:
    url: ${JDBC_URL}
    username: ${JDBC_USER}_bar
    password: ${JDBC_PASSWORD}
    driverClassName: oracle.jdbc.driver.OracleDriver
    schema-generate: CREATE
    db-type: oracle
    dialect: oracle

micronaut:
  http:
    client:
      read-timeout: 5m
EOF
