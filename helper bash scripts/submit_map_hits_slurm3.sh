#!/bin/bash
#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=8:00:00           # adjust this to match the walltime of your job
#SBATCH --gres=gpu:1              # a GPU helps to accelerate the inference part only
#SBATCH --cpus-per-task=8         # a MAXIMUM of 8 core, Alpafold has no benefit to use more
#SBATCH --mem=30G                 # adjust this according to the memory you need
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DOWNLOAD_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
declare -a name_array=('EEF1A1'	'TUBA1B' 'TRAP1')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	./feature_gen.sh map_fastas/${name_array[$i]}.fasta
done