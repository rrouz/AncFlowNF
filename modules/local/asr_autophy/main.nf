process ASR_AUTOPHY {
    tag "asr_autophy"
    label 'process_high'
   
    input:
    path alignment
    path autophy_dir
    
    output:
    path 'asr_complete.txt', emit: flag
    path 'ancestral_autophy.*', emit: asr_outputs
    path 'ancestral_autophy_sequences.fasta', emit: ancestral_fasta_all
    path 'clade_mrca_sequences.fasta', emit: ancestral_fasta_mrca
    path 'alignment_clustered.fasta', emit: clustered_alignment
    path 'autophy_tree.nwk', emit: tree
    path "versions.yml", emit: versions
    
    script:
    """
    # Find AutoPhy outputs using glob patterns
    CLUSTER_CSV=\$(ls ${autophy_dir}/*colored_RF.csv 2>/dev/null | head -1)
    TREE_FILE=\$(ls ${autophy_dir}/*.tree 2>/dev/null | head -1)
    
    if [ -z "\$CLUSTER_CSV" ] || [ -z "\$TREE_FILE" ]; then
        echo "Error: Could not find AutoPhy cluster CSV or tree file"
        echo "Contents of autophy directory:"
        ls -la ${autophy_dir}/
        exit 1
    fi
    
    echo "Found cluster CSV: \$CLUSTER_CSV"
    echo "Found tree file: \$TREE_FILE"
    
    # Step 1: Add cluster IDs to alignment headers
    python ${params.bin_dir}/add_cluster_ids_to_alignment.py \\
        ${alignment} \\
        \$CLUSTER_CSV \\
        alignment_clustered.fasta
    
    # Step 2: Convert AutoPhy tree to Newick format
    python ${params.bin_dir}/convert_autophy_tree_to_newick.py \\
        \$TREE_FILE \\
        autophy_tree.nwk
    
    # Step 3: Run IQ-TREE ancestral sequence reconstruction
    iqtree \\
        -s alignment_clustered.fasta \\
        -te autophy_tree.nwk \\
        --ancestral \\
        --prefix ancestral_autophy \\
        -nt AUTO
    
    # Step 4: Extract all ancestral sequences from .state file to FASTA
    python ${params.bin_dir}/extract_ancestral_sequences.py \\
        ancestral_autophy.state \\
        ancestral_autophy_sequences.fasta
    
    # Step 5: Extract MRCA and second MRCA (parent) sequences for each clade
    python ${params.bin_dir}/extract_clade_mrcas.py \\
        autophy_tree.nwk \\
        \$CLUSTER_CSV \\
        ancestral_autophy_sequences.fasta \\
        clade_mrca_sequences.fasta
    
    touch asr_complete.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(iqtree --version 2>&1 | head -n1 | awk '{print \$NF}')
        python: \$(python --version | sed 's/Python //g')
        biopython: \$(python -c "import Bio; print(Bio.__version__)" 2>/dev/null || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    touch asr_complete.txt
    touch ancestral_autophy.state
    touch ancestral_autophy_sequences.fasta
    touch clade_mrca_sequences.fasta
    touch alignment_clustered.fasta
    touch autophy_tree.nwk
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(iqtree --version 2>&1 | head -n1 | awk '{print \$NF}' || echo "unknown")
        python: \$(python --version | sed 's/Python //g' || echo "unknown")
        biopython: "unknown"
    END_VERSIONS
    """
}

