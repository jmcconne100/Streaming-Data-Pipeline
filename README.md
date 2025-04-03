# Streaming-Data-Pipeline

# Overview
- This project sets up a real-time streaming data pipeline on AWS using the following components:
- Amazon Kinesis Data Streams: Ingests real-time event data.
- AWS Lambda: Validates and filters incoming records from the stream.
- Amazon S3: Stores valid and invalid records under separate prefixes (raw/, unformatted/).
- AWS Glue Job: Processes JSON files and writes flattened Parquet files to S3.
- AWS Glue Crawler: Updates the Glue Data Catalog to enable Athena queries.
- AWS Step Functions + EventBridge: Orchestrates the Glue Job and Crawler to run hourly.
- Test Script: Simulates valid/invalid data flow into the Kinesis stream.

# Infrastructure
1. Infrastructure-2.txt
- Defines the following resources:
- S3 bucket jon-kinesis-data-lake
- Kinesis Data Stream
- Lambda function (jon-kinesis-stream-processor) that:
  - Validates if a record is valid JSON
  - Sends valid records to s3://.../raw/
  - Sends invalid records to s3://.../unformatted/
- Glue Job and Crawler sharing a single execution role
- Event source mapping for Kinesis → Lambda
- IAM roles for Lambda and Glue

2. Infrastructure-State-Machine.txt
Adds orchestration via:
- AWS Step Functions: Runs Glue Job and then the Crawler in sequence
- Amazon EventBridge: Schedules the state machine to run hourly
- IAM roles to allow state machine execution and triggering

# Data Ingestion
3. kinesis-test-script.sh
- Shell script to simulate test data streaming into the pipeline.

Usage:
```
chmod +x kinesis-test-script.sh
./kinesis-test-script.sh 10
```
- Takes a number as input for how many records to send.
- Each record has a 20% chance to be a malformed (non-JSON) payload.
- Introduces a random delay between records (1–5 seconds).
- Sends data to the configured Kinesis stream.

# ETL with Glue
4. jon-kinesis-glue-job-script.py
Python Glue script that:
- Reads all valid JSON data from s3://jon-kinesis-data-lake/raw/
- Flattens nested fields
- Writes the processed data as Parquet to:
```
s3://jon-kinesis-data-lake/parquet-output/
```
# Athena Querying
- The Glue Crawler automatically catalogs the schema of processed Parquet files under the Glue Database jon-kinesis-athena-db
- You can query your cleaned records via Amazon Athena once the crawler has run

# How It All Flows
```
Kinesis Stream
      ↓
   Lambda
  ↙       ↘
raw/     unformatted/
  ↓
(EventBridge — every hour)
            ↓
   Step Function Orchestration
      ↓              ↓
  Glue Job       Glue Crawler
      ↓              ↓
parquet-output/ → Glue Catalog → Athena
```

# Notes
- Be sure to replace any hardcoded bucket or stream names if copying this to your own AWS account.
- IAM permissions have been provisioned with broad * access — lock down for production.