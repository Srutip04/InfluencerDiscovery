
resource "aws_db_subnet_group" "aurora_subnets" {
  name       = "${var.project}-aurora-subnets-${var.env}"
  subnet_ids = [] # fill with subnet ids
}

# Aurora Serverless / Aurora cluster - placeholder. Configure engine_version, subnet_group, vpc_security_group_ids in production.
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${var.project}-aurora-${var.env}"
  engine                  = "aurora-postgresql"
  engine_version          = "13.6"
  backup_retention_period = 7
  database_name           = "increator"
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnets.name
  skip_final_snapshot     = true
}
