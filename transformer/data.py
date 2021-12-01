# from torch.utils.data import Datasets
import torch
import torch.nn.functional as F
from torch.utils.data.dataloader import default_collate
import torch_geometric.utils as utils


class GraphDataset(object):
    def __init__(self, dataset, n_tags=None, degree=False):
        """a pytorch geometric dataset as input
        """
        self.dataset = dataset
        self.n_features = dataset[0].x.shape[-1]
        self.pe_list = None
        self.lap_pe_list = None
        self.lap_pe_dim = None
        self.degree_list = None
        if degree:
            self.compute_degree()
        self.n_tags = n_tags
        self.one_hot()

    def __len__(self):
        return len(self.dataset)

    def __getitem__(self, index):
        data = self.dataset[index]
        if self.x_onehot is not None and len(self.x_onehot) == len(self.dataset):
            data.x_onehot = self.x_onehot[index]
        if self.pe_list is not None and len(self.pe_list) == len(self.dataset):
            data.pe = self.pe_list[index]
        if self.lap_pe_list is not None and len(self.lap_pe_list) == len(self.dataset):
            data.lap_pe = self.lap_pe_list[index]
        if self.degree_list is not None and len(self.degree_list) == len(self.dataset):
            data.degree = self.degree_list[index]
        return data

    def compute_degree(self):
        self.degree_list = []
        for g in self.dataset:
            deg = 1. / torch.sqrt(1. + utils.degree(g.edge_index[0], g.num_nodes))
            self.degree_list.append(deg)

    def input_size(self):	
        if self.n_tags is None:	
            return self.n_features	
        if isinstance(self.n_tags, int):	
            return self.n_tags	
        return sum(self.n_tags)

    def one_hot(self):
        self.x_onehot = None
        if self.n_tags is not None: #and self.n_tags > 1:
            self.x_onehot = []
            for g in self.dataset:
                # onehot = F.one_hot(g.x.view(-1).long(), self.n_tags)
                onehot = atom_one_hot(g.x, self.n_tags)
                self.x_onehot.append(onehot)

    def collate_fn(self):
        def collate(batch):
            batch = list(batch)
            max_len = max(len(g.x) for g in batch)

            padded_x = torch.zeros((len(batch), max_len, self.input_size()))
            mask = torch.zeros((len(batch), max_len), dtype=bool)
            labels = []

            # TODO: check if position encoding matrix is sparse
            # if it's the case, use a huge sparse matrix
            # else use a dense tensor
            pos_enc = None
            use_pe = hasattr(batch[0], 'pe') and batch[0].pe is not None
            if use_pe:
                #print("We might have a problem here")
                if not batch[0].pe.is_sparse:
                    if batch[0].pe.ndim == 2:
                        pos_enc = torch.zeros((len(batch), max_len, max_len))
                    else:
                        pos_enc = torch.zeros((
                            len(batch), batch[0].pe.shape[0], max_len, max_len))
                else:
                    print("Not implemented yet!")

            # process lap PE
            lap_pos_enc = None
            use_lap_pe = hasattr(batch[0], 'lap_pe') and batch[0].lap_pe is not None
            if use_lap_pe:
                # lap_pe_dim = batch[0].lap_pe.shape[-1]
                lap_pos_enc = torch.zeros((len(batch), max_len, self.lap_pe_dim))

            degree = None
            use_degree = hasattr(batch[0], 'degree') and batch[0].degree is not None
            if use_degree:
                degree = torch.zeros((len(batch), max_len))

            for i, g in enumerate(batch):
                labels.append(g.y.view(-1))
                g_len = len(g.x)

                if self.n_tags is None:
                    padded_x[i, :g_len, :] = g.x
                else:
                    padded_x[i, :g_len, :] = g.x_onehot
                mask[i, g_len:] = True
                if use_pe:
                    if g.pe.ndim == 2:
                        pos_enc[i, :g_len, :g_len] = g.pe
                    else:
                        pos_enc[i, :, :g_len, :g_len] = g.pe
                if use_lap_pe:
                    lap_pos_enc[i, :g_len, :g.lap_pe.shape[-1]] = g.lap_pe
                if use_degree:
                    degree[i, :g_len] = g.degree

            return padded_x, mask, pos_enc, lap_pos_enc, degree, default_collate(labels)
        return collate


class OneHotEdges(object):
    def __init__(self, num_edge_classes):
        self.num_edge_classes = num_edge_classes
        

    def __call__(self, data):
        data.edge_attr = F.one_hot(data.edge_attr.long()-1, self.num_edge_classes) 
        return data

def atom_one_hot(nodes, num_atom_types):	
    if isinstance(num_atom_types, int):	
        return F.one_hot(nodes.view(-1).long(), num_atom_types)	
    all_one_hot_feat = []	
    for col in range(len(num_atom_types)):	
        one_hot_feat = F.one_hot(nodes[:, col], num_atom_types[col])	
        all_one_hot_feat.append(one_hot_feat)	
    all_one_hot_feat = torch.cat(all_one_hot_feat, dim=1)	
    return all_one_hot_feat