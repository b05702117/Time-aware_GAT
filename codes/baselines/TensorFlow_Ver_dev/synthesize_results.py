"""Aggregates results from the metrics_eval_best_weights.json in a parent folder"""

import argparse
import json
import os
import numpy as np
import pandas as pd

from tabulate import tabulate

parser = argparse.ArgumentParser()
parser.add_argument('--parent_dir', default='experiments',
                    help='Directory containing results of experiments')
parser.add_argument('--file_type', default='test',
                    help='Directory containing results of experiments')

def aggregate_metrics(parent_dir, file_type, metrics):
    """Aggregate the metrics of all experiments in folder `parent_dir`.

    Assumes that `parent_dir` contains multiple experiments, with their results stored in
    `parent_dir/subdir/metrics_dev.json`

    Args:
        parent_dir: (string) path to directory containing experiments results
        metrics: (dict) subdir -> {'accuracy': ..., ...}
    """
    # Get the metrics for the folder if it has results from an experiment
    metrics_file_name = '{}_metrics_pred_best_weights.json'.format(file_type)
    metrics_file = os.path.join(parent_dir, metrics_file_name)
    if os.path.isfile(metrics_file):
        with open(metrics_file, 'r') as f:
            metrics[parent_dir] = json.load(f)

    # Check every subdirectory of parent_dir
    for subdir in os.listdir(parent_dir):
        if not os.path.isdir(os.path.join(parent_dir, subdir)):
            continue
        else:
            aggregate_metrics(os.path.join(parent_dir, subdir), file_type, metrics)


def metrics_to_table(metrics):
    # Get the headers from the first subdir. Assumes everything has the same metrics
    headers = metrics[list(metrics.keys())[0]].keys()
    table = [[subdir] + [values[h] for h in headers] for subdir, values in metrics.items()]
    res = tabulate(table, headers, tablefmt='pipe')

    return res


if __name__ == "__main__":
    args = parser.parse_args()

    # Aggregate metrics from args.parent_dir directory
    metrics = dict()
    aggregate_metrics(args.parent_dir, args.file_type, metrics)
    table = metrics_to_table(metrics)

    all_results = []
    for key, value in metrics.items():
        column_names = value.keys()
        results = np.fromiter(value.values(), dtype=float)
        all_results.append(results)

    all_results = pd.DataFrame(all_results, columns=column_names)
    all_results.loc['average'] = all_results.mean(axis=0)
    all_results.transpose().to_csv(args.parent_dir+'/results_tf.csv')
    print(all_results.transpose())

    # Display the table to terminal
    # print(table)

    # Save results in parent_dir/results.md
    #save_file = os.path.join(args.parent_dir, "{}_results.md".format(args.file_type))
    #with open(save_file, 'w') as f:
    #    f.write(table)
