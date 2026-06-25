package com.kutlwano.auth.dto;

public class LoginResponse {
    private String accessToken;
    private String dashboard;
    private boolean requiresMfa;
    private boolean requiresDeviceVerification;
    private UserSummary user;

    public String getAccessToken() { return accessToken; }
    public void setAccessToken(String accessToken) { this.accessToken = accessToken; }

    public String getDashboard() { return dashboard; }
    public void setDashboard(String dashboard) { this.dashboard = dashboard; }

    public boolean isRequiresMfa() { return requiresMfa; }
    public void setRequiresMfa(boolean requiresMfa) { this.requiresMfa = requiresMfa; }

    public boolean isRequiresDeviceVerification() { return requiresDeviceVerification; }
    public void setRequiresDeviceVerification(boolean requiresDeviceVerification) { this.requiresDeviceVerification = requiresDeviceVerification; }

    public UserSummary getUser() { return user; }
    public void setUser(UserSummary user) { this.user = user; }

    public static class UserSummary {
        private String userId;
        private String email;
        private String firstName;
        private String lastName;
        private String role;
        private String position;
        private String department;

        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }

        public String getFirstName() { return firstName; }
        public void setFirstName(String firstName) { this.firstName = firstName; }

        public String getLastName() { return lastName; }
        public void setLastName(String lastName) { this.lastName = lastName; }

        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }

        public String getPosition() { return position; }
        public void setPosition(String position) { this.position = position; }

        public String getDepartment() { return department; }
        public void setDepartment(String department) { this.department = department; }
    }
}
