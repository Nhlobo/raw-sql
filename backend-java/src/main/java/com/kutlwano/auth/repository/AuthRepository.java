package com.kutlwano.auth.repository;

import com.kutlwano.auth.domain.InternalUserRecord;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class AuthRepository {

    private final JdbcTemplate jdbcTemplate;

    public AuthRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<InternalUserRecord> findInternalUserByEmail(String email) {
        String sql = """
            SELECT
                u.user_id,
                u.username,
                u.email,
                u.password_hash,
                u.account_status::text AS account_status,
                u.user_type::text AS user_type,
                u.primary_role::text AS primary_role,
                u.mfa_status::text AS mfa_status,
                u.password_status::text AS password_status,
                u.failed_login_count,
                u.account_locked_until,
                u.last_login_at,
                p.first_name,
                p.last_name,
                d.department_name,
                j.position_name,
                j.position_id
            FROM security.users u
            LEFT JOIN security.user_profiles p ON p.user_id = u.user_id
            LEFT JOIN security.user_employment e ON e.user_id = u.user_id
            LEFT JOIN core.departments d ON d.department_id = e.department_id
            LEFT JOIN core.job_positions j ON j.position_id = e.position_id
            WHERE u.email = ?
              AND u.user_type = 'internal'
              AND u.archived_at IS NULL
            """;

        List<InternalUserRecord> rows = jdbcTemplate.query(sql, (rs, rowNum) -> {
            InternalUserRecord r = new InternalUserRecord();
            r.setUserId(rs.getObject("user_id", UUID.class));
            r.setUsername(rs.getString("username"));
            r.setEmail(rs.getString("email"));
            r.setPasswordHash(rs.getString("password_hash"));
            r.setAccountStatus(rs.getString("account_status"));
            r.setUserType(rs.getString("user_type"));
            r.setPrimaryRole(rs.getString("primary_role"));
            r.setMfaStatus(rs.getString("mfa_status"));
            r.setPasswordStatus(rs.getString("password_status"));
            r.setFailedLoginCount(rs.getObject("failed_login_count", Integer.class));
            r.setAccountLockedUntil(rs.getObject("account_locked_until", java.time.OffsetDateTime.class));
            r.setLastLoginAt(rs.getObject("last_login_at", java.time.OffsetDateTime.class));
            r.setFirstName(rs.getString("first_name"));
            r.setLastName(rs.getString("last_name"));
            r.setDepartmentName(rs.getString("department_name"));
            r.setPositionName(rs.getString("position_name"));
            r.setPositionId(rs.getObject("position_id", UUID.class));
            return r;
        }, email);

        return rows.stream().findFirst();
    }

    public boolean isTrustedDevice(UUID userId, String fingerprintHash) {
        if (fingerprintHash == null || fingerprintHash.isBlank()) return false;

        Integer count = jdbcTemplate.queryForObject("""
            SELECT COUNT(*)
            FROM security.trusted_devices
            WHERE user_id = ?
              AND fingerprint_hash = ?
              AND is_active = TRUE
              AND (expires_at IS NULL OR expires_at > NOW())
            """, Integer.class, userId, fingerprintHash);

        return count != null && count > 0;
    }

    public void recordLoginHistory(UUID userId, String usernameAttempted, String result, String failureReason,
                                   String ipAddress, String browser, String platform, String fingerprintHash) {
        jdbcTemplate.update("""
            INSERT INTO security.login_history
            (
                user_id,
                username_attempted,
                login_result,
                ip_address,
                browser,
                platform,
                fingerprint_hash,
                failure_reason
            )
            VALUES
            (
                ?, ?, ?::security.login_result, CAST(? AS INET),
                ?::security.browser_type, ?::security.device_platform, ?, ?
            )
            """,
            userId,
            usernameAttempted,
            result,
            ipAddress,
            browser == null ? "unknown" : browser,
            platform == null ? "unknown" : platform,
            fingerprintHash,
            failureReason
        );
    }
}
