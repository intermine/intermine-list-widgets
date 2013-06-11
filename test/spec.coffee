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
                    "value": "demo-list"
                ]
    
# Target element.
"#two":
    # DOM checks.
    "dom":
        ".header h3":
            "text": "Protein Domain Enrichment"
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
        "table.table tbody tr td.description":
            "text": [
                'Homeobox, conserved site [IPR017970]'
                'Homeodomain [IPR001356]'
                'Homeodomain-like [IPR009057]'
                'MAD homology, MH1 [IPR013019]'
                'Dwarfin [IPR013790]'
                'MAD homology 1, Dwarfin-type [IPR003619]'
                'SMAD domain, Dwarfin-type [IPR001132]'
                'SMAD domain-like [IPR017855]'
            ]
    
# Target element.
"#three":
    # DOM checks.
    "dom":
        ".header h3":
            "text": "Orthologues"
        "table.table tbody tr":
            "text": [
                "Drosophila melanogaster23"
                "Drosophila sechellia23"
                "Drosophila yakuba23"
                "Drosophila erecta22"
                "Danio rerio21"
                "Drosophila ananassae21"
                "Homo sapiens21"
                "Mus musculus21"
                "Rattus norvegicus21"
                "Drosophila grimshawi20"
                "Drosophila mojavensis20"
                "Drosophila persimilis20"
                "Drosophila pseudoobscura20"
                "Drosophila virilis20"
                "Drosophila willistoni20"
                "Anopheles gambiae19"
                "Caenorhabditis elegans19"
                "Drosophila simulans19"
                "Saccharomyces cerevisiae3"
            ]