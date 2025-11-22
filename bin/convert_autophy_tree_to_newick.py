#!/usr/bin/env python3
"""
Convert AutoPhy NEXUS tree to clean Newick format for IQ-TREE ASR.
The AutoPhy tree has cluster IDs in leaf names which we want to preserve.
"""

import sys
import dendropy

def convert_autophy_tree_to_newick(nexus_file, newick_file):
    """
    Convert AutoPhy NEXUS format tree to clean Newick for IQ-TREE.
    Removes underscore wrapping and outputs unquoted taxon names.
    """
    try:
        # Read tree - try NEXUS first, then Newick
        try:
            tree = dendropy.Tree.get(path=nexus_file, schema="nexus", preserve_underscores=True)
        except:
            tree = dendropy.Tree.get(path=nexus_file, schema="newick", preserve_underscores=True)
        
        # Clean up taxon labels - remove leading/trailing underscores
        for node in tree.leaf_node_iter():
            if node.taxon and node.taxon.label:
                label = node.taxon.label
                # Remove leading and trailing underscores
                label = label.strip('_')
                node.taxon.label = label
        
        # Write as Newick without quotes (suppress_leaf_taxon_labels=False means write them)
        tree.write(path=newick_file, 
                  schema="newick",
                  suppress_rooting=True,
                  unquoted_underscores=True,
                  suppress_leaf_taxon_labels=False,
                  suppress_leaf_node_labels=True)
        
        print(f"Converted AutoPhy tree to Newick format")
        print(f"Output: {newick_file}")
        
    except Exception as e:
        print(f"Error converting tree: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) != 3:
        print("Usage: convert_autophy_tree_to_newick.py <autophy.tree> <output.nwk>")
        sys.exit(1)
    
    nexus_file = sys.argv[1]
    newick_file = sys.argv[2]
    
    convert_autophy_tree_to_newick(nexus_file, newick_file)

if __name__ == "__main__":
    main()

