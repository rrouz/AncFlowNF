process AUTOPHY {
    tag "autophy"
    label 'process_high'
   
    input:
    path nwk
    
    output:
    path 'autophy/', emit: autophy_dir
    path 'autophy_success.txt', emit: flag
    path 'autophy/**', emit: autophy_outputs, optional: true
    path "versions.yml", emit: versions
    
    script:
    """
    echo "Running Autophy..."
    
    # Convert Newick to NEXUS format for AutoPhy
    python <<'EOF'
import dendropy
tree = dendropy.Tree.get(path="${nwk}", schema="newick", preserve_underscores=True)
tree.write(path="tree.nexus", schema="nexus")
EOF
    
    autophy -t tree.nexus \\
        -id autophy \\
        -d ${params.autophy_mode} \\
        -o clustered
    
    # Autophy creates 'output' directory, rename it to 'autophy'
    if [ -d "output" ]; then
        mv output autophy
    fi
    
    # Copy raw AutoPhy outputs to results/autophy
    mkdir -p ${params.outdir}/autophy
    cp -r autophy/* ${params.outdir}/autophy/ 2>/dev/null || true
    
    touch autophy_success.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        autophy: "latest"
    END_VERSIONS
    """

    stub:
    """
    mkdir -p autophy
    touch autophy_success.txt
    touch autophy/test.tree
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        autophy: "latest"
    END_VERSIONS
    """
}

