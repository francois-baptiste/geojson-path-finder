import json
import pandas as pd
from google.cloud import bigquery

print('Upload geojson-path-finder network demo to Bigquery')

with open('gothenburg.json') as json_file:
    js = json_file.read()
    df = pd.DataFrame([['Gothenburg', js]])

df.columns = ['name', 'geojson']

bigquery.Client('data-science-229608').load_table_from_dataframe(df, 'routing_us.geojson_test_networks').result()
