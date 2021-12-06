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


while getopts e:u: flag
do
    case "${flag}" in
        e) encode_e=${OPTARG};;
        u) use_e=${OPTARG};;
    esac
done

outdir=$WORK/results-transfo-gckn-zinc/seed

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


#outdir = outdir + '/{}_{}_{}_{}_{}_{}_{}_{}_{}_{}_{}'.format(
#            args.lr, args.nb_layers, args.nb_heads, args.dim_hidden, bn,
#            args.pos_enc, args.normalization, args.p, args.beta, 
#            args.weight_decay, args.dropout
#        )

# seed3/transformer/ZINC/gckn_8_32_0.6_sum_True_True_True/0.0001_3_8_64_BN_None_sym_1_0.6_0.001_0.3/results.csv  not found.
# seed3/transformer/ZINC/gckn_8_32_0.6_sum_True_True_True/0.001_3_8_128_BN_None_sym_1_0.6_0.0001_0.3/results.csv  not found.
# seed3/transformer/ZINC/gckn_8_32_0.6_sum_True_True_True/0.0001_3_8_128_BN_None_sym_1_0.6_0.001_0.0/results.csv  not found.
# seed3/transformer/ZINC/gckn_8_32_0.6_sum_True_True_True/0.0001_3_8_128_BN_None_sym_1_0.6_0.001_0.3/results.csv  not found.


dataset='ZINC'
epochs=500
seeds="3"


pos_enc="diffusion"
normalization="sym"
gckn_dims="32"
gckn_paths="8"
gckn_sigmas="0.6"
gckn_pooling="sum"
ps="1"
betas="0.6"
nb_heads=8
nb_layers="3"
dim_hiddens="64"
lrs="0.0001"
wds="0.001"
dropouts="0.3"


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
            --p ${p} --beta ${beta} \
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
	
