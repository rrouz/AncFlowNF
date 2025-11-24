process IQTREE {
    tag "iqtree"
    label 'process_high'
   
    input:
    path alignment
    
    output:
    path 'IQ-TREE_output.treefile', emit: treefile
    path 'IQ-TREE_output.*', emit: all_outputs
    path "versions.yml", emit: versions
    
    script:
    """
    iqtree -s ${alignment} \\
        -m ${params.iqtree_model} \\
        -bb ${params.iqtree_bootstrap} \\
        -nt AUTO \\
        -pre IQ-TREE_output
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(iqtree -version 2>&1 | head -n1 | sed 's/IQ-TREE //')
    END_VERSIONS
    """

    stub:
    """
    touch IQ-TREE_output.treefile
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(iqtree -version 2>&1 | head -n1 | sed 's/IQ-TREE //' || echo "unknown")
    END_VERSIONS
    """
}

