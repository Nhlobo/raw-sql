package com.kutlwano.auth.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

@Configuration
public class DataSourceConfig {

    @Bean
    public DataSource dataSource(@Value("${JDBC_DATABASE_URL:}") String jdbcDatabaseUrl,
                                 @Value("${DATABASE_URL:}") String databaseUrl,
                                 @Value("${DB_USERNAME:}") String dbUsername,
                                 @Value("${DB_PASSWORD:}") String dbPassword) {

        DatabaseConnection connection;

        if (StringUtils.hasText(jdbcDatabaseUrl)) {
            connection = new DatabaseConnection(jdbcDatabaseUrl, dbUsername, dbPassword);
        } else if (StringUtils.hasText(databaseUrl)) {
            connection = toJdbcConnection(databaseUrl, dbUsername, dbPassword);
        } else {
            throw new IllegalStateException("Set JDBC_DATABASE_URL or DATABASE_URL before starting the application");
        }

        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setJdbcUrl(connection.url());
        dataSource.setDriverClassName("org.postgresql.Driver");

        if (StringUtils.hasText(connection.username())) {
            dataSource.setUsername(connection.username());
        }

        if (StringUtils.hasText(connection.password())) {
            dataSource.setPassword(connection.password());
        }

        return dataSource;
    }

    private DatabaseConnection toJdbcConnection(String databaseUrl, String fallbackUsername, String fallbackPassword) {
        if (databaseUrl.startsWith("jdbc:postgresql://")) {
            return new DatabaseConnection(databaseUrl, fallbackUsername, fallbackPassword);
        }

        URI uri = URI.create(databaseUrl);
        if (!"postgres".equals(uri.getScheme()) && !"postgresql".equals(uri.getScheme())) {
            throw new IllegalStateException("DATABASE_URL must use postgres, postgresql, or jdbc:postgresql scheme");
        }

        String query = StringUtils.hasText(uri.getQuery()) ? "?" + uri.getQuery() : "";
        String username = StringUtils.hasText(fallbackUsername) ? fallbackUsername : username(uri);
        String password = StringUtils.hasText(fallbackPassword) ? fallbackPassword : password(uri);

        return new DatabaseConnection(
            "jdbc:postgresql://" + uri.getHost() + port(uri) + uri.getPath() + query,
            username,
            password
        );
    }

    private String port(URI uri) {
        return uri.getPort() == -1 ? "" : ":" + uri.getPort();
    }

    private String username(URI uri) {
        String userInfo = uri.getUserInfo();
        if (!StringUtils.hasText(userInfo)) return null;
        return decode(userInfo.split(":", 2)[0]);
    }

    private String password(URI uri) {
        String userInfo = uri.getUserInfo();
        if (!StringUtils.hasText(userInfo) || !userInfo.contains(":")) return null;
        return decode(userInfo.split(":", 2)[1]);
    }

    private String decode(String value) {
        return URLDecoder.decode(value, StandardCharsets.UTF_8);
    }

    private record DatabaseConnection(String url, String username, String password) {
    }
}
