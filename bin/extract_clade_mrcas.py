#!/usr/bin/env python3
"""
Extracts only the Most Recent Common Ancestor (MRCA) sequences for each clade.
Filters the full ancestral sequences to keep only immediate ancestral nodes.
"""

import sys
import csv
from collections import defaultdict
from Bio import SeqIO, Phylo
from io import StringIO

def parse_cluster_csv(cluster_csv):
    """Parse AutoPhy cluster CSV and get sequences per cluster."""
    clusters = defaultdict(list)
    with open(cluster_csv, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            seq_id = row['Label']
            cluster_id = row['Cluster']
            clusters[cluster_id].append(seq_id)
    return clusters

def find_mrca_node(tree, tip_names):
    """Find the MRCA node for a set of tip names."""
    # Get all terminal nodes matching our tip names
    terminals = []
    for tip_name in tip_names:
        # Find terminal that matches (handle the full header with cluster ID)
        found = False
        for terminal in tree.get_terminals():
            # Check if the tip_name is in the terminal name
            if tip_name in terminal.name:
                terminals.append(terminal)
                found = True
                break
        if not found:
            print(f"Warning: Could not find tip '{tip_name}' in tree", file=sys.stderr)
    
    if len(terminals) == 0:
        return None
    elif len(terminals) == 1:
        # Single sequence cluster - return its parent
        parent = tree.get_path(terminals[0])
        if len(parent) > 1:
            return parent[-2]  # Return parent node
        return None
    
    # Find MRCA of multiple terminals
    mrca = tree.common_ancestor(terminals)
    return mrca

def get_node_name(node):
    """Get the name of a node (for internal nodes)."""
    if node.name:
        return node.name
    # If no name, try to find it by confidence value or return None
    return None

def main():
    if len(sys.argv) != 5:
        print("Usage: python extract_clade_mrcas.py <tree.nwk> <cluster.csv> <all_ancestral.fasta> <output_mrca.fasta>")
        sys.exit(1)

    tree_file = sys.argv[1]
    cluster_csv = sys.argv[2]
    ancestral_fasta = sys.argv[3]
    output_fasta = sys.argv[4]

    print(f"Loading tree from: {tree_file}")
    tree = Phylo.read(tree_file, "newick")
    
    # Label internal nodes if they don't have names
    node_counter = 1
    for node in tree.get_nonterminals():
        if not node.name or node.name == '':
            node.name = f"Node{node_counter}"
            node_counter += 1

    print(f"Parsing clusters from: {cluster_csv}")
    clusters = parse_cluster_csv(cluster_csv)
    print(f"Found {len(clusters)} clusters")

    # Find MRCA for each cluster
    mrca_nodes = {}
    for cluster_id, seq_ids in clusters.items():
        print(f"\nCluster {cluster_id}: {len(seq_ids)} sequences")
        mrca = find_mrca_node(tree, seq_ids)
        if mrca:
            node_name = get_node_name(mrca)
            if node_name:
                mrca_nodes[cluster_id] = node_name
                print(f"  MRCA: {node_name}")
            else:
                print(f"  Warning: MRCA found but has no name")
        else:
            print(f"  Warning: Could not find MRCA")

    # Read all ancestral sequences
    print(f"\nReading ancestral sequences from: {ancestral_fasta}")
    all_ancestral = {rec.id: rec for rec in SeqIO.parse(ancestral_fasta, "fasta")}
    print(f"Total ancestral sequences: {len(all_ancestral)}")

    # Extract only MRCA sequences
    mrca_sequences = []
    for cluster_id, node_name in sorted(mrca_nodes.items()):
        if node_name in all_ancestral:
            record = all_ancestral[node_name]
            # Add cluster info to description
            record.description = f"cluster_{cluster_id}_MRCA"
            mrca_sequences.append(record)
            print(f"Extracted: {node_name} (cluster {cluster_id})")
        else:
            print(f"Warning: Node {node_name} not found in ancestral sequences", file=sys.stderr)

    # Write filtered sequences
    print(f"\nWriting {len(mrca_sequences)} MRCA sequences to: {output_fasta}")
    SeqIO.write(mrca_sequences, output_fasta, "fasta")
    print("Done!")

if __name__ == "__main__":
    main()

