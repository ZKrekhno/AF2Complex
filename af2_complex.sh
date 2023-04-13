#Attempting to run AF2-complex for map and its potential interactors from APEX dataset
#https://github.com/FreshAirTonight/af2complex
#Date: Jan 8, 20223
#Author: Zakhar Krkehno
#Work on the MSL Raptor server
#Install alpha fold on the cedar server
#Follow these instructions to install alpha fold - https://docs.alliancecan.ca/wiki/AlphaFold
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
virtualenv --no-download ~/alphafold_env
#This is to get into this environment
source ~/alphafold_env/bin/activate
#In the environment
pip install --no-index --upgrade pip
pip install --no-index alphafold==2.2.2
#Validate
run_alphafold.py --help
#Freeze
pip freeze > ~/alphafold-requirements.txt
#Set up download of DBs
export DOWNLOAD_DIR=$SCRATCH/alphafold/data
mkdir -p $DOWNLOAD_DIR
screen -S download
download_all_data.sh $DOWNLOAD_DIR
download_small_bfd.sh $DOWNLOAD_DIR
#This screen is happening at cedar1-login node 
ssh cedar1 #if not on cedar1-login node
tree -d $DOWNLOAD_DIR
#Now on to clone AF2complex - none of the options below worked, so had to manually download the zip repo from Github and put it on compute canada
git clone https://github.com/FreshAirTonight/af2complex.git
wget https://github.com/FreshAirTonight/af2complex/archive/refs/heads/main.zip
#Had to install module networkx
pip install networkx
#Freeze
pip freeze > ~/af2complex-requirements.txt
#Run an example script of simple af2-complex
nano af2-gpu-notmpdir.sh
#!/bin/bash
#SBATCH --job-name=alphafold_run
#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=08:00:00           # adjust this to match the walltime of your job
#SBATCH --gres=gpu:1              # a GPU helps to accelerate the inference part only
#SBATCH --cpus-per-task=8         # a MAXIMUM of 8 core, Alpafold has no benefit to use more
#SBATCH --mem=20G                 # adjust this according to the memory you need
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DOWNLOAD_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
INPUT_DIR=$SCRATCH/alphafold/input     # set the appropriate path to your supporting data
OUTPUT_DIR=${SCRATCH}/alphafold/output # set the appropriate path to your supporting data
# Generate your virtual environment in $SLURM_TMPDIR
source ~/alphafold_env/bin/activate
#Run example script
/home/zakhar/projects/def-bfinlay/zakhar/af2_complex/af2complex-main/example/example1_mod.sh

#Next step is test whether this tool works well for predicting interactions
#First test on interactions between map and its chaperone cesT
#Download fasta sequences for map and cesT
#These are used as positive controls for interaction - if their scores are high, it might be worth proceeding
#Link to the paper:
#https://onlinelibrary.wiley.com/doi/10.1046/j.1365-2958.2003.03290.x
#This is done in af2complex-main/analysis directory
wget https://rest.uniprot.org/uniprotkb/B7UMA0.fasta -O map.fasta
wget https://rest.uniprot.org/uniprotkb/P21244.fasta -O cesT.fasta
#Run feature generation on map
#Create the feature generation script
nano map_feature.sh
sbatch map_feature.sh map.fasta
#Create feature generation script with reduced dbs instead of full
nano feat_reduced.sh
#Create feature generation script without call to sbatch

nano feature_gen.sh


sbatch feat_reduced.sh map.fasta
sbatch feat_reduced.sh cesT.fasta

#Make target list
echo "##Target(components) Size(AAs) Name(for output)" > map_cest.lst
echo "map/cest 359 map_cesT" >> map_cest.lst

#Create map-cesT af2-complex script
nano map_cest.sh
sbatch map_cest.sh map_cest.lst map_cest
#This worked alright
#Now create a script for af2complex generation with better presets (more recycling and such)

nano af2comp_super.sh
#Get the list of map hits from APEX and run them through the feature generation pipeline

