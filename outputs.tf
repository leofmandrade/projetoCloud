output "db_endpoint" {
  description = "Endpoint do banco de dados"
  value       = aws_db_instance.db.address
}

output "db_port" {
  description = "Porta do banco de dados"
  value       = aws_db_instance.db.port
}

