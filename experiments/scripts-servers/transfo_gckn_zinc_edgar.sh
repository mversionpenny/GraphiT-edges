intro="source gpu_setVisibleDevices.sh; source /scratch/prospero/mselosse/miniconda3/bin/activate tb;"
cmd="cd /scratch/prospero/mselosse/GraphiT-edges; export PYTHONPATH='/scratch/prospero/mselosse/GraphiT-edges'; cd experiments; python run_transformer_gckn.py"
epochs=500
#pos_enc="pstep"
#pos_enc="diffusion"
pos_enc="None"
normalization="sym"
#normalization="None"
gckn_dims="32"
gckn_paths="8"
gckn_sigmas="0.6"
gckn_pooling="sum"
p=1
betas="1.0"
nb_heads=8
nb_layers=10
dim_hidden="128"
lr=0.0001
weight_decay=0.01
seeds="0 1 2 3"



while getopts e: flag
do
    case "${flag}" in
        e) encode_e=${OPTARG};;
    esac
done


echo "encode -e : $encode_e"
if [ $encode_e = 'e' ]; then
	encode_edge='--encode-edge' #'--encode-edge'
    path_edge='True'
	outdir=/scratch/prospero/mselosse/results-transfo-edges
	logs_out="/scratch/prospero/mselosse/results-transfo-edges/logs/%jobid%.stdout"
	logs_err="/scratch/prospero/mselosse/results-transfo-edges/logs/%jobid%.stderr"
elif [ $encode_e = 'ne' ]; then
	encode_edge=''
    path_edge='False'
	outdir=/scratch/prospero/mselosse/results-transfo-noedges
	logs_out="/scratch/prospero/mselosse/results-transfo-noedges/logs/%jobid%.stdout"
	logs_err="/scratch/prospero/mselosse/results-transfo-noedges/logs/%jobid%.stderr"
else
	echo "Error: Argument -e should be 'e' or 'ne'. Exiting now."
	exit 2
fi

echo "outdir = $outdir"



startjob () {
    while (($(oarstat | grep mselosse | wc -l) > 20)); do echo -n '.'; sleep 100;  done
    oarsub -l "walltime=10:0:0" -p "host!='gpuhost1'"  -O "${logs_out}" -E "${logs_err}" -n "transformer_${1}" "${intro} ${cmd} $2"
    #oarsub -l "walltime=2:0:0" -t besteffort -t idempotent -p "host!='gpuhost1'" -O "${logs_out}" -E "${logs_err}" -n "transformer_${1}" "${cmd} $2"
}

for gckn_path in $gckn_paths; do
for gckn_dim in $gckn_dims; do
for gckn_sigma in $gckn_sigmas; do
for beta in $betas; do
    for seed in $seeds; do
        params="${lr}_${nb_layers}_${nb_heads}_${dim_hidden}_LN_${pos_enc}_${normalization}_${p}_${beta}_${weight_decay}"
	
        echo "${outdir}${seed}/transformer/ZINC/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv"
        if [ ! -f ${outdir}${seed}/transformer/ZINC/gckn_${gckn_path}_${gckn_dim}_${gckn_sigma}_${gckn_pooling}_True_True_${path_edge}/${params}/results.csv ]; then
            startjob "${params}" "--gckn-path ${gckn_path} --gckn-dim ${gckn_dim} --gckn-pooling ${gckn_pooling} 
            --outdir ${outdir}${seed} --seed ${seed} --epochs ${epochs} --pos_enc ${pos_enc} --beta ${beta} --p ${p}
            --nb-heads ${nb_heads} --nb-layers ${nb_layers} --dim-hidden ${dim_hidden} --lr ${lr} --weight-decay ${weight_decay}
            ${encode_edge} --warmup 2000"
        fi
    done
done
done
done
done
