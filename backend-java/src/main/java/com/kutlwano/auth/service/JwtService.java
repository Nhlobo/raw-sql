package com.kutlwano.auth.service;

import com.kutlwano.auth.config.AppProperties;
import com.kutlwano.auth.domain.InternalUserRecord;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
public class JwtService {

    private final AppProperties appProperties;

    public JwtService(AppProperties appProperties) {
        this.appProperties = appProperties;
    }

    public String generateAccessToken(InternalUserRecord user, String dashboard) {
        Instant now = Instant.now();
        Instant expiry = now.plus(appProperties.getJwt().getAccessTokenMinutes(), ChronoUnit.MINUTES);

        return Jwts.builder()
            .subject(user.getUserId().toString())
            .issuer(appProperties.getJwt().getIssuer())
            .issuedAt(Date.from(now))
            .expiration(Date.from(expiry))
            .claim("email", user.getEmail())
            .claim("role", user.getPrimaryRole())
            .claim("position", user.getPositionName())
            .claim("department", user.getDepartmentName())
            .claim("dashboard", dashboard)
            .signWith(getSigningKey())
            .compact();
    }

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(appProperties.getJwt().getSecret().getBytes(StandardCharsets.UTF_8));
    }
}
