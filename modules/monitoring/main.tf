# ============================================================================
# MODULE: AZURE MONITOR (Log Analytics + App Insights)
# ============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# AMÉLIORATION: Action Group pour alertes (recommandation du rapport)
resource "azurerm_monitor_action_group" "security" {
  count = var.enable_alerting ? 1 : 0

  name                = "${var.log_analytics_name}-security-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "SecAlert"

  email_receiver {
    name          = "SecurityTeam"
    email_address = var.alert_email
  }

  tags = var.tags
}

# AMÉLIORATION: Alerte pour violations ABAC
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "abac_violations" {
  count = var.enable_alerting ? 1 : 0

  name                = "abac-violations-alert"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  scopes               = [azurerm_log_analytics_workspace.main.id]
  severity             = 2

  criteria {
    query                   = <<-QUERY
      StorageBlobLogs
      | where TimeGenerated > ago(5m)
      | where StatusCode == 403
      | summarize count() by bin(TimeGenerated, 5m)
    QUERY
    time_aggregation_method = "Count"
    threshold               = 10
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.security[0].id]
  }

  tags = var.tags
}
