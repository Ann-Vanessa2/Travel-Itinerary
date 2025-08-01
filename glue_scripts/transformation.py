import sys
import logging
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import *
from pyspark.sql.utils import AnalysisException
from pyspark.sql.types import (
    StructType, StructField, LongType, StringType, TimestampType, 
    BooleanType, ShortType, IntegerType, DoubleType, DateType
)
import boto3
from urllib.parse import urlparse
from datetime import datetime

# Initialize boto3 S3 client
s3 = boto3.client('s3')

# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Job parameters
# database: travel_itinerary
# s3_output_bucket: travel-itinerary
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'SOURCE_DATABASE',
    'S3_OUTPUT_BUCKET',
    'DB_TABLES'
])

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Define schemas for all tables
schemas = {

    # USERS TABLE
    "users": StructType([
        StructField("id", LongType(), False),
        StructField("username", StringType(), False),
        StructField("email", StringType(), False),
        StructField("first_name", StringType(), True),
        StructField("last_name", StringType(), True),
        StructField("password", StringType(), True),
        StructField("profile_image_url", StringType(), True),
        StructField("profile_picture_key", StringType(), True),
        StructField("role", ShortType(), True),
        StructField("social_id", StringType(), True),
        StructField("social_provider", StringType(), True),
        StructField("is_enabled", BooleanType(), True),
        StructField("created_at", TimestampType(), True),
        StructField("updated_at", TimestampType(), True)
    ]),

    # VERIFICATION_TOKEN TABLE
    "verification_token": StructType([
        StructField("id", LongType(), False),
        StructField("created_at", TimestampType(), True),
        StructField("expiration", TimestampType(), True),
        StructField("verification_token", StringType(), False),
        StructField("token_type", StringType(), True),
        StructField("user_id", LongType(), False)
    ]),

    # USER_PERMISSIONS TABLE
    "user_permissions": StructType([
        StructField("user_id", LongType(), False),
        StructField("permissions", StringType(), False)
    ]),

    # PERMISSIONS_USER TABLE
    "permissions_user": StructType([
        StructField("user_id", LongType(), False),
        StructField("permission_id", LongType(), False)
    ]),

    # TRIP TABLE
    "trip": StructType([
        StructField("id", IntegerType(), False),
        StructField("title", StringType(), False),
        StructField("start_date", DateType(), False),
        StructField("end_date", DateType(), False),
        StructField("trip_status", StringType(), False),
        StructField("total_budget", DoubleType(), True),
        StructField("user_id", IntegerType(), False),
        StructField("number_of_travelers", IntegerType(), False),
        StructField("created_at", TimestampType(), True),
        StructField("updated_at", TimestampType(), True),
        StructField("last_modified_by", IntegerType(), True)
    ]),

    # DESTINATION TABLE
    "destination": StructType([
        StructField("id", IntegerType(), False),
        StructField("name", StringType(), False),
        StructField("description", StringType(), True),
        StructField("state", StringType(), True),
        StructField("country", StringType(), True),
        StructField("image_url", StringType(), True),
        StructField("geolocation_latitude", DoubleType(), True),
        StructField("geolocation_longitude", DoubleType(), True),
        StructField("geolocation_description", StringType(), True)
    ]),

    # ACTIVITY TABLE
    "activity": StructType([
        StructField("id", IntegerType(), False),
        StructField("name", StringType(), False),
        StructField("description", StringType(), True),
        StructField("address", StringType(), False),
        StructField("image_url", StringType(), True),
        StructField("source_website_url", StringType(), True),
        StructField("destination_id", IntegerType(), False),
        StructField("geolocation_latitude", DoubleType(), True),
        StructField("geolocation_longitude", DoubleType(), True),
        StructField("geolocation_description", StringType(), True),
        StructField("price_amount", DoubleType(), True),
        StructField("price_currency", StringType(), True),
        StructField("price_description", StringType(), True)
    ]),

    # TRIP_PARTICIPANTS TABLE
    "trip_participants": StructType([
        StructField("id", IntegerType(), False),
        StructField("trip_id", IntegerType(), False),
        StructField("user_id", IntegerType(), False),
        StructField("user_email", StringType(), True),
        StructField("role", StringType(), True),
        StructField("is_active", BooleanType(), True),
        StructField("joined_at", TimestampType(), True)
    ]),

    # TRIP_INVITATIONS TABLE
    "trip_invitations": StructType([
        StructField("id", IntegerType(), False),
        StructField("trip_id", IntegerType(), False),
        StructField("inviter_id", IntegerType(), False),
        StructField("invitee_email", StringType(), False),
        StructField("invitation_token", StringType(), False),
        StructField("status", StringType(), False),
        StructField("trip_title", StringType(), True),
        StructField("inviter_name", StringType(), True),
        StructField("created_at", TimestampType(), True),
        StructField("expires_at", TimestampType(), True)
    ]),

    # EXPENSES TABLE
    "expenses": StructType([
        StructField("id", IntegerType(), False),
        StructField("amount", DoubleType(), False),
        StructField("activity_id", IntegerType(), True),
        StructField("activity_name", StringType(), True),
        StructField("description", StringType(), True),
        StructField("date", DateType(), False),
        StructField("trip_id", IntegerType(), True)
    ]),

    # ITINERARIES TABLE
    "itineraries": StructType([
        StructField("id", IntegerType(), False),
        StructField("trip_id", IntegerType(), False)
    ]),

    # ITINERARY_ITEM TABLE
    "itinerary_item": StructType([
        StructField("id", IntegerType(), False),
        StructField("itinerary_id", IntegerType(), False),
        StructField("scheduled_time", TimestampType(), False),
        StructField("activity_id", IntegerType(), True),
        StructField("destination_id", IntegerType(), True),
        StructField("notes", StringType(), True),
        StructField("reminder_time", TimestampType(), True),
        StructField("display_order", IntegerType(), True)
    ]),

    # CATEGORY TABLE
    "category": StructType([
        StructField("id", IntegerType(), False),
        StructField("name", StringType(), False),
        StructField("description", StringType(), True)
    ]),

    # REVIEW TABLE
    "review": StructType([
        StructField("id", IntegerType(), False),
        StructField("activity_id", IntegerType(), False),
        StructField("rating", IntegerType(), True),
        StructField("comment", StringType(), True),
        StructField("reviewer_name", StringType(), True),
        StructField("created_at", TimestampType(), True)
    ]),

    # TRIP_DESTINATIONS TABLE (Join Table)
    "trip_destinations": StructType([
        StructField("trip_id", IntegerType(), False),
        StructField("destination_id", IntegerType(), False)
    ]),

    # ACTIVITY_CATEGORY TABLE (Join Table)
    "activity_category": StructType([
        StructField("activity_id", IntegerType(), False),
        StructField("category_id", IntegerType(), False)
    ]),

    # ACTIVITY_TRAVEL_STYLES TABLE
    "activity_travel_styles": StructType([
        StructField("activity_id", IntegerType(), False),
        StructField("travel_style", StringType(), False)
    ]),

    # EXPENSE_PAID_BY TABLE (Join Table)
    "expense_paid_by": StructType([
        StructField("expense_id", IntegerType(), False),
        StructField("user_id", StringType(), True)
    ])

}

