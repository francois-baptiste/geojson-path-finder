import json
import pandas as pd
from google.cloud import bigquery
import argparse

parser = argparse.ArgumentParser(description='Import geojson network file to Big Query.')
parser.add_argument('--file-path', required=True, help='The GeoJson File to import.')
parser.add_argument('--project-id', required=True, help='Google Cloud Project Id.')
parser.add_argument('--dataset', required=True, help='Google Cloud Big Query data set.')
parser.add_argument('--table-name', required=True, help='Big Query table name.')

args = parser.parse_args()

if __name__ == '__main__':
    print('Upload geojson-path-finder network demo to Bigquery')
    data = []
    with open('gothenburg.json') as json_file:
        for v in json.load(json_file)['features']:
          data.append([json.dumps(i) for i in v.values()])

    df = pd.DataFrame(data)

    df.columns = ['type', 'id', 'properties', 'geometry']

    client = bigquery.Client(args.project_id)
    client.load_table_from_dataframe(df, f'{args.dataset}.{args.table_name}').result()
