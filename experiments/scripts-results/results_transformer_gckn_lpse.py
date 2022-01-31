# -*- coding: utf-8 -*-
import argparse
import numpy as np
import os
import copy
import pandas as pd
from collections import defaultdict
import torch


import torch.nn.functional as F
from torch.utils.data import DataLoader
from torch_geometric import datasets

from timeit import default_timer as timer
from torch import nn, optim

from statistics import mean, stdev

def main():
    
    seed_grid = [0, 1, 2, 3]
    
    gckn_path = 8
    gckn_sigma = 0.6
    gckn_dim = 32
    gckn_pooling = 'sum'

    
    bn='BN'
    beta_grid = [0.5, 0.6] #[0.5]
    p_grid = [1]
    normalization='sym'
    pos_enc='diffusion'
    nb_heads = 8
    nb_layers_grid=[3, 4, 5]
    dim_hidden_list=[64, 128, 256]
    lr_list=[0.001, 0.0001, 0.00001]
    wd_list=[0.001, 0.0001]
    drp_list=[0.0, 0.3]
    encode_edge=True
    
    

    path_base = '/gpfswork/rech/tbr/uho58uo/test-lpse/results-transfo-gckn-zinc/seed'
   
    best_val_path = ''
    test_mae_list = []
    for seed in seed_grid:
        best_val_mae = 1000 #= 0 #= 1000
        for beta in beta_grid:
            for p in p_grid:
                for nb_layers in nb_layers_grid:
                    for dim_hidden in dim_hidden_list:    
                        for lr in lr_list:
                            for wd in wd_list:
                                for drp in drp_list:
                                    
                                    path = path_base + '{}/transformer/ZINC/edge_attr/gckn_{}_{}_{}_{}_{}_{}_{}/'.format(
                                        seed, gckn_path, gckn_dim, gckn_sigma, gckn_pooling, True, True, encode_edge
                                    ) + '{}_{}_{}_{}_{}_{}_{}_{}_{}_{}_{}/'.format(
                                        lr, nb_layers, nb_heads, dim_hidden, bn, pos_enc, normalization, p, beta,
                                        wd, drp
                                    ) + 'results.csv'

                                    if os.path.exists(path):
                                        results = pd.read_csv(path)
                                        #breakpoint()
                                        val_mae = results.loc[results['name'] == 'val_mae', 'value'].iloc[0] #results.loc[results['name'] == 'val_auc', 'value'].iloc[0]#results.loc[results['name'] == 'val_mae', 'value'].iloc[0]
                                        if val_mae < best_val_mae: #val_mae > best_val_mae:#val_mae < best_val_mae:
                                            best_val_mae = val_mae
                                            best_val_path = path
                                    else:
                                        print(path, ' not found.')

        print("*******", best_val_path, "*******")                          
        best_val_df = pd.read_csv(best_val_path)
        test_mae = best_val_df.loc[best_val_df['name'] == 'test_mae', 'value'].iloc[0] #best_val_df.loc[best_val_df['name'] == 'test_auc', 'value'].iloc[0] #best_val_df.loc[best_val_df['name'] == 'test_mae', 'value'].iloc[0]
        test_mae_list.append(test_mae)
    print(test_mae_list)
    print("mean: ", mean(test_mae_list))
    print("stdev: ", stdev(test_mae_list))
                         

if __name__ == "__main__":
    main()
