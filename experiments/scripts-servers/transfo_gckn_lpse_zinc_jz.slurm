#!/bin/bash
#SBATCH --job-name transfo-paths-zinc
#SBATCH -A tbr@gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=10
#SBATCH --hint=nomultithread
#SBATCH --time=10:00:00
#SBATCH --output=/gpfsscratch/rech/tbr/uho58uo/logs/%j.out      # nom du fichier de sortie
#SBATCH --error=/gpfsscratch/rech/tbr/uho58uo/logs/%j.out       # nom du fichier d'erreur



export PYTHONPATH=${WORK}/GraphiT-edges
echo $PYTHONPATH


module purge

# module load cuda/10.1.2
module load pytorch-gpu/py3/1.6.0

 
cd $PYTHONPATH
make

cd experiments


args=$1

echo "$args"

python -u $WORK/GraphiT-edges/experiments/run_transformer_gckn_lpse.py $args