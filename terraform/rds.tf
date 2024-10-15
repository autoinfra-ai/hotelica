# RDS Subnet Group
resource "aws_db_subnet_group" "hotelica_db_subnet_group" {
  name       = "hotelica-db-subnet-group"
  subnet_ids = [aws_subnet.perplexica_subnet_1.id, aws_subnet.perplexica_subnet_2.id]

  tags = {
    Name = "Hotelica DB Subnet Group"
  }
}

# RDS Security Group
resource "aws_security_group" "hotelica_db_sg" {
  name        = "hotelica-db-sg"
  description = "Security group for Hotelica RDS"
  vpc_id      = aws_vpc.perplexica_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Hotelica DB Security Group"
  }
}

# Add this rule after both security groups are created
resource "aws_security_group_rule" "hotelica_db_sg_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.perplexica_sg.id
  security_group_id        = aws_security_group.hotelica_db_sg.id
}

# RDS Instance
resource "aws_db_instance" "hotelica_db" {
  identifier           = "hotelica-db"
  engine               = "postgres"
  engine_version       = "16.4"  # Latest version aas of now
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  storage_type         = "gp3"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres16"

  vpc_security_group_ids = [aws_security_group.hotelica_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.hotelica_db_subnet_group.name

  backup_retention_period = 7
  skip_final_snapshot     = true
  multi_az                = false
  publicly_accessible     = false

  tags = {
    Name = "Hotelica DB"
  }
}

# SSM Parameter for DB URL
resource "aws_ssm_parameter" "db_url" {
  name  = "/hotelica/DB_URL"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.hotelica_db.endpoint}/${var.db_name}"
}

# Output the DB endpoint
output "db_endpoint" {
  value     = aws_db_instance.hotelica_db.endpoint
  sensitive = true
}
