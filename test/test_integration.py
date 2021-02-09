import os
from google.cloud import bigquery
from google.cloud.exceptions import NotFound

PROJECT_ID = os.environ["PROJECT_ID"]
DATASET = os.environ["DATASET"]
LOCATION = os.environ["LOCATION"]

print(os.environ)

def test_if_dataset_exists():
    client = bigquery.Client()
    client.get_dataset(f"{PROJECT_ID}.{DATASET}")


def test_dataset_location():
    client = bigquery.Client()
    ds = client.get_dataset(f"{PROJECT_ID}.{DATASET}")

    assert ds.location == LOCATION
