#On cedar cluster manipulate the intact object to get the interactions I want
#do all this in af2complex-main/analysis folder
#Turn this into a bash script for ease of download for time
nano helper_bash_scripts/download_intact.sh
	#!/bin/bash
	#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
	#SBATCH --time=08:00:00           # adjust this to match the walltime of your job
	wget ftp.ebi.ac.uk/pub/databases/intact/current/psimitab/intact.txt -O intact/intact_whole.txt

salloc --time=3:0:0 --ntasks=16 --mem-per-cpu=30G --account=def-bfinlay
#The code is in "extracting APEX hits from intact.r" file


