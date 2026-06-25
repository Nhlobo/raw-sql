package com.kutlwano.auth.service;

import com.kutlwano.auth.domain.InternalUserRecord;
import com.kutlwano.auth.dto.LoginRequest;
import com.kutlwano.auth.dto.LoginResponse;
import com.kutlwano.auth.repository.AuthRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;

@Service
public class AuthService {

    private final AuthRepository authRepository;
    private final PasswordEncoder passwordEncoder;
    private final DashboardResolver dashboardResolver;
    private final JwtService jwtService;

    public AuthService(AuthRepository authRepository,
                       PasswordEncoder passwordEncoder,
                       DashboardResolver dashboardResolver,
                       JwtService jwtService) {
        this.authRepository = authRepository;
        this.passwordEncoder = passwordEncoder;
        this.dashboardResolver = dashboardResolver;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request, String ipAddress) {
        InternalUserRecord user = authRepository.findInternalUserByEmail(request.getEmail().trim().toLowerCase())
            .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        validateUserBeforePassword(user);

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            authRepository.recordLoginHistory(
                user.getUserId(),
                request.getEmail(),
                "failed",
                "INVALID_PASSWORD",
                ipAddress,
                request.getBrowser(),
                request.getDevicePlatform(),
                request.getFingerprintHash()
            );
            throw new RuntimeException("Invalid credentials");
        }

        boolean trustedDevice = authRepository.isTrustedDevice(user.getUserId(), request.getFingerprintHash());
        boolean requiresMfa = !"not_enabled".equalsIgnoreCase(user.getMfaStatus());
        boolean requiresDeviceVerification = !trustedDevice;

        String dashboard = dashboardResolver.resolve(user);
        String accessToken = jwtService.generateAccessToken(user, dashboard);

        authRepository.recordLoginHistory(
            user.getUserId(),
            request.getEmail(),
            "success",
            null,
            ipAddress,
            request.getBrowser(),
            request.getDevicePlatform(),
            request.getFingerprintHash()
        );

        LoginResponse response = new LoginResponse();
        response.setAccessToken(accessToken);
        response.setDashboard(dashboard);
        response.setRequiresMfa(requiresMfa);
        response.setRequiresDeviceVerification(requiresDeviceVerification);

        LoginResponse.UserSummary summary = new LoginResponse.UserSummary();
        summary.setUserId(user.getUserId().toString());
        summary.setEmail(user.getEmail());
        summary.setFirstName(user.getFirstName());
        summary.setLastName(user.getLastName());
        summary.setRole(user.getPrimaryRole());
        summary.setPosition(user.getPositionName());
        summary.setDepartment(user.getDepartmentName());

        response.setUser(summary);
        return response;
    }

    private void validateUserBeforePassword(InternalUserRecord user) {
        if (!"internal".equalsIgnoreCase(user.getUserType())) {
            throw new RuntimeException("User is not an internal platform user");
        }

        if ("pending_activation".equalsIgnoreCase(user.getAccountStatus())) {
            throw new RuntimeException("Account pending activation");
        }

        if ("inactive".equalsIgnoreCase(user.getAccountStatus())
            || "disabled".equalsIgnoreCase(user.getAccountStatus())
            || "suspended".equalsIgnoreCase(user.getAccountStatus())
            || "terminated".equalsIgnoreCase(user.getAccountStatus())
            || "archived".equalsIgnoreCase(user.getAccountStatus())) {
            throw new RuntimeException("Account is not active");
        }

        if ("locked".equalsIgnoreCase(user.getAccountStatus())) {
            throw new RuntimeException("Account is locked");
        }

        if (user.getAccountLockedUntil() != null && user.getAccountLockedUntil().isAfter(OffsetDateTime.now())) {
            throw new RuntimeException("Account is temporarily locked");
        }

        if ("expired".equalsIgnoreCase(user.getPasswordStatus())
            || "reset_required".equalsIgnoreCase(user.getPasswordStatus())) {
            throw new RuntimeException("Password reset required");
        }
    }
}
