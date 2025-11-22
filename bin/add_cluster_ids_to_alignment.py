#!/usr/bin/env python3
"""
Add cluster IDs from AutoPhy CSV to alignment sequence headers.
Maps sequences to their cluster assignments.
"""

import sys
import csv
from Bio import SeqIO

def parse_cluster_assignments(csv_file):
    """Parse AutoPhy cluster assignments from CSV."""
    clusters = {}
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            label = row['Label']
            cluster = row['Cluster']
            clusters[label] = cluster
    return clusters

def add_cluster_ids(alignment_file, cluster_file, output_file):
    """Add cluster IDs to alignment sequence headers."""
    # Parse cluster assignments
    clusters = parse_cluster_assignments(cluster_file)
    
    # Read alignment and modify headers
    modified_sequences = []
    matched = 0
    unmatched = 0
    
    for record in SeqIO.parse(alignment_file, "fasta"):
        original_id = record.id
        
        # Try to find cluster assignment
        cluster_id = clusters.get(original_id, None)
        
        if cluster_id is not None:
            # Add cluster ID to the header
            record.id = f"{original_id}|{cluster_id}"
            record.description = f"{original_id}|{cluster_id}"
            matched += 1
        else:
            # Keep original if not found
            unmatched += 1
            print(f"Warning: No cluster found for {original_id}")
        
        modified_sequences.append(record)
    
    # Write modified alignment
    SeqIO.write(modified_sequences, output_file, "fasta")
    
    print(f"Processed {len(modified_sequences)} sequences")
    print(f"  Matched: {matched}")
    print(f"  Unmatched: {unmatched}")
    print(f"Written to: {output_file}")

def main():
    if len(sys.argv) != 4:
        print("Usage: add_cluster_ids_to_alignment.py <alignment.fasta> <clusters.csv> <output.fasta>")
        sys.exit(1)
    
    alignment_file = sys.argv[1]
    cluster_file = sys.argv[2]
    output_file = sys.argv[3]
    
    add_cluster_ids(alignment_file, cluster_file, output_file)

if __name__ == "__main__":
    main()

