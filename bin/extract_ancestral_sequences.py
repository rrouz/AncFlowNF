#!/usr/bin/env python3
"""
Extract ancestral sequences from IQ-TREE .state file to FASTA format.
"""

import sys
from collections import defaultdict

def parse_state_file(state_file):
    """Parse IQ-TREE .state file and extract most likely ancestral sequences."""
    sequences = defaultdict(list)
    
    with open(state_file, 'r') as f:
        for line in f:
            # Skip comments and header
            if line.startswith('#') or line.startswith('Node\t'):
                continue
                
            parts = line.strip().split('\t')
            if len(parts) < 3:
                continue
            
            try:
                node = parts[0]
                site = int(parts[1])
                state = parts[2]  # Most likely amino acid
                sequences[node].append((site, state))
            except (ValueError, IndexError):
                continue
    
    # Sort by site and create sequences
    fasta_sequences = {}
    for node, sites in sequences.items():
        sites.sort(key=lambda x: x[0])
        seq = ''.join([state for _, state in sites])
        fasta_sequences[node] = seq
    
    return fasta_sequences

def write_fasta(sequences, output_file):
    """Write sequences to FASTA format."""
    with open(output_file, 'w') as f:
        for node, seq in sorted(sequences.items()):
            f.write(f">{node}\n")
            # Write in 80 character lines
            for i in range(0, len(seq), 80):
                f.write(seq[i:i+80] + '\n')

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_ancestral_sequences.py <state_file> [output.fasta]")
        sys.exit(1)
    
    state_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "ancestral_sequences.fasta"
    
    print(f"Parsing {state_file}...")
    sequences = parse_state_file(state_file)
    
    print(f"Found {len(sequences)} ancestral nodes")
    print(f"Writing sequences to {output_file}...")
    write_fasta(sequences, output_file)
    
    print("Done!")
    print(f"\nSummary:")
    for node in sorted(sequences.keys())[:5]:
        print(f"  {node}: {len(sequences[node])} amino acids")
    if len(sequences) > 5:
        print(f"  ... and {len(sequences) - 5} more nodes")

if __name__ == "__main__":
    main()

