# DynamoDB Module for UCEHub
# Creates tables for: Cafeteria Orders, Support Tickets, Absence Justifications

# ============================================================================
# CAFETERIA ORDERS TABLE
# ============================================================================

resource "aws_dynamodb_table" "cafeteria_orders" {
  name           = "${var.project_name}-cafeteria-orders-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing for unpredictable workloads
  hash_key       = "orderId"
  range_key      = "timestamp"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "userEmail"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # GSI for querying orders by user
  global_secondary_index {
    name            = "UserEmailIndex"
    hash_key        = "userEmail"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # GSI for querying orders by status
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cafeteria-orders-${var.environment}"
      Type = "CafeteriaOrders"
    }
  )
}

# ============================================================================
# SUPPORT TICKETS TABLE
# ============================================================================

resource "aws_dynamodb_table" "support_tickets" {
  name           = "${var.project_name}-support-tickets-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ticketId"
  range_key      = "createdAt"

  attribute {
    name = "ticketId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  attribute {
    name = "userEmail"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "priority"
    type = "S"
  }

  # GSI for querying tickets by user
  global_secondary_index {
    name            = "UserEmailIndex"
    hash_key        = "userEmail"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # GSI for querying tickets by status
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # GSI for querying tickets by priority
  global_secondary_index {
    name            = "PriorityIndex"
    hash_key        = "priority"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-support-tickets-${var.environment}"
      Type = "SupportTickets"
    }
  )
}

# ============================================================================
# ABSENCE JUSTIFICATIONS TABLE
# ============================================================================

resource "aws_dynamodb_table" "absence_justifications" {
  name           = "${var.project_name}-absence-justifications-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "justificationId"
  range_key      = "submittedAt"

  attribute {
    name = "justificationId"
    type = "S"
  }

  attribute {
    name = "submittedAt"
    type = "N"
  }

  attribute {
    name = "userEmail"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # GSI for querying justifications by user
  global_secondary_index {
    name            = "UserEmailIndex"
    hash_key        = "userEmail"
    range_key       = "submittedAt"
    projection_type = "ALL"
  }

  # GSI for querying justifications by status
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "submittedAt"
    projection_type = "ALL"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-absence-justifications-${var.environment}"
      Type = "AbsenceJustifications"
    }
  )
}
