# /bin/bash

# TODO: make the ROOT to relative path
ROOT='/tmp2/ybtu/codes.credit.relation/codes/NeuDP_GAT'
# cd $ROOT
DATA_ROOT='/home/cwlin/explainable_credit/data'

# MODEL_NAME=NeuDP_GAT_wo_intra # NeuDP_GAT, NeuDP_GAT_wo_intra, NeuDP_GAT_wo_inter
# MODEL_NAME=NeuDP_GAT_wo_inter
WINDOW_SIZE=12
FEATURE_SIZE=14
CUM_LABELS=8

# Fixed parameters
device=$1
experiment_type=$2 # index time expand_len expand_time(for inference only)
cluster_setting=$3 # industry 
n_cluster=$4 # 14
lstm_num_units=$5
intra_gat_hidn_dim=$6
inter_gat_hidn_dim=$7
learning_rate=$8
weight_decay=$9
MODEL_NAME=${10} # NeuDP_GAT, NeuDP_GAT_wo_intra, NeuDP_GAT_wo_inter
# fold_start=${10}
# fold_end=${11}
max_epoch=100
patience=20
gamma=0.9
batch_size=1

## directory setting
edge_file_dir=$DATA_ROOT/edge_file 
all_company_ids_path=$DATA_ROOT/edge_file/all_company_ids.csv

output_file=$ROOT/experiments/${experiment_type}/${experiment_type}.csv
echo $output_file

fold_range=(20 15 10 05 01)
# fold_range=(20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1)
# fold_range=(20)
# for fold in $(seq $fold_end -1 $fold_start); do
for fold in "${fold_range[@]}"; do
    fold=$(printf "%02d" $fold)

    data_dir=$DATA_ROOT
    if [ "$experiment_type" == "index" ]; then
        data_dir=${data_dir}/index/index_fold_${fold}
    elif [ "$experiment_type" == "time" ]; then
        data_dir=${data_dir}/expand_no_overtime/time_fold_${fold}
    elif [ "$experiment_type" == "expand_len" ]; then
        data_dir=${data_dir}/expand_len/time_fold_${fold}
    else
        echo "Invalid experiment_type provided!"
        exit 1
    fi

    # setup model directory
    run_id="lstm${lstm_num_units}_intra${intra_gat_hidn_dim}_inter${inter_gat_hidn_dim}_lr${learning_rate}_wd${weight_decay}"
    model_dir=$ROOT/experiments/${experiment_type}/${cluster_setting}_${n_cluster}/fold_${fold}/${MODEL_NAME}_${WINDOW_SIZE}_${experiment_type}_${run_id}

    # directory of last_weights has to be made first
    mkdir -p $model_dir/last_weights &&
    echo made $model_dir
done

# # for fold in $(seq $fold_end -1 $fold_start); do
for fold in "${fold_range[@]}"; do
    fold=$(printf "%02d" $fold)

    data_dir=$DATA_ROOT
    if [ "$experiment_type" == "index" ]; then
        data_dir=${data_dir}/index/index_fold_${fold}
    elif [ "$experiment_type" == "time" ]; then
        data_dir=${data_dir}/expand_no_overtime/time_fold_${fold}
    elif [ "$experiment_type" == "expand_len" ]; then
        data_dir=${data_dir}/expand_len/time_fold_${fold}
    else
        echo "Invalid experiment_type provided!"
        exit 1
    fi

    # setup model directory
    run_id="lstm${lstm_num_units}_intra${intra_gat_hidn_dim}_inter${inter_gat_hidn_dim}_lr${learning_rate}_wd${weight_decay}"
    model_dir=$ROOT/experiments/${experiment_type}/${cluster_setting}_${n_cluster}/fold_${fold}/${MODEL_NAME}_${WINDOW_SIZE}_${experiment_type}_${run_id}

    if [ -f "$model_dir/AR" ] && [ -f "$model_dir/RMSNE" ] && [ -f "$model_dir/num_epochs" ]; then
        echo "AR, RMSNE, and num_epochs already exist. Skipping experiment."
    else
        bash run_GAT_02.sh $model_dir $data_dir $edge_file_dir $all_company_ids_path \
                        $device $experiment_type $cluster_setting $n_cluster $fold \
                        $lstm_num_units $intra_gat_hidn_dim $inter_gat_hidn_dim \
                        $learning_rate $weight_decay $max_epoch $patience $gamma $batch_size \
                        $MODEL_NAME $WINDOW_SIZE $FEATURE_SIZE $CUM_LABELS&&

        # Extract last 8 lines of AR and RMSNE (adjust the file paths if necessary)
        AR=($(tail -n 8 $model_dir/AR)) &&
        RMSNE=($(tail -n 8 $model_dir/RMSNE)) && 
        num_epochs=$(tail -n 1 $model_dir/num_epochs) &&

        # Compute average AR
        sum_ar=0
        for ar in "${AR[@]}"; do
            sum_ar=$(echo "$sum_ar + $ar" | bc)
        done
        avg_ar=$(echo "scale=4; $sum_ar / ${#AR[@]}" | bc)

        # Compute average RMSNE
        sum_rmsne=0
        for rmsne in "${RMSNE[@]}"; do
            sum_rmsne=$(echo "$sum_rmsne + $rmsne" | bc)
        done
        avg_rmsne=$(echo "scale=4; $sum_rmsne / ${#RMSNE[@]}" | bc)

        # header: experiment_type,cluster_setting,n_cluster,fold,inter,intra,epoch,lstm,lr,wd,AR_01,AR_02,AR_03,AR_04,AR_05,AR_06,AR_07,AR_08,Avg_AR,RMSNE_01,RMSNE_02,RMSNE_03,RMSNE_04,RMSNE_05,RMSNE_06,RMSNE_07,RMSNE_08,Avg_RMSNE
        echo "$experiment_type,$cluster_setting,$n_cluster,$fold,$inter_gat_hidn_dim,$intra_gat_hidn_dim,$num_epochs,$lstm_num_units,$learning_rate,$weight_decay,${AR[0]},${AR[1]},${AR[2]},${AR[3]},${AR[4]},${AR[5]},${AR[6]},${AR[7]},$avg_ar,${RMSNE[0]},${RMSNE[1]},${RMSNE[2]},${RMSNE[3]},${RMSNE[4]},${RMSNE[5]},${RMSNE[6]},${RMSNE[7]},$avg_rmsne" >> $output_file
    fi
done
