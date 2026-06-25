package com.kutlwano.auth.domain;

import java.time.OffsetDateTime;
import java.util.UUID;

public class InternalUserRecord {
    private UUID userId;
    private String username;
    private String email;
    private String passwordHash;
    private String accountStatus;
    private String userType;
    private String primaryRole;
    private String mfaStatus;
    private String passwordStatus;
    private Integer failedLoginCount;
    private OffsetDateTime accountLockedUntil;
    private OffsetDateTime lastLoginAt;
    private String firstName;
    private String lastName;
    private String departmentName;
    private String positionName;
    private UUID positionId;

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getAccountStatus() { return accountStatus; }
    public void setAccountStatus(String accountStatus) { this.accountStatus = accountStatus; }

    public String getUserType() { return userType; }
    public void setUserType(String userType) { this.userType = userType; }

    public String getPrimaryRole() { return primaryRole; }
    public void setPrimaryRole(String primaryRole) { this.primaryRole = primaryRole; }

    public String getMfaStatus() { return mfaStatus; }
    public void setMfaStatus(String mfaStatus) { this.mfaStatus = mfaStatus; }

    public String getPasswordStatus() { return passwordStatus; }
    public void setPasswordStatus(String passwordStatus) { this.passwordStatus = passwordStatus; }

    public Integer getFailedLoginCount() { return failedLoginCount; }
    public void setFailedLoginCount(Integer failedLoginCount) { this.failedLoginCount = failedLoginCount; }

    public OffsetDateTime getAccountLockedUntil() { return accountLockedUntil; }
    public void setAccountLockedUntil(OffsetDateTime accountLockedUntil) { this.accountLockedUntil = accountLockedUntil; }

    public OffsetDateTime getLastLoginAt() { return lastLoginAt; }
    public void setLastLoginAt(OffsetDateTime lastLoginAt) { this.lastLoginAt = lastLoginAt; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getDepartmentName() { return departmentName; }
    public void setDepartmentName(String departmentName) { this.departmentName = departmentName; }

    public String getPositionName() { return positionName; }
    public void setPositionName(String positionName) { this.positionName = positionName; }

    public UUID getPositionId() { return positionId; }
    public void setPositionId(UUID positionId) { this.positionId = positionId; }
}
