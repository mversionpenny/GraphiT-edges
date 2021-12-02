#!/bin/bash

sendjob(){
        max_jobs=150
        counter=`squeue -u $USER | wc -l`
        echo $counter
        while [ "$counter" -ge "$max_jobs" ]; do
                sleep 90
                counter=`squeue -u $USER | wc -l`
                echo $counter
        done
        sbatch $WORK/GraphiT-edges/experiments/scripts-servers/transfo_gckn_zinc_jz.slurm "$1"
}


while getopts e: flag
do
    case "${flag}" in
        e) encode_e=${OPTARG};;
    esac
done
echo "encode -e : $encode_e"
if [ $encode_e = 'e' ]; then
	encode_edge='--encode-edge' 
    path_edge='True'
	outdir=$STORE/results-transfo-gckn-zinc/edges/seed
elif [ $encode_e = 'ne' ]; then
	encode_edge=''
    path_edge='False'
	outdir=$STORE/results-transfo-gckn-zinc/noedges/seed
else
	echo "Error: Argument -e should be 'e' or 'ne'. Exiting now."
	exit 2
fi

echo "outdir = $outdir"





dataset='ZINC'
epochs=10
echo "TO CHANGE"
seeds="3" #seeds="0 1 2 3"

pos_enc="diffusion"
normalization="sym"
gckn_dims="32"
gckn_paths="8"
gckn_sigmas="0.6"
gckn_pooling="sum"
ps="1"
betas="0.6" #betas="0.5 0.6"
nb_heads=8
nb_layers="5" #nb_layers="3 4 5"
dim_hiddens="128" #dim_hiddens="32 64 128 256"
lrs="0.00001" #lrs="0.001 0.0001 0.00001"
wds="0.0001" #wds="0.1 0.001 0.0001"
dropouts="0.1" #dropouts="0.1 0.5"


echo "/!\  ps are $ps, beta are $betas and pos_enc is None"

for seed in $seeds; do
for gckn_dim in $gckn_dims; do
for gckn_path in $gckn_paths; do
for gckn_sigma in $gckn_sigmas; do
    for p in $ps; do
    for beta in $betas; do
        for nb_layer in $nb_layers; do
        for dim_hidden in $dim_hiddens; do
        for lr in $lrs; do
        for wd in $wds; do
        for dropout in $dropouts; do

			params="${lr}_${nb_layer}_${nb_heads}_${dim_hidden}_BN_None_${normalization}_${p}_${beta}_${wd}_${dropout}"			
			#if [ ! -f ${outdir}${seed}/transformer/ZINC/edge_attr/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv ]; then					
			#echo ${outdir}${seed}/transformer/ZINC/edge_attr/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv
            args="--outdir ${outdir}${seed} --seed ${seed} --epochs ${epochs} \
            --p ${p} --beta ${beta} \
            --gckn-dim ${gckn_dim} --gckn-path ${gckn_path} --gckn-sigma ${gckn_sigma} --gckn-pooling ${gckn_pooling} \
            --nb-heads ${nb_heads} --nb-layers ${nb_layer} --dim-hidden ${dim_hidden} --lr ${lr} --weight-decay ${wd} --dropout ${dropout} \
            --warmup 2000 --use-edge-attr ${encode_edge}"  
			sendjob "$args"
			#fi
        done
        done
        done
        done
        done
    done
    done
done
done
done
done
	
