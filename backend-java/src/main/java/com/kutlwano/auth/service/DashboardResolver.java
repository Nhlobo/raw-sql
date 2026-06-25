package com.kutlwano.auth.service;

import com.kutlwano.auth.domain.InternalUserRecord;
import org.springframework.stereotype.Service;

@Service
public class DashboardResolver {

    public String resolve(InternalUserRecord user) {
        String role = safe(user.getPrimaryRole());
        String position = safe(user.getPositionName()).toLowerCase();

        return switch (role) {
            case "super_admin" -> "ENTERPRISE_CONTROL_CENTRE";
            case "director" -> "EXECUTIVE_DASHBOARD";
            case "operations_manager" -> "OPERATIONS_DASHBOARD";
            case "system_administrator" -> "ADMINISTRATION_DASHBOARD";
            case "appointment_coordinator", "scheduler" -> "SCHEDULING_DASHBOARD";
            case "case_manager" -> "MASTER_FILE_DASHBOARD";
            case "finance_manager", "finance_officer", "finance_clerk", "debtors_controller", "accounts_controller" -> "FINANCE_DASHBOARD";
            case "document_controller", "medical_records_officer" -> "DOCUMENT_MANAGEMENT_DASHBOARD";
            case "report_manager", "report_editor", "report_reviewer" -> "REPORTS_DASHBOARD";
            case "sales_consultant", "crm_manager" -> "SALES_RELATIONSHIP_DASHBOARD";
            case "receptionist" -> "RECEPTION_DASHBOARD";
            case "support" -> "TECHNICAL_SUPPORT_DASHBOARD";
            default -> fromPosition(position);
        };
    }

    private String fromPosition(String position) {
        if (position.contains("reception")) return "RECEPTION_DASHBOARD";
        if (position.contains("appointment")) return "SCHEDULING_DASHBOARD";
        if (position.contains("case manager")) return "MASTER_FILE_DASHBOARD";
        if (position.contains("finance")) return "FINANCE_DASHBOARD";
        if (position.contains("report")) return "REPORTS_DASHBOARD";
        if (position.contains("document")) return "DOCUMENT_MANAGEMENT_DASHBOARD";
        if (position.contains("sales")) return "SALES_RELATIONSHIP_DASHBOARD";
        if (position.contains("support")) return "TECHNICAL_SUPPORT_DASHBOARD";
        if (position.contains("operations")) return "OPERATIONS_DASHBOARD";
        return "GENERAL_INTERNAL_DASHBOARD";
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }
}