# Tables to extract (passed as comma-separated list)
tables = args['DB_TABLES'].split(',')

# Tables to delete from source S3 before writing to silver
tables_to_delete = {
    "verification_token", "user_permissions", "permissions_user",
    "trip_participants", "trip_invitations", "itineraries",
    "itinerary_item", "review", "activity_category",
    "activity_travel_styles", "expense_paid_by"
}

# # Loop through and process each table
# for table_name in tables:
#     try:
#         logger.info(f"Processing table: {table_name}")

#         # Load from catalog
#         dyf = glueContext.create_dynamic_frame.from_catalog(
#             database=args['SOURCE_DATABASE'], # travel_itinerary
#             table_name=table_name
#         )

#         # Convert to DataFrame for validation
#         df = dyf.toDF()
#         schema = schemas[table_name]

#         # Enforce schema
#         validated_df = spark.createDataFrame(df.rdd, schema=schema)

#         # Write to curated S3
#         target_path = f"s3://{args['S3_OUTPUT_BUCKET']}/silver/{table_name}/"
#         validated_df.write.mode("overwrite").parquet(target_path)

#         logger.info(f"Successfully processed {table_name} to {target_path}")

#     except AnalysisException as ae:
#         logger.error(f"AnalysisException while processing {table_name}: {str(ae)}", exc_info=True)
#     except Exception as e:
#         logger.error(f"Unexpected error while processing {table_name}: {str(e)}", exc_info=True)

# # Finalize job
# job.commit()
# logger.info("Glue job completed successfully.")


##########################

# Generate current timestamp in format: YYYY-MM-DD_HH-MM-SS
timestamp = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")

# Loop through and process each table
for table_name in tables:
    try:
        logger.info(f"Processing table: {table_name}")

        # Load from catalog
        dyf = glueContext.create_dynamic_frame.from_catalog(
            database=args['SOURCE_DATABASE'],
            table_name=table_name
        )

        # Convert to DataFrame for validation
        df = dyf.toDF()
        schema = schemas[table_name]

        # Enforce schema
        validated_df = spark.createDataFrame(df.rdd, schema=schema)

        # DELETE SOURCE FILES before writing to curated S3
        if table_name in tables_to_delete:
            # Get S3 source path from Glue Catalog metadata
            source_path = dyf.glue_ctx.catalog_client.get_table(
                DatabaseName=args['SOURCE_DATABASE'], # travel_itinerary
                Name=table_name
            )['StorageDescriptor']['Location']

            parsed = urlparse(source_path)
            bucket = parsed.netloc
            prefix = parsed.path.lstrip('/')

            logger.info(f"Deleting source files for table {table_name} from s3://{bucket}/{prefix}")

            # List and delete all objects under prefix
            objects_to_delete = s3.list_objects_v2(Bucket=bucket, Prefix=prefix).get('Contents', [])
            if objects_to_delete:
                delete_batch = [{'Key': obj['Key']} for obj in objects_to_delete]
                s3.delete_objects(Bucket=bucket, Delete={'Objects': delete_batch})
                logger.info(f"Deleted {len(delete_batch)} objects for table {table_name}")
            else:
                logger.warning(f"No objects found for deletion for table {table_name}")

        # Write to curated S3 (silver layer)
        target_path = f"s3://{args['S3_OUTPUT_BUCKET']}/silver/{timestamp}/{table_name}/"
        validated_df.write.mode("overwrite").parquet(target_path)

        logger.info(f"Successfully processed {table_name} to {target_path}")

    except AnalysisException as ae:
        logger.error(f"AnalysisException while processing {table_name}: {str(ae)}", exc_info=True)
    except Exception as e:
        logger.error(f"Unexpected error while processing {table_name}: {str(e)}", exc_info=True)

# Finalize job
job.commit()
logger.info("Glue job completed successfully.")
