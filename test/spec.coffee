#!/usr/bin/env coffee
module.exports =

# Target element.
"#one":
    # DOM checks.
    "dom":
        ".header h3":
            "text": "mRNA subcellular localisation (fly-FISH)"
    
    # Click events.
    "click":
        # Selector for the target.
        ".btn.view-all":
            # Console log response.
            "log":
                "model":
                    "name": "genomic"
                "select": [
                    "Gene.primaryIdentifier"
                    "Gene.secondaryIdentifier"
                    "Gene.name"
                    "Gene.organism.name"
                    "Gene.mRNAExpressionResults.stageRange"
                    "Gene.mRNAExpressionResults.expressed"
                ]
                "constraintLogic": "A and B and C"
                "where": [
                    "path": "Gene"
                    "op": "IN"
                    "code": "A"
                    "value": "demo-genes"
                ]
    
# Target element.
"#two":
    # DOM checks.
    "dom":
        ".header h3":
            "text": "Pathway Enrichment"
        "select[name=errorCorrection] option":
            "text": [
                'Holm-Bonferroni'
                'Benjamini Hochberg'
                'Bonferroni'
                'None'
            ]
        "select[name=pValue] option":
            "text": [
                '0.05'
                '0.10'
                '1.00'
            ]
        "select[name=DataSet] option":
            "text": [
                'All'
                'KEGG pathways data set'
                'Reactome data set'
            ]
        ".background .popover table tr td a":
            "text": [
                'Default'
                'copy'
                'demo-genes'
                'some genes fbgn'
            ]
        "table.table tbody tr td.description":
            "text": [
                'TGF-beta signaling pathway'
            ]
    
# Target element.
"#three":
    # DOM checks.
    "dom":
        ".header h3":
            "text": "Orthologues"
        "table.table tbody tr":
            "text": [
                'Drosophila erecta24'
                'Drosophila virilis24'
                'Drosophila ananassae23'
                'Drosophila grimshawi23'
                'Drosophila mojavensis23'
                'Drosophila persimilis23'
                'Drosophila pseudoobscura23'
                'Drosophila sechellia23'
                'Drosophila willistoni23'
                'Drosophila yakuba23'
                'Anopheles gambiae19'
                'Drosophila simulans18'
                'Danio rerio16'
                'Homo sapiens16'
                'Mus musculus16'
                'Rattus norvegicus14'
                'Caenorhabditis elegans13'
                'Saccharomyces cerevisiae3'
            ]