#Quickly download sequences for potential map hits
nano download_map_hits.sh
#!/bin/bash
#Make arrays for ids and names
declare -a id_array=('P04181'	'P07437'	'P10515'	'P10809'	'P24752'	'P30048'	'P36957'	'P38646'	'P42704'	'P45880'	'P49411'	'P68104'	'P68363'	'Q12931'	'Q6UB35'	'Q9NSE4'	'Q9NVI7'	'Q9Y2Z4')
declare -a name_array=('OAT'	'TUBB'	'DLAT'	'HSPD1'	'ACAT1'	'PRDX3'	'DLST'	'HSPA9'	'LRPPRC'	'VDAC2'	'TUFM'	'EEF1A1'	'TUBA1B'	'TRAP1'	'MTHFD1L'	'IARS2'	'ATAD3A'	'YARS2')
#Iterate over the arrays and download sequences
for (( i=0; i<${#id_array[@]}; i++ ));
do
	wget https://rest.uniprot.org/uniprotkb/${id_array[$i]}.fasta -O map_fastas/${name_array[$i]}.fasta
done
#Next run alphafold on all the human hits
nano map_hits_afold_feat_gen.sh
#!/bin/bash
#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=15:00:00           # adjust this to match the walltime of your job
#SBATCH --gres=gpu:1              # a GPU helps to accelerate the inference part only
#SBATCH --cpus-per-task=8         # a MAXIMUM of 8 core, Alpafold has no benefit to use more
#SBATCH --mem=30G                 # adjust this according to the memory you need
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DOWNLOAD_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
INPUT_DIR=$SCRATCH/alphafold/input     # set the appropriate path to your supporting data
OUTPUT_DIR=${SCRATCH}/alphafold/output # set the appropriate path to your supporting data

source ~/alphafold_env/bin/activate
declare -a name_array=('OAT'	'TUBB'	'DLAT'	'HSPD1'	'ACAT1'	'PRDX3'	'DLST'	'HSPA9'	'LRPPRC'	'VDAC2'	'TUFM'	'EEF1A1'	'TUBA1B'	'TRAP1'	'MTHFD1L'	'IARS2'	'ATAD3A'	'YARS2')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	./feature_gen.sh map_fastas/${name_array[$i]}.fasta
done
#THis was taking too long, so stop after DLAT is complete, stop and re-submit four different jobs
#re-submit four different jobs (break down hits in 4)
nano submit_map_hits_slurm1.sh
nano submit_map_hits_slurm2.sh
nano submit_map_hits_slurm3.sh
nano submit_map_hits_slurm4.sh
#next prepare target list for af2complex - 
#did that in excel separately and uploaded to the server.
#Finally, submit the script for running map and partners
sbatch af2comp_super.sh map_hits.lst af2_out_reduced
#This is running too slow, break down the hits list and re-submit
#Will have to re-run HSPD1 separately tomorrow
sbatch af2comp_super.sh map_hits1.lst af2_out_reduced
sbatch af2comp_super_more_ram.sh map_hits2.lst af2_out_reduced
sbatch af2comp_super.sh map_hits3.lst af2_out_reduced
sbatch af2comp_super.sh map_hits4.lst af2_out_reduced
sbatch af2comp_super.sh map_hits5.lst af2_out_reduced
sbatch af2comp_super_more_ram.sh map_hits6.lst af2_out_reduced

#Create quick dummy folders with good names and copy just the ranking all model json files there
mkidr af2complex_jsons
nano move_jsons.sh
#!/bin/bash
declare -a name_array=('OAT'	'TUBB'	'DLAT'	'HSPD1'	'ACAT1'	'PRDX3'	'DLST'	'HSPA9'	'LRPPRC'	'VDAC2'	'TUFM'	'EEF1A1'	'TUBA1B'	'TRAP1'	'MTHFD1L'	'IARS2'	'ATAD3A'	'YARS2')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	mkdir af2complex_jsons/map_${name_array[$i]}
	cp map_${name_array[$i]}/ranking_all* af2complex_jsons/map_${name_array[$i]}/
done
#Last step is to evaluate the interface scores - do that in R
#All hit scores of 0, check and see if NHERF2 can be modelled
wget https://rest.uniprot.org/uniprotkb/Q15599.fasta -O map_fastas/NHERF2.fasta
#Generate features
sbatch feat_reduced.sh map_fastas/NHERF2.fasta
#Make target list for map_NHERF2
echo "##Target(components) Size(AAs) Name(for output)" > map_NHERF2.lst
echo "map/NHERF2 540 map_with_MTS_NHERF2" >> map_NHERF2.lst
echo "map|45-203:1/NHERF2 456 map_NHERF2" >> map_NHERF2.lst
#Run af2-complex script
sbatch map_cest.sh map_NHERF2.lst af2_out_reduced


#Calculate scores with LRPPRC, DLAT, EEF1A1, ACAT1, VDAC2
sbatch helper_bash_scripts/af2comp_super_most_ram.sh targeting/map_target_within_each1.lst af2_out_reduced
sbatch helper_bash_scripts/af2comp_super_more_ram.sh targeting/map_target_within_each2.lst af2_out_reduced

#Re-run with map monomer models of AF2complex
nano helper_bash_scripts/map_af2complex_schedule_monomer.sh
#!/bin/bash
for i in {1..6..1}
do
	echo "submitting targeting/map_hits${i}.lst"
	sbatch helper_bash_scripts/af2comp_super_map_monomer.sh targeting/map_hits${i}.lst af2_out_reduced
done
# submitting targeting/map_hits1.lst
# Submitted batch job 57395851
# submitting targeting/map_hits2.lst
# Submitted batch job 57395852
# submitting targeting/map_hits3.lst
# Submitted batch job 57395854
# submitting targeting/map_hits4.lst
# Submitted batch job 57395857
# submitting targeting/map_hits5.lst
# Submitted batch job 57395859
# submitting targeting/map_hits6.lst
# Submitted batch job 57395860
#Try running AlphaFold_Mutlimer to support findings
#Create a combination of map and cesT
cat map_fastas/map.fasta map_fastas/cesT.fasta > map_fastas/map_cesT.fasta
nano helper_bash_scripts/multimer_feature_gen.sh
nano helper_bash_scripts/map_cesT_multimer.sh
#!/bin/bash
#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=8:00:00           # adjust this to match the walltime of your job
#SBATCH --gres=gpu:1              # a GPU helps to accelerate the inference part only
#SBATCH --cpus-per-task=8         # a MAXIMUM of 8 core, Alpafold has no benefit to use more
#SBATCH --mem=30G                 # adjust this according to the memory you need
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DOWNLOAD_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
source ~/alphafold_env/bin/activate
bash helper_bash_scripts/multimer_feature_gen.sh map_fastas/map_cesT.fasta
# Submitted batch job 57397190
#Next model map with TOMM22 (another potentially known interactor)
wget https://rest.uniprot.org/uniprotkb/Q9NS69.fasta -O map_fastas/TOMM22.fasta
#Generate features
sbatch helper_bash_scripts/feat_reduced.sh map_fastas/TOMM22.fasta
#Submitted 57546466
#Make target list for map_TOMM22
echo "##Target(components) Size(AAs) Name(for output)" > targeting/map_TOMM22.lst
echo "map/TOMM22 386 map_with_MTS_TOMM22" >> targeting/map_TOMM22.lst
echo "map|45-203:1/TOMM22 346 map_TOMM22" >> targeting/map_TOMM22.lst
#Run af2-complex script
sbatch helper_bash_scripts/map_tomm22.sh targeting/map_TOMM22.lst af2_out_reduced
##############################################
################################################
###############################################
#Used the INTact db and Mitocarta to get small interacting partners of ACAT1, LRPPRC, or VDAC2. 
#Try modelling with those - they could have been missed by MS approach
#Quickly download sequences for potential map hits
nano helper_bash_scripts/download_map_supp_hits.sh
#!/bin/bash
#Make arrays for ids and names
declare -a id_array=('P21796' 'O75431' 'P38117' 'Q9GZT3' 'Q8IWL3' 'O14561' 'Q99714' 'Q9Y277' 'Q9Y2Q3' 'Q14197' 'Q9NWT8' 'Q96T52' 'Q96LU5' 'Q96A26' 'Q9H6K4' 'Q9NPL8' 'P00441' 'Q16611' 'O14880' 'Q15388' 'Q13268' 'Q9C002' 'Q9Y6E7')
declare -a name_array=('VDAC1' 'MTX2' 'ETFB' 'SLIRP' 'HSCB' 'NDUFAB1' 'HSD17B10' 'VDAC3' 'GSTK1' 'MRPL58' 'AURKAIP1' 'IMMP2L' 'IMMP1L' 'FAM162A' 'OPA3' 'TIMMDC1' 'SOD1' 'BAK1' 'MGST3' 'TOMM20' 'DHRS2' 'C15orf48' 'SIRT4')
#Iterate over the arrays and download sequences
for (( i=0; i<${#id_array[@]}; i++ ));
do
	wget https://rest.uniprot.org/uniprotkb/${id_array[$i]}.fasta -O map_fastas/${name_array[$i]}.fasta
done
#Next step is to model each of these hits
#Next run alphafold on all the human hits

nano helper_bash_scripts/map_supp_hits_afold_feat_gen.sh
#!/bin/bash
declare -a name_array=('VDAC1' 'MTX2' 'ETFB' 'SLIRP' 'HSCB' 'NDUFAB1' 'HSD17B10' 'VDAC3' 'GSTK1' 'MRPL58' 'AURKAIP1' 'IMMP2L' 'IMMP1L' 'FAM162A' 'OPA3' 'TIMMDC1' 'SOD1' 'BAK1' 'MGST3' 'TOMM20' 'DHRS2' 'C15orf48' 'SIRT4')
for (( i=0; i<${#name_array[@]}; i=i+5 ));
do
	echo "submitting ${name_array[$i]}, ${name_array[$i+1]} ${name_array[$i+2]} ${name_array[$i+3]} ${name_array[$i+4]}"
	sbatch helper_bash_scripts/espZ_feat_gen.sh map_fastas/${name_array[$i]}.fasta map_fastas/${name_array[$i+1]}.fasta map_fastas/${name_array[$i+2]}.fasta map_fastas/${name_array[$i+3]}.fasta map_fastas/${name_array[$i+4]}.fasta
done
# submitting VDAC1, MTX2 ETFB SLIRP HSCB
# Submitted batch job 57649308
# submitting NDUFAB1, HSD17B10 VDAC3 GSTK1 MRPL58
# Submitted batch job 57649309
# submitting AURKAIP1, IMMP2L IMMP1L FAM162A OPA3
# Submitted batch job 57649310
# submitting TIMMDC1, SOD1 BAK1 MGST3 TOMM20
# Submitted batch job 57649311
# submitting DHRS2, C15orf48 SIRT4
# Submitted batch job 57649312
#Next step is to prepare target lists -
#Run all 5 multimer and all 5 monomer models
#Next run af2complex on all the human hits
nano helper_bash_scripts/map_supp_af2complex_schedule.sh
#!/bin/bash
for i in {1..5..1}
do
	echo "submitting targeting/map_target_${i}.lst"
	sbatch helper_bash_scripts/af2comp_super.sh targeting/map_supp_target_${i}.lst af2_out_reduced
done
bash helper_bash_scripts/map_supp_af2complex_schedule.sh
# submitting targeting/espZ_target_1.lst
# Submitted batch job 57662473
# submitting targeting/espZ_target_2.lst
# Submitted batch job 57662474
# submitting targeting/espZ_target_3.lst
# Submitted batch job 57662475
# submitting targeting/espZ_target_4.lst
# Submitted batch job 57662476
# submitting targeting/espZ_target_5.lst
# Submitted batch job 57662477
##################################
#Re-run with map monomer models of AF2complex
nano helper_bash_scripts/map_af2complex_schedule_supp_monomer.sh
#!/bin/bash
for i in {1..5..1}
do
	echo "submitting targeting/map_supp_hits${i}.lst"
	sbatch helper_bash_scripts/af2comp_super_map_monomer.sh targeting/map_supp_target_${i}.lst af2_out_reduced
done
# submitting targeting/map_supp_hits1.lst
# Submitted batch job 57683420
# submitting targeting/map_supp_hits2.lst
# Submitted batch job 57683421
# submitting targeting/map_supp_hits3.lst
# Submitted batch job 57683422
# submitting targeting/map_supp_hits4.lst
# Submitted batch job 57683423
# submitting targeting/map_supp_hits5.lst
# Submitted batch job 57683424
#copy all supplementary jsons
nano cp_map_supp_jsons.sh
#!/bin/bash
declare -a name_array=('VDAC1' 'MTX2' 'ETFB' 'SLIRP' 'HSCB' 'NDUFAB1' 'HSD17B10' 'VDAC3' 'GSTK1' 'MRPL58' 'AURKAIP1' 'IMMP2L' 'IMMP1L' 'FAM162A' 'OPA3' 'TIMMDC1' 'SOD1' 'BAK1' 'MGST3' 'TOMM20' 'DHRS2' 'C15orf48' 'SIRT4')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	mkdir af2complex_jsons/map_${name_array[$i]}
	cp map_${name_array[$i]}/ranking_all* af2complex_jsons/map_${name_array[$i]}/
done

#Upon inspection of the map-BAK complex - it seems that map specifically interacts with BH1 and BH2 domains.
#Try one last final round of map modelling with hits - use Uniprot curated Bcl2-family proteins 
#Quickly download sequences for potential map hits
nano helper_bash_scripts/download_map_bcl2.sh
#!/bin/bash
#Make arrays for ids and names
declare -a id_array=('O43521'	'P10415'	'Q07812'	'Q07817'	'Q07820'	'Q16548'	'Q16611'	'Q92843'	'Q92934'	'Q96LC9'	'Q9BXH1'	'Q9BXK5'	'Q9BZR8'	'Q9HD36'	'Q9UMX3'	'Q9HB09')
declare -a name_array=('BCL2L11'	'BCL2'	'BAX'	'BCL2L1'	'MCL1'	'BCL2A1'	'BAK1'	'BCL2L2'	'BAD'	'BMF'	'BBC3'	'BCL2L13'	'BCL2L14'	'BCL2L10'	'BOK'	'BCL2L12')
#Iterate over the arrays and download sequences
for (( i=0; i<${#id_array[@]}; i++ ));
do
	wget https://rest.uniprot.org/uniprotkb/${id_array[$i]}.fasta -O map_fastas/${name_array[$i]}.fasta
done

#Generate features for bcl2-like proteins
nano helper_bash_scripts/map_bcl2_afold_feat_gen.sh
#!/bin/bash
declare -a name_array=('BCL2L11'	'BCL2'	'BAX'	'BCL2L1'	'MCL1'	'BCL2A1'	'BCL2L2'	'BAD'	'BMF'	'BBC3'	'BCL2L13'	'BCL2L14'	'BCL2L10'	'BOK'	'BCL2L12')
for (( i=0; i<${#name_array[@]}; i=i+3 ));
do
	echo "submitting ${name_array[$i]}, ${name_array[$i+1]}, ${name_array[$i+2]}" 
	sbatch helper_bash_scripts/espZ_feat_gen.sh map_fastas/${name_array[$i]}.fasta map_fastas/${name_array[$i+1]}.fasta map_fastas/${name_array[$i+2]}.fasta 
done
# submitting BCL2L11, BCL2, BAX
# Submitted batch job 57733073
# submitting BCL2L1, MCL1, BCL2A1
# Submitted batch job 57733074
# submitting BCL2L2, BAD, BMF
# Submitted batch job 57733075
# submitting BBC3, BCL2L13, BCL2L14
# Submitted batch job 57733076
# submitting BCL2L10, BOK, BCL2L12
# Submitted batch job 57733077
nano helper_bash_scripts/map_bcl2_af2complex_schedule.sh
#!/bin/bash
for i in {1..5..1}
do
	echo "submitting targeting/map_bcl2_target_${i}.lst for multimer"
	sbatch helper_bash_scripts/af2comp_super.sh targeting/map_bcl2_target_${i}.lst af2_out_reduced
	echo "submitting targeting/map_bcl2_target_${i}.lst for monomer"
	sbatch helper_bash_scripts/af2comp_super_map_monomer.sh targeting/map_bcl2_target_${i}.lst af2_out_reduced
done
bash helper_bash_scripts/map_bcl2_af2complex_schedule.sh
# submitting targeting/map_bcl2_target_1.lst for multimer
# Submitted batch job 57741881
# submitting targeting/map_bcl2_target_1.lst for monomer
# Submitted batch job 57741884
# submitting targeting/map_bcl2_target_2.lst for multimer
# Submitted batch job 57741887
# submitting targeting/map_bcl2_target_2.lst for monomer
# Submitted batch job 57741891
# submitting targeting/map_bcl2_target_3.lst for multimer
# Submitted batch job 57741894
# submitting targeting/map_bcl2_target_3.lst for monomer
# Submitted batch job 57741896
# submitting targeting/map_bcl2_target_4.lst for multimer
# Submitted batch job 57741898
# submitting targeting/map_bcl2_target_4.lst for monomer
# Submitted batch job 57741900
# submitting targeting/map_bcl2_target_5.lst for multimer
# Submitted batch job 57741901
# submitting targeting/map_bcl2_target_5.lst for monomer
# Submitted batch job 57741902
#copy all bcl2 jsons
nano cp_map_bcl2_jsons.sh
#!/bin/bash
declare -a name_array=('BCL2L11'	'BCL2'	'BAX'	'BCL2L1'	'MCL1'	'BCL2A1'	'BCL2L2'	'BAD'	'BMF'	'BBC3'	'BCL2L13'	'BCL2L14'	'BCL2L10'	'BOK'	'BCL2L12')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	mkdir af2complex_jsons/map_${name_array[$i]}
	cp map_${name_array[$i]}/ranking_all* af2complex_jsons/map_${name_array[$i]}/
done
#Try Bcl-Xs (short version of BCL2L1)
wget https://rest.uniprot.org/uniprotkb/Q07817-2.fasta -O map_fastas/BclXS.fasta
#Generate features
sbatch helper_bash_scripts/feat_reduced.sh map_fastas/BclXS.fasta 
#Make target list for map_TOMM22
echo "##Target(components) Size(AAs) Name(for output)" > targeting/map_BclXS.lst
echo "map|45-203:1/BclXS 450 map_BclXS" >> targeting/map_BclXS.lst
#Run af2-complex script
sbatch helper_bash_scripts/af2comp_super.sh targeting/map_BclXS.lst af2_out_reduced
#All scores of 0, so doesn't really matter
#make targeting list for map_IMMP2L with MTS
echo "##Target(components) Size(AAs) Name(for output)" > targeting/map_IMMP.lst
echo "map/IMMP2L 450 map_with_MTS_IMMP2L" >> targeting/map_IMMP.lst
echo "map/IMMP2L/IMMP1L 800 map_IMMP2L_IMMP1L" >> targeting/map_IMMP.lst
sbatch helper_bash_scripts/af2comp_super.sh targeting/map_IMMP.lst af2_out_reduced

#Quickly download sequences for for TRAP1_associated
nano helper_bash_scripts/download_map_TRAP.sh
#!/bin/bash
#Make arrays for ids and names
declare -a id_array=('O75208' 'P52815' 'P30084' 'O75489' 'O00483' 'P0C7P0' 'Q8WUK0' 'Q99497')
declare -a name_array=('COQ9' 'MRPL12' 'ECHS1' 'NDUFS3' 'NDUFA4' 'CISD3' 'PTPMT1' 'PARK7')
#Iterate over the arrays and download sequences
for (( i=0; i<${#id_array[@]}; i++ ));
do
	wget https://rest.uniprot.org/uniprotkb/${id_array[$i]}.fasta -O map_fastas/${name_array[$i]}.fasta
done	
#Generate features for TRAP proteins
nano helper_bash_scripts/map_TRAP_afold_feat_gen.sh
#!/bin/bash
declare -a name_array=('COQ9' 'MRPL12' 'ECHS1' 'NDUFS3' 'NDUFA4' 'CISD3' 'PTPMT1' 'PARK7')
for (( i=0; i<${#name_array[@]}; i=i+2 ));
do
	echo "submitting ${name_array[$i]}, ${name_array[$i+1]}" 
	sbatch helper_bash_scripts/espZ_feat_gen.sh map_fastas/${name_array[$i]}.fasta map_fastas/${name_array[$i+1]}.fasta
done
# submitting COQ9, MRPL12
# Submitted batch job 59050074
# submitting ECHS1, NDUFS3
# Submitted batch job 59050075
# submitting NDUFA4, CISD3
# Submitted batch job 59050076
# submitting PTPMT1, PARK7
# Submitted batch job 59050077
#Submit AF2complex modelling
nano helper_bash_scripts/map_TRAP1_af2complex_schedule.sh
#!/bin/bash
for i in {1..4..1}
do
	echo "submitting targeting/map_supp_TRAP_target_${i}.lst for multimer"
	sbatch helper_bash_scripts/af2comp_super.sh targeting/map_supp_TRAP_target_${i}.lst af2_out_reduced
	echo "submitting targeting/map_supp_TRAP_target_${i}.lst for monomer"
	sbatch helper_bash_scripts/af2comp_super_map_monomer.sh targeting/map_supp_TRAP_target_${i}.lst af2_out_reduced
done
bash helper_bash_scripts/map_TRAP1_af2complex_schedule.sh
# submitting targeting/map_supp_TRAP_target_1.lst for multimer
# Submitted batch job 59065449
# submitting targeting/map_supp_TRAP_target_1.lst for monomer
# Submitted batch job 59065451
# submitting targeting/map_supp_TRAP_target_2.lst for multimer
# Submitted batch job 59065453
# submitting targeting/map_supp_TRAP_target_2.lst for monomer
# Submitted batch job 59065455
# submitting targeting/map_supp_TRAP_target_3.lst for multimer
# Submitted batch job 59065457
# submitting targeting/map_supp_TRAP_target_3.lst for monomer
# Submitted batch job 59065459
# submitting targeting/map_supp_TRAP_target_4.lst for multimer
# Submitted batch job 59065461
# submitting targeting/map_supp_TRAP_target_4.lst for monomer
# Submitted batch job 59065463
#copy all TRAP jsons
nano cp_map_TRAP_jsons.sh
#!/bin/bash
declare -a name_array=('COQ9' 'MRPL12' 'ECHS1' 'NDUFS3' 'NDUFA4' 'CISD3' 'PTPMT1' 'PARK7')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	mkdir af2complex_jsons/map_${name_array[$i]}
	cp map_${name_array[$i]}/ranking_all* af2complex_jsons/map_${name_array[$i]}/
done
#Now the final step to do is to assess the other APEX hits - mitochondrial partners
#Quickly download sequences for for other partners
nano helper_bash_scripts/download_map_system.sh
#!/bin/bash
#Make arrays for ids and names
declare -a id_array=('P21912' 'P30049' 'P47985' 'Q9HAV7' 'Q5VUM1' 'P07919' 'Q8NFV4' 'P35232' 'Q9NX18' 'P30042' 'Q14061' 'Q9H1K1' 'Q02978' 'Q99623' 'A6NFY7' 'P53007' 'O96000' 'Q9Y3A0' 'Q9H061' 'P05141' 'Q9NS69' 'Q9NX63' 'Q8WYQ3' 'Q9HC21' 'Q96I36' 'Q96GK7' 'O75880' 'Q5SXM8' 'Q96ND0' 'Q9BTZ2' 'P61604' 'Q9H9B4' 'Q9NRP4' 'Q9Y2R0' 'Q8TB37' 'Q9NU23' 'Q8TAE8' 'Q8WWC4' 'Q9Y241' 'Q9Y3E2' 'P55789' 'Q9BWM7' 'Q9Y6H1' 'Q9BSK2' 'Q8IVP5' 'Q9NWR8' 'P07195' 'P58557' 'P36404' 'Q9GZY8' 'Q9NX40' 'P12236' 'P32119' 'Q96IX5' 'Q9GZY4' 'Q9BRT2' 'O95900' 'Q13162' 'Q9BUV8' 'P27695' 'Q8NE22' 'Q9HBL7')
declare -a name_array=('SDHB' 'ATP5F1D' 'UQCRFS1' 'GRPEL1' 'SDHAF4' 'UQCRH' 'ABHD11' 'PHB' 'SDHAF2' 'GATD3A' 'COX17' 'ISCU' 'SLC25A11' 'PHB2' 'SDHAF1' 'SLC25A1' 'NDUFB10' 'COQ4' 'TMEM126A' 'SLC25A5' 'TOMM22' 'CHCHD3' 'CHCHD10' 'SLC25A19' 'COX14' 'FAHD2A' 'SCO1' 'DNLZ' 'FAM210A' 'DHRS4' 'HSPE1' 'SFXN1' 'SDHAF3' 'COA3' 'NUBPL' 'LYRM2' 'GADD45GIP1' 'MAIP1' 'HIGD1A' 'BOLA1' 'GFER' 'SFXN3' 'CHCHD2' 'SLC25A33' 'FUNDC1' 'MCUB' 'LDHB' 'YBEY' 'ARL2' 'MFF' 'OCIAD1' 'SLC25A6' 'PRDX2' 'ATP5MD' 'COA1' 'UQCC2' 'TRUB2' 'PRDX4' 'RAB5IF' 'APEX1' 'SETD9' 'PLGRKT')
#Iterate over the arrays and download sequences
for (( i=0; i<${#id_array[@]}; i++ ));
do
	wget https://rest.uniprot.org/uniprotkb/${id_array[$i]}.fasta -O map_fastas/${name_array[$i]}.fasta
done

nano helper_bash_scripts/map_system_hits_afold_feat_gen.sh
#!/bin/bash
declare -a name_array=('SDHB' 'ATP5F1D' 'UQCRFS1' 'GRPEL1' 'SDHAF4' 'UQCRH' 'ABHD11' 'PHB' 'SDHAF2' 'GATD3A' 'COX17' 'ISCU' 'SLC25A11' 'PHB2' 'SDHAF1' 'SLC25A1' 'NDUFB10' 'COQ4' 'TMEM126A' 'SLC25A5' 'TOMM22' 'CHCHD3' 'CHCHD10' 'SLC25A19' 'COX14' 'FAHD2A' 'SCO1' 'DNLZ' 'FAM210A' 'DHRS4' 'HSPE1' 'SFXN1' 'SDHAF3' 'COA3' 'NUBPL' 'LYRM2' 'GADD45GIP1' 'MAIP1' 'HIGD1A' 'BOLA1' 'GFER' 'SFXN3' 'CHCHD2' 'SLC25A33' 'FUNDC1' 'MCUB' 'LDHB' 'YBEY' 'ARL2' 'MFF' 'OCIAD1' 'SLC25A6' 'PRDX2' 'ATP5MD' 'COA1' 'UQCC2' 'TRUB2' 'PRDX4' 'RAB5IF' 'APEX1' 'SETD9' 'PLGRKT')
for (( i=0; i<${#name_array[@]}; i=i+5 ));
do
	echo "submitting ${name_array[$i]}, ${name_array[$i+1]} ${name_array[$i+2]} ${name_array[$i+3]} ${name_array[$i+4]}"
	sbatch helper_bash_scripts/espZ_feat_gen.sh map_fastas/${name_array[$i]}.fasta map_fastas/${name_array[$i+1]}.fasta map_fastas/${name_array[$i+2]}.fasta map_fastas/${name_array[$i+3]}.fasta map_fastas/${name_array[$i+4]}.fasta
done
# submitting SDHB, ATP5F1D UQCRFS1 GRPEL1 SDHAF4
# Submitted batch job 59363336
# submitting UQCRH, ABHD11 PHB SDHAF2 GATD3A
# Submitted batch job 59363337
# submitting COX17, ISCU SLC25A11 PHB2 SDHAF1
# Submitted batch job 59363339
# submitting SLC25A1, NDUFB10 COQ4 TMEM126A SLC25A5
# Submitted batch job 59363340
# submitting TOMM22, CHCHD3 CHCHD10 SLC25A19 COX14
# Submitted batch job 59363341
# submitting FAHD2A, SCO1 DNLZ FAM210A DHRS4
# Submitted batch job 59363342
# submitting HSPE1, SFXN1 SDHAF3 COA3 NUBPL
# Submitted batch job 59363343
# submitting LYRM2, GADD45GIP1 MAIP1 HIGD1A BOLA1
# Submitted batch job 59363344
# submitting GFER, SFXN3 CHCHD2 SLC25A33 FUNDC1
# Submitted batch job 59363345
# submitting MCUB, LDHB YBEY ARL2 MFF
# Submitted batch job 59363347
# submitting OCIAD1, SLC25A6 PRDX2 ATP5MD COA1
# Submitted batch job 59363348
# submitting UQCC2, TRUB2 PRDX4 RAB5IF APEX1
# Submitted batch job 59363349
# submitting SETD9, PLGRKT
# Submitted batch job 59363350
#Submit AF2complex modelling
nano helper_bash_scripts/map_system_af2complex_schedule.sh
#!/bin/bash
for i in {1..13..1}
do
	echo "submitting targeting/map_system_target_${i}.lst for multimer"
	sbatch helper_bash_scripts/af2comp_super.sh targeting/map_system_target_${i}.lst af2_out_reduced
	echo "submitting targeting/map_system_target_${i}.lst for monomer"
	sbatch helper_bash_scripts/af2comp_super_map_monomer.sh targeting/map_system_target_${i}.lst af2_out_reduced
done
bash helper_bash_scripts/map_system_af2complex_schedule.sh
# submitting targeting/map_system_target_1.lst for multimer
# Submitted batch job 59406573
# submitting targeting/map_system_target_1.lst for monomer
# Submitted batch job 59406574
# submitting targeting/map_system_target_2.lst for multimer
# Submitted batch job 59406575
# submitting targeting/map_system_target_2.lst for monomer
# Submitted batch job 59406576
# submitting targeting/map_system_target_3.lst for multimer
# Submitted batch job 59406577
# submitting targeting/map_system_target_3.lst for monomer
# Submitted batch job 59406578
# submitting targeting/map_system_target_4.lst for multimer
# Submitted batch job 59406580
# submitting targeting/map_system_target_4.lst for monomer
# Submitted batch job 59406581
# submitting targeting/map_system_target_5.lst for multimer
# Submitted batch job 59406582
# submitting targeting/map_system_target_5.lst for monomer
# Submitted batch job 59406583
# submitting targeting/map_system_target_6.lst for multimer
# Submitted batch job 59406584
# submitting targeting/map_system_target_6.lst for monomer
# Submitted batch job 59406585
# submitting targeting/map_system_target_7.lst for multimer
# Submitted batch job 59406586
# submitting targeting/map_system_target_7.lst for monomer
# Submitted batch job 59406587
# submitting targeting/map_system_target_8.lst for multimer
# Submitted batch job 59406588
# submitting targeting/map_system_target_8.lst for monomer
# Submitted batch job 59406591
# submitting targeting/map_system_target_9.lst for multimer
# Submitted batch job 59406592
# submitting targeting/map_system_target_9.lst for monomer
# Submitted batch job 59406593
# submitting targeting/map_system_target_10.lst for multimer
# Submitted batch job 59406594
# submitting targeting/map_system_target_10.lst for monomer
# Submitted batch job 59406595
# submitting targeting/map_system_target_11.lst for multimer
# Submitted batch job 59406596
# submitting targeting/map_system_target_11.lst for monomer
# Submitted batch job 59406597
# submitting targeting/map_system_target_12.lst for multimer
# Submitted batch job 59406598
# submitting targeting/map_system_target_12.lst for monomer
# Submitted batch job 59406599
# submitting targeting/map_system_target_13.lst for multimer
# Submitted batch job 59406600
# submitting targeting/map_system_target_13.lst for monomer
# Submitted batch job 59406602
#copy all TRAP jsons
nano cp_map_system_jsons.sh
#!/bin/bash
declare -a name_array=('SDHB' 'ATP5F1D' 'UQCRFS1' 'GRPEL1' 'SDHAF4' 'UQCRH' 'ABHD11' 'PHB' 'SDHAF2' 'GATD3A' 'COX17' 'ISCU' 'SLC25A11' 'PHB2' 'SDHAF1' 'SLC25A1' 'NDUFB10' 'COQ4' 'TMEM126A' 'SLC25A5' 'TOMM22' 'CHCHD3' 'CHCHD10' 'SLC25A19' 'COX14' 'FAHD2A' 'SCO1' 'DNLZ' 'FAM210A' 'DHRS4' 'HSPE1' 'SFXN1' 'SDHAF3' 'COA3' 'NUBPL' 'LYRM2' 'GADD45GIP1' 'MAIP1' 'HIGD1A' 'BOLA1' 'GFER' 'SFXN3' 'CHCHD2' 'SLC25A33' 'FUNDC1' 'MCUB' 'LDHB' 'YBEY' 'ARL2' 'MFF' 'OCIAD1' 'SLC25A6' 'PRDX2' 'ATP5MD' 'COA1' 'UQCC2' 'TRUB2' 'PRDX4' 'RAB5IF' 'APEX1' 'SETD9' 'PLGRKT')
for (( i=0; i<${#name_array[@]}; i++ ));
do
	mkdir af2complex_jsons/map_system/map_${name_array[$i]}
	cp map_${name_array[$i]}/ranking_all* af2complex_jsons/map_system/map_${name_array[$i]}/
done
#GATD3A did not work for making features with AlphaFold so did not have results with af2complex