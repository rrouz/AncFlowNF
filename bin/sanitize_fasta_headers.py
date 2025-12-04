#!/usr/bin/env python3
"""Sanitize FASTA headers for iq-tree/autophy compatibility.
Creates mapping file to restore originals later.
"""

import re
import sys
import json
from pathlib import Path

def sanitize_header(header: str) -> str:
    """Convert header to safe format: alphanumeric + underscore only."""
    # Remove leading '>' if present
    clean = header.lstrip('>')
    # Replace problematic chars with underscore, collapse multiples
    sanitized = re.sub(r'[^a-zA-Z0-9]', '_', clean)
    sanitized = re.sub(r'_+', '_', sanitized).strip('_')
    return sanitized

def main(input_fasta: str, output_fasta: str, mapping_file: str):
    mapping = {}
    seen = {}
    
    with open(input_fasta) as fin, open(output_fasta, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                original = line.strip()[1:]  # Remove '>'
                sanitized = sanitize_header(original)
                
                # Handle duplicates by appending counter
                if sanitized in seen:
                    seen[sanitized] += 1
                    sanitized = f"{sanitized}_{seen[sanitized]}"
                else:
                    seen[sanitized] = 0
                
                mapping[sanitized] = original
                fout.write(f">{sanitized}\n")
            else:
                fout.write(line)
    
    with open(mapping_file, 'w') as f:
        json.dump(mapping, f, indent=2)
    
    print(f"Sanitized {len(mapping)} sequences")

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input.fasta> <output.fasta> <mapping.json>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3])
