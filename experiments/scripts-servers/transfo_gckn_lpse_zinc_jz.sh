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
        sbatch $WORK/GraphiT-edges/experiments/scripts-servers/transfo_gckn_lpse_zinc_jz.slurm "$1"
}


while getopts e:u:z: flag
do
    case "${flag}" in
        e) encode_e=${OPTARG};;
        u) use_e=${OPTARG};;
        z) zero_d=${OPTARG};;
    esac
done

outdir=$WORK/test-lpse/results-transfo-gckn-zinc/seed

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
    edge_attr='/edge_attr'
elif [ $use_e = 'ne' ]; then
	use_edge_attr=''
    edge_attr=''
else
	echo "Error: Argument -u should be 'e' or 'ne'. Exiting now."
	exit 2
fi

echo "use zero diag -z : $zero_d"
if [ $zero_d = 'y' ]; then
	zero_diag='--zero-diag' 
    zero_diag_attr='/zero_diag'
elif [ $zero_d = 'n' ]; then
	zero_diag=''
    zero_diag_attr=''
else
	echo "Error: Argument -z should be 'y' or 'n'. Exiting now."
	exit 2
fi

echo "outdir = $outdir"





dataset='ZINC'
epochs=1500
seeds=1 #"0 1 2 3"

pos_enc="pstep"
normalization="sym"
gckn_dims="128"
gckn_paths="8"
gckn_sigmas="0.6"
gckn_pooling="sum"
ps="16"  # "2 3"
betas="0.25" #"0.5 0.6" # "0.5"
nb_heads=8
nb_layers=10 #"3 4 5"
dim_hiddens=128 #"64 128 256"
lrs="0.0007"  #"0.001 0.0001 0.00001"
wds="0.001" #"0.001 0.0001"
dropouts=0.3 #"0.0 0.3"



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
			#if [ ! -f ${outdir}${seed}/transformer/ZINC${zero_diag_attr}${edge_attr}/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv ]; then					
			echo ${outdir}${seed}/transformer/ZINC${zero_diag_attr}${edge_attr}/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv
            args="--outdir ${outdir}${seed} --seed ${seed} --epochs ${epochs} \
            --pos-enc ${pos_enc} --p ${p} --beta ${beta} \
            --gckn-dim ${gckn_dim} --gckn-path ${gckn_path} --gckn-sigma ${gckn_sigma} --gckn-pooling ${gckn_pooling} \
            --nb-heads ${nb_heads} --nb-layers ${nb_layer} --dim-hidden ${dim_hidden} --lr ${lr} --weight-decay ${wd} --dropout ${dropout} \
             ${encode_edge} ${use_edge_attr} ${zero_diag}"  
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
	
