# DynamoDB Module Outputs

output "cafeteria_orders_table_name" {
  description = "Name of the cafeteria orders DynamoDB table"
  value       = aws_dynamodb_table.cafeteria_orders.name
}

output "cafeteria_orders_table_arn" {
  description = "ARN of the cafeteria orders DynamoDB table"
  value       = aws_dynamodb_table.cafeteria_orders.arn
}

output "support_tickets_table_name" {
  description = "Name of the support tickets DynamoDB table"
  value       = aws_dynamodb_table.support_tickets.name
}

output "support_tickets_table_arn" {
  description = "ARN of the support tickets DynamoDB table"
  value       = aws_dynamodb_table.support_tickets.arn
}

output "absence_justifications_table_name" {
  description = "Name of the absence justifications DynamoDB table"
  value       = aws_dynamodb_table.absence_justifications.name
}

output "absence_justifications_table_arn" {
  description = "ARN of the absence justifications DynamoDB table"
  value       = aws_dynamodb_table.absence_justifications.arn
}

output "all_table_names" {
  description = "Map of all table names"
  value = {
    cafeteria_orders         = aws_dynamodb_table.cafeteria_orders.name
    support_tickets          = aws_dynamodb_table.support_tickets.name
    absence_justifications   = aws_dynamodb_table.absence_justifications.name
  }
}

output "all_table_arns" {
  description = "List of all table ARNs for IAM policies"
  value = [
    aws_dynamodb_table.cafeteria_orders.arn,
    aws_dynamodb_table.support_tickets.arn,
    aws_dynamodb_table.absence_justifications.arn,
  ]
}
