#!/usr/bin/env python3
"""
Extract ancestral sequences up to the second MRCA (parent of MRCA) for each clade.
"""

import sys
import csv
from collections import defaultdict
from Bio import SeqIO, Phylo

def parse_cluster_csv(cluster_csv):
    """Parse AutoPhy cluster CSV and get sequences per cluster."""
    clusters = defaultdict(list)
    with open(cluster_csv) as f:
        reader = csv.DictReader(f)
        for row in reader:
            clusters[row['Cluster']].append(row['Label'])
    return clusters

def find_mrca_and_parent(tree, tip_names):
    """Find MRCA and its parent (second MRCA) for a set of tip names."""
    terminals = []
    for tip_name in tip_names:
        for terminal in tree.get_terminals():
            if tip_name in terminal.name:
                terminals.append(terminal)
                break
    
    if not terminals:
        return None, None
    
    if len(terminals) == 1:
        path = tree.get_path(terminals[0])
        if len(path) >= 2:
            mrca = path[-2]
            parent = path[-3] if len(path) >= 3 else None
            return mrca, parent
        return None, None
    
    mrca = tree.common_ancestor(terminals)
    # Find parent of MRCA
    parent = None
    for clade in tree.find_clades():
        if mrca in clade.clades:
            parent = clade
            break
    
    return mrca, parent

def main():
    if len(sys.argv) != 5:
        print("Usage: extract_clade_mrcas.py <tree.nwk> <cluster.csv> <ancestral.fasta> <output.fasta>")
        sys.exit(1)

    tree_file, cluster_csv, ancestral_fasta, output_fasta = sys.argv[1:5]

    tree = Phylo.read(tree_file, "newick")
    
    # Label internal nodes
    for i, node in enumerate(tree.get_nonterminals(), 1):
        if not node.name:
            node.name = f"Node{i}"

    clusters = parse_cluster_csv(cluster_csv)
    all_ancestral = {rec.id: rec for rec in SeqIO.parse(ancestral_fasta, "fasta")}
    
    output_seqs = []
    for cluster_id, seq_ids in sorted(clusters.items()):
        mrca, parent = find_mrca_and_parent(tree, seq_ids)
        
        # Collect nodes: MRCA and parent (second MRCA)
        nodes_to_extract = []
        if mrca and mrca.name:
            nodes_to_extract.append((mrca.name, "MRCA"))
        if parent and parent.name:
            nodes_to_extract.append((parent.name, "MRCA2"))
        
        for node_name, label in nodes_to_extract:
            if node_name in all_ancestral:
                rec = all_ancestral[node_name]
                rec.id = f"{node_name}|cluster_{cluster_id}_{label}"
                rec.description = ""
                output_seqs.append(rec)
                print(f"Cluster {cluster_id}: {node_name} ({label})")

    SeqIO.write(output_seqs, output_fasta, "fasta")
    print(f"\nWrote {len(output_seqs)} sequences to {output_fasta}")

if __name__ == "__main__":
    main()
