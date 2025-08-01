import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from datetime import datetime

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'RDS_ENDPOINT',
    'RDS_PORT',
    'RDS_DB_NAME',
    'RDS_USERNAME',
    'RDS_PASSWORD',
    'S3_OUTPUT_BUCKET',
    'TABLES_TO_EXTRACT'
])

# Database connection details
jdbc_url = f"jdbc:postgresql://{args['RDS_ENDPOINT']}:{args['RDS_PORT']}/{args['RDS_DB_NAME']}"
# jdbc_url = f"jdbc:postgresql://travel-itinerary-2.c7gckm02k895.eu-west-1.rds.amazonaws.com:5432/travel_itinerary"
connection_properties = {
    "user": args['RDS_USERNAME'],
    "password": args['RDS_PASSWORD'],
    "driver": "org.postgresql.Driver"
}

# S3 output path
s3_output_bucket = args['S3_OUTPUT_BUCKET']

# Tables to extract (passed as comma-separated list)
tables = args['TABLES_TO_EXTRACT'].split(',')

# Generate current timestamp in format: YYYY-MM-DD_HH-MM-SS
timestamp = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")

# Process each table
for table in tables:
    print(f"Extracting table: {table}")
    
    # Read data from RDS
    df = glueContext.read.format("jdbc").option("url", jdbc_url) \
        .option("dbtable", table) \
        .option("user", connection_properties["user"]) \
        .option("password", connection_properties["password"]) \
        .load()
    
    # Write to S3 in Parquet format (you can change to CSV or other formats)
    output_path = f"s3://{s3_output_bucket}/bronze/{timestamp}/{table}/"
    # output_path = f"s3://{s3_output_bucket}/bronze/{table}/"
    df.write.mode("overwrite").parquet(output_path)
    
    print(f"Successfully exported {table} to {output_path}")

job.commit()