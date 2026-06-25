#!/bin/bash
#SBATCH --job-name=liggghts_2Node
#SBATCH --nodes=2
#SBATCH --nodelist=Molga-2-[1-8]     # Selects from the 32-core nodes
#SBATCH --ntasks-per-node=32
#SBATCH --exclude=Molga-6-[1-11]     # Explicitly avoiding Molga-6
#SBATCH --output=Nodes_2/liggghts_%j.out
#SBATCH --error=Nodes_2/ligghts_%j.err
#SBATCH --partition=normal

module load openmpi4_verbs/4.1.6

cd /mnt/beegfs/users/kortiz/Proyecto/NOVECIENTAS3XV4

# Define the output directory
OUTPUT_FOLDER="Nodes_2"

# Create the directory so LIGGGHTS doesn't crash on write
mkdir -p $OUTPUT_FOLDER

# Execute LIGGGHTS and pass the folder name to the outdir variable
mpirun -np $SLURM_NTASKS /mnt/beegfs/users/kortiz/Proyecto/LIGGGHTS-PUBLIC/src/lmp_auto -in in.NOVECIENTAS3XV4
