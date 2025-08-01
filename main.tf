module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = var.project_prefix
  cidr    = var.vpc_cidr
  azs     = var.azs

  private_subnets = ["172.31.10.0/24", "172.31.11.0/24", "172.31.12.0/24", "172.31.13.0/24"]
  public_subnets  = ["172.31.0.0/24", "172.31.1.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
}

resource "aws_s3_bucket" "bronze_silver" {
  bucket = "${var.project_prefix}"
  force_destroy = true
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_prefix}-rds"
  engine            = "postgres"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  username          = var.db_username
  password          = var.db_password
  db_name           = "travel_itinerary"
  port              = 5432
  publicly_accessible = true
  multi_az            = true
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  db_subnet_group_name   = module.vpc.database_subnet_group
  skip_final_snapshot    = true
}

resource "aws_iam_role" "glue_service_role" {
  name = "glue-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_glue_job" "ingest_job" {
  name     = "IngestToS3job"
  role_arn = aws_iam_role.glue_service_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${var.project_prefix}/scripts/IngestToS3job.py"
    python_version  = "3"
  }
  glue_version = "4.0"
  max_capacity = 2
}

resource "aws_glue_job" "transform_job" {
  name     = "TransformationJob"
  role_arn = aws_iam_role.glue_service_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${var.project_prefix}/scripts/TransformationJob.py"
    python_version  = "3"
  }
  glue_version = "4.0"
  max_capacity = 2
}

resource "aws_glue_crawler" "bronze_crawler" {
  name = "travel_itinerary_raw_crawler"
  role = aws_iam_role.glue_service_role.arn
  database_name = "travel_itinerary_raw"
  s3_target {
    path = "s3://${var.project_prefix}/bronze/2025-07-30_19:52:31/"
  }
}

resource "aws_redshift_cluster" "travel_warehouse" {
  cluster_identifier = "travel-itinerary-cluster"
  node_type          = "ra3.large"
  number_of_nodes    = 2
  database_name      = "travel_itinerary"
  master_username    = "awsuser"
  master_password    = var.redshift_password
  port               = 5439
  cluster_subnet_group_name = module.vpc.database_subnet_group
  vpc_security_group_ids    = [module.vpc.default_security_group_id]
}

resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "Travel-Itinerary-State-Machine"
  role_arn = aws_iam_role.glue_service_role.arn
  definition = jsonencode({
    Comment = "State machine for ETL",
    StartAt = "Run Glue Job - RDS to S3",
    States = {
      "Run Glue Job - RDS to S3" = {
        Type     = "Task",
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "IngestToS3job"
        },
        Next = "Run Glue Job - S3 Preprocessing"
      },
      "Run Glue Job - S3 Preprocessing" = {
        Type     = "Task",
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "TransformationJob"
        },
        End = true
      }
    }
  })
}
