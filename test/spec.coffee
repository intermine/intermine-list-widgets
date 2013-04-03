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
    
# Target element.
"#three":
    # DOM checks.
    "dom":
        ".header h3":
            "text": "Orthologues"