#!/usr/bin/env python3
"""Restore original FASTA headers using mapping file."""

import sys
import json

def main(input_fasta: str, mapping_file: str, output_fasta: str):
    with open(mapping_file) as f:
        mapping = json.load(f)
    
    restored = 0
    with open(input_fasta) as fin, open(output_fasta, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                sanitized = line.strip()[1:]
                original = mapping.get(sanitized, sanitized)
                fout.write(f">{original}\n")
                restored += 1
            else:
                fout.write(line)
    
    print(f"Restored {restored} headers")

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input.fasta> <mapping.json> <output.fasta>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3])
