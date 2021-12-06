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
        sbatch $WORK/GraphiT-edges/experiments/scripts-servers/transfo_gckn_molhiv_jz.slurm "$1"
}


while getopts e:u: flag
do
    case "${flag}" in
        e) encode_e=${OPTARG};;
        u) use_e=${OPTARG};;
    esac
done

outdir=$WORK/results-transfo-gckn-molhiv/seed

echo "encode -e : $encode_e"
if [ $encode_e = 'e' ]; then
	encode_edge='--encode-edge' 
    path_edge='True'
elif [ $encode_e = 'ne' ]; then
	encode_edge=''
    path_edge='False'
else
	echo "Error: Argument -e should be 'e' or 'ne'. Exiting now."
	exit 2
fi

echo "use edge in attention -u : $use_e"
if [ $use_e = 'e' ]; then
	use_edge_attr='--use-edge-attr' 
    edge_attr='edge_attr'
elif [ $use_e = 'ne' ]; then
	use_edge_attr=''
    edge_attr=''
else
	echo "Error: Argument -e should be 'e' or 'ne'. Exiting now."
	exit 2
fi

echo "outdir = $outdir"





dataset='molhiv'
epochs=150
seeds="0 1 2 3"

pos_enc="diffusion"
normalization="sym"
gckn_dims="32"
gckn_paths="8"
gckn_sigmas="0.6"
gckn_pooling="sum"
ps="1"
betas="0.5 0.6"
nb_heads=8
nb_layers="3 4 5"
dim_hiddens="64 128 256"
lrs="0.001 0.0001 0.00001"
wds="0.001 0.0001"
dropouts="0.0 0.3"


echo "/!\  ps are $ps, beta are $betas and pos_enc is $pos_enc"

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

			params="${lr}_${nb_layer}_${nb_heads}_${dim_hidden}_BN_${pos_enc}_${normalization}_${p}_${beta}_${wd}_${dropout}"			
			if [ ! -f ${outdir}${seed}/transformer/ZINC/${edge_attr}/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv ]; then					
			#echo ${outdir}${seed}/transformer/ZINC/edge_attr/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv
            args="--outdir ${outdir}${seed} --seed ${seed} --epochs ${epochs} \
            --pos-enc ${pos_enc} --p ${p} --beta ${beta} \
            --gckn-dim ${gckn_dim} --gckn-path ${gckn_path} --gckn-sigma ${gckn_sigma} --gckn-pooling ${gckn_pooling} \
            --nb-heads ${nb_heads} --nb-layers ${nb_layer} --dim-hidden ${dim_hidden} --lr ${lr} --weight-decay ${wd} --dropout ${dropout} \
            --warmup 2000 ${encode_edge} ${use_edge_attr}"  
			sendjob "$args"
			fi
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
	
