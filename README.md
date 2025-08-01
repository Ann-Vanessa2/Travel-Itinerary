# Travel Itinerary ETL Pipeline Documentation
## Overview
This project implements a batch-based ETL pipeline for processing travel itinerary data. The pipeline utilizes Amazon RDS (PostgreSQL) as the source, and processes data through AWS Glue, storing outputs in S3 buckets and a structured schema in Amazon Redshift. The pipeline is orchestrated using AWS Step Functions, and schemas are cataloged with AWS Glue Crawlers.

## Architecture Overview

### 1. Data Format and Sample Schema
Source: `Amazon RDS (PostgreSQL)`
Database Name: `travel_itinerary`

Destination: Amazon S3 (Bronze & Silver)
Bronze Bucket (Raw Data)
Silver Bucket (Cleaned Data)

### 2. Validation and Transformation Rules
Bronze Layer (Glue Job 1 - Extract & Load):
- Extracts all tables from RDS using JDBC connection
- Converts to CSV
- Stores raw data in respective bronze/ folders in S3

Silver Layer (Glue Job 2 - Clean & Curate):
- Drops duplicates and NULLs
- Applies column normalization
- Stores cleaned data in silver/ folders in S3

Redshift Presentation Layer:
- Creates star schema tables in Redshift
- Loads data into Redshift star schema

- Target schema includes:
dim_user, dim_trip, fact_booking, among others

### 3. Glue Crawlers & Data Catalog
Bronze Crawler
- Crawls raw CSV data in bronze/
- Creates tables in travel_itinerary_raw database

### 4. Step Function Workflow Explanation
State Machine Flow:
IngestToS3Job (Glue Job 1):
- Connects to RDS via JDBC
- Extracts data and stores in bronze/ bucket

RunBronzeCrawler:
Updates AWS Glue Catalog with raw data schema

TransformationJob (Glue Job 2):
Processes raw data from bronze to silver layer

Success/Failure Branches:
Failure paths log errors to CloudWatch
Success triggers notifications or audit logs