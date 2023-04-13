#!/bin/bash       
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DOWNLOAD_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
INPUT_DIR=$SCRATCH/alphafold/input     # set the appropriate path to your supporting data
OUTPUT_DIR=${SCRATCH}/alphafold/output # set the appropriate path to your supporting data

source ~/alphafold_env/bin/activate

fasta_path=$1

run_alphafold.py \
   --data_dir=${DOWNLOAD_DIR} \
   --fasta_paths=$fasta_path \
   --db_preset='reduced_dbs' \
   --small_bfd_database_path=${DOWNLOAD_DIR}/small_bfd/bfd-first_non_consensus_sequences.fasta \
   --pdb70_database_path=${DOWNLOAD_DIR}/pdb70/pdb70 \
   --template_mmcif_dir=${DOWNLOAD_DIR}/pdb_mmcif/mmcif_files \
   --uniref90_database_path=${DOWNLOAD_DIR}/uniref90/uniref90.fasta  \
   --hhblits_binary_path=${EBROOTHHMINSUITE}/bin/hhblits \
   --hhsearch_binary_path=${EBROOTHHMINSUITE}/bin/hhsearch \
   --jackhmmer_binary_path=${EBROOTHMMER}/bin/jackhmmer \
   --kalign_binary_path=${EBROOTKALIGN}/bin/kalign \
   --mgnify_database_path=${DOWNLOAD_DIR}/mgnify/mgy_clusters_2018_12.fa \
   --output_dir=af2_out_reduced \
   --obsolete_pdbs_path=${DOWNLOAD_DIR}/pdb_mmcif/obsolete.dat \
   --max_template_date=2020-05-14 \
   --model_preset=multimer \
   --use_gpu_relax=True \
   --use_precomputed_msas=True