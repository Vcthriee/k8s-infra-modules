# RDS Subnet Group - places database in isolated database subnets
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-rds-subnet-group"
  description = "Subnet group for RDS PostgreSQL"
  subnet_ids  = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-subnet-group"
  }
}

# RDS Parameter Group - PostgreSQL configuration
resource "aws_db_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-rds-params"
  family      = "postgres14"
  description = "Custom parameters for PostgreSQL 14"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries > 1 second
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-params"
  }
}

# RDS Instance - PostgreSQL primary
resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "14.17"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted   = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  multi_az               = var.db_multi_az
  publicly_accessible    = false

  backup_retention_period = var.db_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot

  performance_insights_enabled    = true
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}