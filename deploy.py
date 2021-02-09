import os
from google.cloud import bigquery
from google.cloud.exceptions import NotFound
from google.cloud import storage
from envsubst import envsubst


PROJECT_ID = os.environ["PROJECT_ID"]
DATASET = os.environ["DATASET"]
LOCATION = os.environ["LOCATION"]
BUCKET_NAME = os.environ["LIBRARY_BUCKET_NAME"]


def deploy_file_to_gcp():
    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob('geojson_path_finder.js')

    blob.upload_from_filename(filename="dist/geojson_path_finder.js")


def parse_query():
    with open('query_template.sql', 'r') as inn:
        parsed_query = envsubst(inn.read())
        return parsed_query


def deploy():
    query = parse_query()
    
    client = bigquery.Client(project=PROJECT_ID, location=LOCATION)
    query_job = client.query(query)
    results = query_job.result()  # Waits for job to complete.


if __name__ == "__main__":
    deploy_file_to_gcp()
    deploy()