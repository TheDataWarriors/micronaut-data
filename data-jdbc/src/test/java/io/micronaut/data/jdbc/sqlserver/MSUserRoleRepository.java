package io.micronaut.data.jdbc.sqlserver;

import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.tck.repositories.UserRoleRepository;

@JdbcRepository(dialect = Dialect.SQL_SERVER)
public interface MSUserRoleRepository extends UserRoleRepository {
}
