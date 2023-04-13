#!/bin/bash

#SBATCH --job-name=alphafold_run
#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=04:00:00           # adjust this to match the walltime of your job
#SBATCH --gres=gpu:1              # a GPU helps to accelerate the inference part only
#SBATCH --cpus-per-task=8         # a MAXIMUM of 8 core, Alpafold has no benefit to use more
#SBATCH --mem=20G                 # adjust this according to the memory you need
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8

DOWNLOAD_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
INPUT_DIR=$SCRATCH/alphafold/input     # set the appropriate path to your supporting data
OUTPUT_DIR=${SCRATCH}/alphafold/output # set the appropriate path to your supporting data

# Generate your virtual environment in $SLURM_TMPDIR
virtualenv --no-download ${SLURM_TMPDIR}/env
source ${SLURM_TMPDIR}/env/bin/activate

# Install alphafold and its dependencies
pip install --no-index --upgrade pip
pip install --no-index --requirement ~/af2complex-requirements.txt
#Run example script
/home/zakhar/projects/def-bfinlay/zakhar/af2_complex/af2complex-main/example/example1_mod.sh
