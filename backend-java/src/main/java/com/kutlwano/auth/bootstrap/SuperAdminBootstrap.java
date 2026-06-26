package com.kutlwano.auth.bootstrap;

import com.kutlwano.auth.config.BootstrapProperties;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.UUID;

@Component
@ConditionalOnProperty(prefix = "bootstrap.admin", name = "enabled", havingValue = "true")
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class SuperAdminBootstrap implements CommandLineRunner {

    private final BootstrapProperties properties;
    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;

    public SuperAdminBootstrap(BootstrapProperties properties,
                               JdbcTemplate jdbcTemplate,
                               PasswordEncoder passwordEncoder) {
        this.properties = properties;
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        validate();

        Integer existing = jdbcTemplate.queryForObject("""
            SELECT COUNT(*)
            FROM security.users
            WHERE email = ?
               OR username = ?
               OR primary_role = 'super_admin'
            """, Integer.class,
            properties.getEmail().trim().toLowerCase(),
            properties.getUsername().trim().toLowerCase()
        );

        if (existing != null && existing > 0) {
            System.out.println("Bootstrap skipped: super admin already exists.");
            return;
        }

        UUID userId = UUID.randomUUID();
        UUID profileId = UUID.randomUUID();

        String passwordHash = passwordEncoder.encode(properties.getPassword());

        jdbcTemplate.update("""
            INSERT INTO security.users
            (
                user_id,
                username,
                email,
                password_hash,
                account_status,
                user_type,
                primary_role,
                mfa_status,
                password_status,
                failed_login_count,
                must_change_password,
                security_stamp,
                concurrency_stamp
            )
            VALUES
            (
                ?,
                ?,
                ?,
                ?,
                'active',
                'internal',
                'super_admin',
                'not_enabled',
                'valid',
                0,
                FALSE,
                gen_random_uuid(),
                gen_random_uuid()
            )
            """,
            userId,
            properties.getUsername().trim().toLowerCase(),
            properties.getEmail().trim().toLowerCase(),
            passwordHash
        );

        jdbcTemplate.update("""
            INSERT INTO security.user_profiles
            (
                profile_id,
                user_id,
                first_name,
                last_name
            )
            VALUES
            (
                ?,
                ?,
                ?,
                ?
            )
            """,
            profileId,
            userId,
            properties.getFirstName().trim(),
            properties.getLastName().trim()
        );

        System.out.println("Bootstrap success: super admin created -> " + properties.getEmail());
    }

    private void validate() {
        if (!StringUtils.hasText(properties.getUsername())
                || !StringUtils.hasText(properties.getEmail())
                || !StringUtils.hasText(properties.getPassword())
                || !StringUtils.hasText(properties.getFirstName())
                || !StringUtils.hasText(properties.getLastName())) {
            throw new IllegalStateException("Set all bootstrap.admin.* values before enabling bootstrap");
        }
    }
}
