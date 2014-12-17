#!/bin/bash                                                                                                                                                                
#SBATCH -t 60  #Runtime in minutes
#SBATCH -p hips #Partition to submit to  
#SBATCH -c 10
#SBATCH --mem=2048 #Memory per node in MB (see also --mem-per-cpu)

. ~/.bashrc

module load centos6/matlab-R2013a
for i in {1..5}
do
  matlab -nodesktop -nosplash -r "whetlab_student" &
done

exit