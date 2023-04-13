#!/bin/bash

module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DATA_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data

# Generate your virtual environment in $SLURM_TMPDIR
source ~/alphafold_env/bin/activate

### input targets
target_lst_file=$1
fea_dir=af2complex_out
out_dir=af2c_scores

echo "Info: input feature directory is $fea_dir"
echo "Info: result output directory is $out_dir"

af_dir=../src

cluster_edge_thres=10

python -u ../tools/run_interface_score.py \
  --target_lst_path=$target_lst_file \
  --output_dir=$out_dir \
  --feature_dir=$fea_dir \
  --do_cluster_analysis \
  --cluster_edge_thres=$cluster_edge_thres 