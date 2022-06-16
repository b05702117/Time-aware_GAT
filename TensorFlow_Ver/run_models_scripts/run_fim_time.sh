#!/bin/bash

for i in {01..13};
do
    python ../train.py --model_dir=../../experiments/fim/time_fold_${i} --data_dir=../../data/8_labels_time/len_01_cum_for/time_fold_${i} --device=0
done
python ../pred_folds.py --exp_dir=../../experiments/fim/ --label_dir=../../data/8_labels_time/len_01_cum_for/ --split_type=time --data_file=test_cum_for.gz --label_file=test_cum_for.gz
python ../synthesize_results.py --parent_dir=../../experiments/fim
