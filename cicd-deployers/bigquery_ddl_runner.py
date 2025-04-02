# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import collections
from google.cloud import bigquery
from google.cloud import storage
import sys

def run_sql_queries_from_gcs(project_id, location, bucket, ddl_project_id, ddl_dataset_id, ddl_data_bucket_name,
                             ddl_connection_name):
    """Searches for SQL files in a GCS bucket and runs them in BigQuery.

    Args:
        bucket_name (str): Name of the GCS bucket.
        project_id (str): Google Cloud project ID.
    """
    bigquery_client = bigquery.Client(project=project_id)
    storage_client = storage.Client(project=project_id)

    bucket = storage_client.get_bucket(bucket)
    blobs = bucket.list_blobs(prefix="", delimiter="/")

    for blob in blobs:
        if blob.name.endswith(".sql"):

            file_content = blob.download_as_string().decode("utf-8")

            # Replace variables
            updated_query = replace_variables_in_query(file_content, ddl_project_id, ddl_dataset_id,
                                                       ddl_data_bucket_name, ddl_connection_name)
            # Create a query job configuration
            job_config = bigquery.QueryJobConfig()

            # Run the SQL query in BigQuery
            query_job = bigquery_client.query(updated_query, job_config=job_config)

            # Wait for the query job to complete and print results
            results = query_job.result()
            for row in results:
                print(row)


def replace_variables_in_query(file_content, project_id, dataset_id, data_bucket_name, connection_name):
    """Replaces variables in a BigQuery query string.

    Args:
        file_content (str): The content of the query file.
        project_id (str): Google Cloud project ID.
        dataset_id (str): BigQuery dataset ID.
        data_bucket_name (str): Name of the GCS bucket.
        connection_name (str): Name of the BigQuery connection.

    Returns:
        str: The updated query string with replaced variables.
    """
    updated_query = file_content.replace("${PROJECT_ID}", project_id) \
        .replace("${DATASET_ID}", dataset_id) \
        .replace("${DATA_BUCKET_NAME}", data_bucket_name) \
        .replace("${CONNECTION_NAME}", connection_name)
    return updated_query


def main(args: collections.abc.Sequence[str]) -> int:
    """The main function parses command-line arguments and calls the run_workflow function to execute the complete Dataform workflow.
    To run the script, provide the required command-line arguments:
        python intro.py --project_id your_project_id --location your_location --repository your_repo_name --dataset your_bq_dataset --branch your_branch
    """
    parser = argparse.ArgumentParser(description="BigQuery DDLs defined in files in a GCS bucket runner")
    parser.add_argument("--project_id",
                        type=str,
                        required=True,
                        help="The GCP project ID where the BigQuery client and storage client will be created.")
    parser.add_argument("--location",
                        type=str,
                        required=True,
                        help="The location of the BigQuery client and storage client")
    parser.add_argument("--bucket",
                        type=str,
                        required=True,
                        help="The bucket where there are DLL files to run")
    parser.add_argument("--ddl_project_id",
                        type=str,
                        required=True,
                        help="The project ID that will be replaced. It should be defined in the .sql file like: {$PROJECT_ID}")
    parser.add_argument("--ddl_dataset_id",
                        type=str,
                        required=True,
                        help="The dataset ID that will be replaced. It should be defined in the .sql file like: {$DATASET_ID}")
    parser.add_argument("--ddl_data_bucket_name",
                        type=str,
                        required=True,
                        help="The bucket name that will be replaced. It should be defined in the .sql file like: {DATA_BUCKET_NAME}")
    parser.add_argument("--ddl_connection_name",
                        type=str,
                        required=True,
                        help="The BigLake connection name that will be replaced. It should be defined in the .sql file like: {CONNECTION_NAME}")

    params = parser.parse_args(args)
    project_id = str(params.project_id)
    location = str(params.location)
    bucket = str(params.bucket)
    ddl_project_id = str(params.ddl_project_id)
    ddl_dataset_id = str(params.ddl_dataset_id)
    ddl_data_bucket_name = str(params.ddl_data_bucket_name)
    ddl_connection_name = str(params.ddl_connection_name)

    run_sql_queries_from_gcs(project_id=project_id, location=location, bucket=bucket, ddl_project_id=ddl_project_id,
                             ddl_dataset_id=ddl_dataset_id, ddl_data_bucket_name=ddl_data_bucket_name,
                             ddl_connection_name=ddl_connection_name)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
