#!/bin/bash
systemctl --user start podman.socket

export PASSWORD=My_Strong_Pa55word
export HOST=db23c.micronautdata.vcnatlas.oraclevcn.com
export SERVICE=pdb1.micronautdata.vcnatlas.oraclevcn.com

/home/opc/sqlcl/bin/sql -s system/$PASSWORD@$HOST:1521/$SERVICE <<EOF
    create user micronaut_data_$RUNID identified by "Oracle_19_Password" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
    alter user micronaut_data_$RUNID quota unlimited on users;
    grant CREATE SESSION, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE ANY INDEX, EXECUTE ANY TYPE to micronaut_data_$RUNID;
EOF

export JDBC_URL="jdbc:oracle:thin:@${HOST}:1521/${SERVICE}"
export JDBC_USER="micronaut_data_${RUNID}"
export JDBC_PASSWORD="Oracle_19_Password"

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
        url: ${JDBC_URL:`jdbc:oracle:thin:@localhost:1521/XEPDB1`}
        username: ${JDBC_USER:system}
        password: ${JDBC_PASSWORD:S3cr3TP4$$wd}
        driverClassName: ${JDBC_DRIVER:oracle.jdbc.driver.OracleDriver}

    micronaut:
      http:
        client:
          read-timeout: 5m
EOF
