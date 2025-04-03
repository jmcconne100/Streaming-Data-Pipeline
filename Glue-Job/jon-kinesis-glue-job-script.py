import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, explode, lit

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# S3 paths
input_path = "s3://jon-kinesis-data-lake/raw/"
output_path = "s3://jon-kinesis-data-lake/parquet-output/"

# Load all JSON files in folder
df = spark.read.option("multiline", "true").json(input_path)

# Function to flatten nested fields
def flatten_df(nested_df):
    flat_cols = [c[0] for c in nested_df.dtypes if not c[1].startswith('struct') and not c[1].startswith('array')]
    nested_cols = [c[0] for c in nested_df.dtypes if c[1].startswith('struct') or c[1].startswith('array')]

    flat_df = nested_df.select(flat_cols + [col(n + "." + sub).alias(n + "_" + sub) 
                                             for n in nested_cols 
                                             for sub in nested_df.select(n + ".*").columns])
    return flat_df

# Apply flattening
flattened_df = flatten_df(df)

# Optional: Show schema
# flattened_df.printSchema()

# Write to Parquet
flattened_df.write.mode("overwrite").parquet(output_path)

job.commit()
