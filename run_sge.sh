#!/bin/bash
#$ -N simple
#$ -t 1-1000
#$ -tc 10
#$ -e err/
#$ -o out/
#$ -cwd

. /etc/profile
module load packages/matlab/r2012b

printf "Executing $SGE_TASK_ID of $num_jobs jobs\n"

echo matlab -nodisplay -nosplash -r "simplebroken"
matlab -nodisplay -nosplash -r "simplebroken"
