output "s3_bucket_name" {
  value = aws_s3_bucket.bronze_silver.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "redshift_endpoint" {
  value = aws_redshift_cluster.travel_warehouse.endpoint
}