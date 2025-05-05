﻿# Module d'analyse des workflows n8n
# Ce module fournit des fonctions pour analyser les workflows n8n,
# dÃ©tecter les activitÃ©s, extraire les transitions et analyser les conditions.

#Requires -Version 5.1

# Fonction pour charger un workflow n8n depuis un fichier JSON
function Get-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath
    )

    try {
        # Lire le contenu du fichier JSON
        $workflowContent = Get-Content -Path $WorkflowPath -Raw -Encoding UTF8

        # Convertir le contenu JSON en objet PowerShell
        $workflow = $workflowContent | ConvertFrom-Json

        # VÃ©rifier si le workflow est valide
        if (-not $workflow.nodes -or -not $workflow.connections) {
            Write-Error "Le fichier ne contient pas un workflow n8n valide."
            return $null
        }

        return $workflow
    } catch {
        Write-Error "Erreur lors du chargement du workflow: $_"
        return $null
    }
}

# Fonction pour dÃ©tecter les activitÃ©s d'un workflow n8n
function Get-N8nWorkflowActivities {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $activities = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # CrÃ©er un objet pour reprÃ©senter l'activitÃ©
                $activity = [PSCustomObject]@{
                    Id       = $node.id
                    Name     = $node.name
                    Type     = $node.type
                    Position = $node.position
                    Category = Get-NodeCategory -NodeType $node.type
                }

                # Ajouter des dÃ©tails si demandÃ©
                if ($IncludeDetails) {
                    $activity | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $node.parameters
                    $activity | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion

                    # Ajouter les connexions entrantes et sortantes
                    $incomingConnections = @()
                    $outgoingConnections = @()

                    foreach ($sourceNode in $Workflow.connections.PSObject.Properties.Name) {
                        foreach ($connection in $Workflow.connections.$sourceNode.main) {
                            foreach ($target in $connection) {
                                if ($target.node -eq $node.id) {
                                    $incomingConnections += [PSCustomObject]@{
                                        SourceNode  = $sourceNode
                                        SourceIndex = $target.index
                                    }
                                }
                            }
                        }
                    }

                    if ($Workflow.connections.$($node.id)) {
                        foreach ($connection in $Workflow.connections.$($node.id).main) {
                            foreach ($target in $connection) {
                                $outgoingConnections += [PSCustomObject]@{
                                    TargetNode  = $target.node
                                    TargetIndex = $target.index
                                }
                            }
                        }
                    }

                    $activity | Add-Member -MemberType NoteProperty -Name "IncomingConnections" -Value $incomingConnections
                    $activity | Add-Member -MemberType NoteProperty -Name "OutgoingConnections" -Value $outgoingConnections
                }

                # Ajouter l'activitÃ© aux rÃ©sultats
                $activities += $activity
            }

            return $activities
        } catch {
            Write-Error "Erreur lors de la dÃ©tection des activitÃ©s: $_"
            return $null
        }
    }
}

# Fonction pour extraire les transitions d'un workflow n8n
function Get-N8nWorkflowTransitions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNodeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes -or -not $Workflow.connections) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $transitions = @()

            # CrÃ©er un dictionnaire pour accÃ©der rapidement aux nÅ“uds par ID
            $nodesById = @{}
            foreach ($node in $Workflow.nodes) {
                $nodesById[$node.id] = $node
            }

            # Analyser chaque connexion du workflow
            foreach ($sourceNodeId in $Workflow.connections.PSObject.Properties.Name) {
                $sourceNode = $nodesById[$sourceNodeId]

                foreach ($connectionArray in $Workflow.connections.$sourceNodeId.main) {
                    foreach ($connection in $connectionArray) {
                        $targetNode = $nodesById[$connection.node]

                        # CrÃ©er un objet pour reprÃ©senter la transition
                        $transition = [PSCustomObject]@{
                            SourceNodeId   = $sourceNodeId
                            SourceNodeName = $sourceNode.name
                            SourceNodeType = $sourceNode.type
                            TargetNodeId   = $connection.node
                            TargetNodeName = $targetNode.name
                            TargetNodeType = $targetNode.type
                            OutputIndex    = $connection.index
                        }

                        # Ajouter des dÃ©tails si demandÃ©
                        if ($IncludeNodeDetails) {
                            $transition | Add-Member -MemberType NoteProperty -Name "SourceNode" -Value $sourceNode
                            $transition | Add-Member -MemberType NoteProperty -Name "TargetNode" -Value $targetNode
                        }

                        # Ajouter la transition aux rÃ©sultats
                        $transitions += $transition
                    }
                }
            }

            return $transitions
        } catch {
            Write-Error "Erreur lors de l'extraction des transitions: $_"
            return $null
        }
    }
}

# Fonction pour analyser les conditions d'un workflow n8n
function Get-N8nWorkflowConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTransitions
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $conditions = @()

            # CrÃ©er un dictionnaire pour accÃ©der rapidement aux nÅ“uds par ID
            $nodesById = @{}
            foreach ($node in $Workflow.nodes) {
                $nodesById[$node.id] = $node
            }

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un nÅ“ud conditionnel
                if ($node.type -eq "n8n-nodes-base.if" -or $node.type -eq "n8n-nodes-base.switch") {
                    # Extraire les conditions
                    $conditionDetails = @()

                    if ($node.type -eq "n8n-nodes-base.if") {
                        # NÅ“ud IF
                        if ($node.parameters.conditions) {
                            foreach ($conditionType in $node.parameters.conditions.PSObject.Properties.Name) {
                                foreach ($condition in $node.parameters.conditions.$conditionType) {
                                    $conditionDetails += [PSCustomObject]@{
                                        Type      = $conditionType
                                        Value1    = $condition.value1
                                        Operation = $condition.operation
                                        Value2    = $condition.value2
                                    }
                                }
                            }
                        }
                    } elseif ($node.type -eq "n8n-nodes-base.switch") {
                        # NÅ“ud Switch
                        if ($node.parameters.rules) {
                            foreach ($rule in $node.parameters.rules) {
                                $conditionDetails += [PSCustomObject]@{
                                    Type      = "switch"
                                    Value1    = $node.parameters.value
                                    Operation = $rule.operation
                                    Value2    = $rule.value
                                    Output    = $rule.output
                                }
                            }
                        }
                    }

                    # CrÃ©er un objet pour reprÃ©senter le nÅ“ud conditionnel
                    $conditionNode = [PSCustomObject]@{
                        Id         = $node.id
                        Name       = $node.name
                        Type       = $node.type
                        Conditions = $conditionDetails
                    }

                    # Ajouter les transitions si demandÃ©
                    if ($IncludeTransitions -and $Workflow.connections.$($node.id)) {
                        $transitions = @()

                        foreach ($outputIndex in 0..($Workflow.connections.$($node.id).main.Count - 1)) {
                            $outputLabel = if ($node.type -eq "n8n-nodes-base.if") {
                                if ($outputIndex -eq 0) { "true" } else { "false" }
                            } else {
                                "output$outputIndex"
                            }

                            foreach ($connection in $Workflow.connections.$($node.id).main[$outputIndex]) {
                                $targetNode = $nodesById[$connection.node]

                                $transitions += [PSCustomObject]@{
                                    OutputIndex    = $outputIndex
                                    OutputLabel    = $outputLabel
                                    TargetNodeId   = $connection.node
                                    TargetNodeName = $targetNode.name
                                    TargetNodeType = $targetNode.type
                                }
                            }
                        }

                        $conditionNode | Add-Member -MemberType NoteProperty -Name "Transitions" -Value $transitions
                    }

                    # Ajouter le nÅ“ud conditionnel aux rÃ©sultats
                    $conditions += $conditionNode
                }
            }

            return $conditions
        } catch {
            Write-Error "Erreur lors de l'analyse des conditions: $_"
            return $null
        }
    }
}

# Fonction pour gÃ©nÃ©rer un rapport d'analyse d'un workflow n8n
function Get-N8nWorkflowAnalysisReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "HTML", "Markdown")]
        [string]$Format = "Markdown"
    )

    try {
        # Charger le workflow
        $workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath

        if (-not $workflow) {
            Write-Error "Impossible de charger le workflow."
            return
        }

        # Analyser le workflow
        $activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails
        $transitions = Get-N8nWorkflowTransitions -Workflow $workflow
        $conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions

        # CrÃ©er le rapport
        $report = ""

        switch ($Format) {
            "Markdown" {
                $report = "# Rapport d'analyse du workflow: $($workflow.name)`n`n"

                # Informations gÃ©nÃ©rales
                $report += "## Informations gÃ©nÃ©rales`n`n"
                $report += "- **Nom**: $($workflow.name)`n"
                $report += "- **ID**: $($workflow.id)`n"
                $report += "- **Actif**: $($workflow.active)`n"
                $report += "- **Nombre de noeuds**: $($workflow.nodes.Count)`n"
                $report += "- **Nombre de connexions**: $($transitions.Count)`n`n"

                # ActivitÃ©s
                $report += "## ActivitÃ©s`n`n"
                $report += "| ID | Nom | Type | CatÃ©gorie |`n"
                $report += "|----|-----|------|-----------|`n"
                foreach ($activity in $activities) {
                    $report += "| $($activity.Id) | $($activity.Name) | $($activity.Type) | $($activity.Category) |`n"
                }
                $report += "`n"

                # Transitions
                $report += "## Transitions`n`n"
                $report += "| Source | Destination | Index |`n"
                $report += "|--------|-------------|-------|`n"
                foreach ($transition in $transitions) {
                    $report += "| $($transition.SourceNodeName) | $($transition.TargetNodeName) | $($transition.OutputIndex) |`n"
                }
                $report += "`n"

                # Conditions
                $report += "## Conditions`n`n"
                foreach ($condition in $conditions) {
                    $report += "### $($condition.Name)`n`n"
                    $report += "- **Type**: $($condition.Type)`n"
                    $report += "- **Conditions**:`n`n"

                    $report += "| Type | Valeur 1 | OpÃ©ration | Valeur 2 |`n"
                    $report += "|------|----------|-----------|----------|`n"
                    foreach ($cond in $condition.Conditions) {
                        $report += "| $($cond.Type) | $($cond.Value1) | $($cond.Operation) | $($cond.Value2) |`n"
                    }

                    if ($condition.Transitions) {
                        $report += "`n- **Transitions**:`n`n"
                        $report += "| Sortie | Label | Destination |`n"
                        $report += "|--------|-------|-------------|`n"
                        foreach ($transition in $condition.Transitions) {
                            $report += "| $($transition.OutputIndex) | $($transition.OutputLabel) | $($transition.TargetNodeName) |`n"
                        }
                    }

                    $report += "`n"
                }
            }
            "JSON" {
                $reportObj = [PSCustomObject]@{
                    WorkflowName    = $workflow.name
                    WorkflowId      = $workflow.id
                    Active          = $workflow.active
                    NodeCount       = $workflow.nodes.Count
                    ConnectionCount = $transitions.Count
                    Activities      = $activities
                    Transitions     = $transitions
                    Conditions      = $conditions
                }

                $report = $reportObj | ConvertTo-Json -Depth 10
            }
            "HTML" {
                # ImplÃ©mentation HTML simplifiÃ©e
                $report = "<html><head><title>Rapport d'analyse du workflow: $($workflow.name)</title></head><body>"
                $report += "<h1>Rapport d'analyse du workflow: $($workflow.name)</h1>"

                # Informations gÃ©nÃ©rales
                $report += "<h2>Informations gÃ©nÃ©rales</h2>"
                $report += "<ul>"
                $report += "<li><strong>Nom</strong>: $($workflow.name)</li>"
                $report += "<li><strong>ID</strong>: $($workflow.id)</li>"
                $report += "<li><strong>Actif</strong>: $($workflow.active)</li>"
                $report += "<li><strong>Nombre de noeuds</strong>: $($workflow.nodes.Count)</li>"
                $report += "<li><strong>Nombre de connexions</strong>: $($transitions.Count)</li>"
                $report += "</ul>"

                # ActivitÃ©s
                $report += "<h2>ActivitÃ©s</h2>"
                $report += "<table border='1'><tr><th>ID</th><th>Nom</th><th>Type</th><th>CatÃ©gorie</th></tr>"
                foreach ($activity in $activities) {
                    $report += "<tr><td>$($activity.Id)</td><td>$($activity.Name)</td><td>$($activity.Type)</td><td>$($activity.Category)</td></tr>"
                }
                $report += "</table>"

                # Transitions
                $report += "<h2>Transitions</h2>"
                $report += "<table border='1'><tr><th>Source</th><th>Destination</th><th>Index</th></tr>"
                foreach ($transition in $transitions) {
                    $report += "<tr><td>$($transition.SourceNodeName)</td><td>$($transition.TargetNodeName)</td><td>$($transition.OutputIndex)</td></tr>"
                }
                $report += "</table>"

                # Conditions
                $report += "<h2>Conditions</h2>"
                foreach ($condition in $conditions) {
                    $report += "<h3>$($condition.Name)</h3>"
                    $report += "<p><strong>Type</strong>: $($condition.Type)</p>"
                    $report += "<p><strong>Conditions</strong>:</p>"

                    $report += "<table border='1'><tr><th>Type</th><th>Valeur 1</th><th>OpÃ©ration</th><th>Valeur 2</th></tr>"
                    foreach ($cond in $condition.Conditions) {
                        $report += "<tr><td>$($cond.Type)</td><td>$($cond.Value1)</td><td>$($cond.Operation)</td><td>$($cond.Value2)</td></tr>"
                    }
                    $report += "</table>"

                    if ($condition.Transitions) {
                        $report += "<p><strong>Transitions</strong>:</p>"
                        $report += "<table border='1'><tr><th>Sortie</th><th>Label</th><th>Destination</th></tr>"
                        foreach ($transition in $condition.Transitions) {
                            $report += "<tr><td>$($transition.OutputIndex)</td><td>$($transition.OutputLabel)</td><td>$($transition.TargetNodeName)</td></tr>"
                        }
                        $report += "</table>"
                    }
                }

                $report += "</body></html>"
            }
            "Text" {
                $report = "Rapport d'analyse du workflow: $($workflow.name)`r`n`r`n"

                # Informations gÃ©nÃ©rales
                $report += "Informations gÃ©nÃ©rales:`r`n"
                $report += "- Nom: $($workflow.name)`r`n"
                $report += "- ID: $($workflow.id)`r`n"
                $report += "- Actif: $($workflow.active)`r`n"
                $report += "- Nombre de noeuds: $($workflow.nodes.Count)`r`n"
                $report += "- Nombre de connexions: $($transitions.Count)`r`n`r`n"

                # ActivitÃ©s
                $report += "ActivitÃ©s:`r`n"
                foreach ($activity in $activities) {
                    $report += "- $($activity.Name) (ID: $($activity.Id), Type: $($activity.Type), CatÃ©gorie: $($activity.Category))`r`n"
                }
                $report += "`r`n"

                # Transitions
                $report += "Transitions:`r`n"
                foreach ($transition in $transitions) {
                    $report += "- $($transition.SourceNodeName) -> $($transition.TargetNodeName) (Index: $($transition.OutputIndex))`r`n"
                }
                $report += "`r`n"

                # Conditions
                $report += "Conditions:`r`n"
                foreach ($condition in $conditions) {
                    $report += "- $($condition.Name) (Type: $($condition.Type))`r`n"
                    $report += "  Conditions:`r`n"

                    foreach ($cond in $condition.Conditions) {
                        $report += "  - $($cond.Type): $($cond.Value1) $($cond.Operation) $($cond.Value2)`r`n"
                    }

                    if ($condition.Transitions) {
                        $report += "  Transitions:`r`n"
                        foreach ($transition in $condition.Transitions) {
                            $report += "  - $($transition.OutputIndex) ($($transition.OutputLabel)) -> $($transition.TargetNodeName)`r`n"
                        }
                    }

                    $report += "`r`n"
                }
            }
        }

        # Enregistrer le rapport si un chemin de sortie est spÃ©cifiÃ©
        if ($OutputPath) {
            $report | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "Rapport enregistrÃ© dans $OutputPath"
        }

        return $report
    } catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport: $_"
        return $null
    }
}

# Fonction utilitaire pour dÃ©terminer la catÃ©gorie d'un nÅ“ud
function Get-NodeCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NodeType
    )

    # CatÃ©goriser les nÅ“uds par type
    switch -Wildcard ($NodeType) {
        "n8n-nodes-base.start" { return "Trigger" }
        "n8n-nodes-base.manualTrigger" { return "Trigger" }
        "n8n-nodes-base.schedule*" { return "Trigger" }
        "n8n-nodes-base.webhook" { return "Trigger" }
        "n8n-nodes-base.cron" { return "Trigger" }

        "n8n-nodes-base.if" { return "Flow Control" }
        "n8n-nodes-base.switch" { return "Flow Control" }
        "n8n-nodes-base.merge" { return "Flow Control" }
        "n8n-nodes-base.splitInBatches" { return "Flow Control" }
        "n8n-nodes-base.wait" { return "Flow Control" }

        "n8n-nodes-base.set" { return "Data Operation" }
        "n8n-nodes-base.function" { return "Data Operation" }
        "n8n-nodes-base.functionItem" { return "Data Operation" }
        "n8n-nodes-base.code" { return "Data Operation" }

        "n8n-nodes-base.httpRequest" { return "API" }
        "n8n-nodes-base.webhook" { return "API" }

        "n8n-nodes-base.emailSend" { return "Communication" }
        "n8n-nodes-base.slack" { return "Communication" }
        "n8n-nodes-base.telegram" { return "Communication" }

        "n8n-nodes-base.googleSheets" { return "Integration" }
        "n8n-nodes-base.notion" { return "Integration" }
        "n8n-nodes-base.airtable" { return "Integration" }

        "n8n-nodes-base.stickyNote" { return "Documentation" }

        default { return "Other" }
    }
}

# Fonction pour dÃ©tecter les blocs try/catch/finally dans le code d'une fonction
function Get-TryCatchBlocks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FunctionCode
    )

    try {
        # Initialiser les rÃ©sultats
        $blocks = @{
            TryBlocks     = @()
            CatchBlocks   = @()
            FinallyBlocks = @()
        }

        # Rechercher les blocs try
        $tryMatches = [regex]::Matches($FunctionCode, "try\s*{([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))}")
        foreach ($match in $tryMatches) {
            $blocks.TryBlocks += [PSCustomObject]@{
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        # Rechercher les blocs catch
        $catchMatches = [regex]::Matches($FunctionCode, "catch\s*(\([^)]*\))?\s*{([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))}")
        foreach ($match in $catchMatches) {
            $blocks.CatchBlocks += [PSCustomObject]@{
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        # Rechercher les blocs finally
        $finallyMatches = [regex]::Matches($FunctionCode, "finally\s*{([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))}")
        foreach ($match in $finallyMatches) {
            $blocks.FinallyBlocks += [PSCustomObject]@{
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        return $blocks
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des blocs try/catch/finally: $_"
        return $null
    }
}

# Fonction pour dÃ©tecter les blocs trap dans le code d'une fonction
function Get-TrapBlocks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FunctionCode
    )

    try {
        # Initialiser les rÃ©sultats
        $trapBlocks = @()

        # Rechercher les blocs trap
        # Le pattern recherche "trap" suivi d'un bloc de code entre accolades
        # Optionnellement, il peut y avoir une condition entre crochets aprÃ¨s "trap"
        $trapMatches = [regex]::Matches($FunctionCode, "trap\s*(?:\[[^\]]+\])?\s*{([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))}")

        foreach ($match in $trapMatches) {
            # Extraire le type d'exception (s'il est spÃ©cifiÃ©)
            $exceptionType = ""
            $typeMatch = [regex]::Match($match.Value, "trap\s*\[([^\]]+)\]")
            if ($typeMatch.Success) {
                $exceptionType = $typeMatch.Groups[1].Value.Trim()
            }

            $trapBlocks += [PSCustomObject]@{
                Code          = $match.Value
                ExceptionType = $exceptionType
                StartIndex    = $match.Index
                EndIndex      = $match.Index + $match.Length
            }
        }

        return $trapBlocks
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des blocs trap: $_"
        return $null
    }
}

# Fonction pour analyser les blocs try/catch/finally dans un workflow n8n
function Get-N8nWorkflowTryCatchBlocks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $tryCatchNodes = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un nÅ“ud de fonction
                if ($node.type -eq "n8n-nodes-base.function" -or $node.type -eq "n8n-nodes-base.functionItem" -or $node.type -eq "n8n-nodes-base.code") {
                    # Extraire le code de la fonction
                    $functionCode = ""

                    if ($node.parameters.functionCode) {
                        $functionCode = $node.parameters.functionCode
                    } elseif ($node.parameters.jsCode) {
                        $functionCode = $node.parameters.jsCode
                    }

                    if ($functionCode) {
                        # DÃ©tecter les blocs try/catch/finally
                        $blocks = Get-TryCatchBlocks -FunctionCode $functionCode

                        if ($blocks -and ($blocks.TryBlocks.Count -gt 0 -or $blocks.CatchBlocks.Count -gt 0 -or $blocks.FinallyBlocks.Count -gt 0)) {
                            # CrÃ©er un objet pour reprÃ©senter le nÅ“ud avec des blocs try/catch/finally
                            $tryCatchNode = [PSCustomObject]@{
                                Id            = $node.id
                                Name          = $node.name
                                Type          = $node.type
                                TryBlocks     = $blocks.TryBlocks.Count
                                CatchBlocks   = $blocks.CatchBlocks.Count
                                FinallyBlocks = $blocks.FinallyBlocks.Count
                                FunctionCode  = $functionCode
                                Blocks        = $blocks
                            }

                            # Ajouter le nÅ“ud aux rÃ©sultats
                            $tryCatchNodes += $tryCatchNode
                        }
                    }
                }
            }

            return $tryCatchNodes
        } catch {
            Write-Error "Erreur lors de l'analyse des blocs try/catch/finally: $_"
            return $null
        }
    }
}

# Fonction pour analyser les blocs trap dans un workflow n8n
function Get-N8nWorkflowTrapBlocks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $trapNodes = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un nÅ“ud de fonction
                if ($node.type -eq "n8n-nodes-base.function" -or $node.type -eq "n8n-nodes-base.functionItem" -or $node.type -eq "n8n-nodes-base.code") {
                    # Extraire le code de la fonction
                    $functionCode = ""

                    if ($node.parameters.functionCode) {
                        $functionCode = $node.parameters.functionCode
                    } elseif ($node.parameters.jsCode) {
                        $functionCode = $node.parameters.jsCode
                    }

                    if ($functionCode) {
                        # DÃ©tecter les blocs trap
                        $trapBlocks = Get-TrapBlocks -FunctionCode $functionCode

                        if ($trapBlocks -and $trapBlocks.Count -gt 0) {
                            # CrÃ©er un objet pour reprÃ©senter le nÅ“ud avec des blocs trap
                            $trapNode = [PSCustomObject]@{
                                Id           = $node.id
                                Name         = $node.name
                                Type         = $node.type
                                TrapBlocks   = $trapBlocks.Count
                                FunctionCode = $functionCode
                                Blocks       = $trapBlocks
                            }

                            # Ajouter le nÅ“ud aux rÃ©sultats
                            $trapNodes += $trapNode
                        }
                    }
                }
            }

            return $trapNodes
        } catch {
            Write-Error "Erreur lors de l'analyse des blocs trap: $_"
            return $null
        }
    }
}

# Fonction pour dÃ©tecter les gestionnaires d'erreurs personnalisÃ©s dans le code d'une fonction
function Get-CustomErrorHandlers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FunctionCode
    )

    try {
        # Initialiser les rÃ©sultats
        $customErrorHandlers = @()

        # Rechercher les gestionnaires d'erreurs personnalisÃ©s
        # 1. Rechercher les blocs try/catch avec des messages d'erreur personnalisÃ©s
        $customCatchMatches = [regex]::Matches($FunctionCode, "catch\s*(\([^)]*\))?\s*{([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))(error|err|exception|e)([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))(message|msg)([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))")

        foreach ($match in $customCatchMatches) {
            $customErrorHandlers += [PSCustomObject]@{
                Type       = "CustomCatch"
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        # 2. Rechercher les appels Ã  Stop And Error ou des fonctions similaires
        $stopErrorMatches = [regex]::Matches($FunctionCode, "(throw|new\s+Error|StopAndError|Stop-Process|Stop-Execution|Stop-Workflow)\s*\(([^()]|(?<open>\()|(?<-open>\)))*(?(open)(?!))")

        foreach ($match in $stopErrorMatches) {
            $customErrorHandlers += [PSCustomObject]@{
                Type       = "StopAndError"
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        # 3. Rechercher les conditions qui vÃ©rifient des erreurs et effectuent des actions spÃ©cifiques
        $errorCheckMatches = [regex]::Matches($FunctionCode, "if\s*\(([^()]|(?<open>\()|(?<-open>\)))*(?(open)(?!))(error|err|exception|e)([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))")

        foreach ($match in $errorCheckMatches) {
            $customErrorHandlers += [PSCustomObject]@{
                Type       = "ErrorCheck"
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        # 4. Rechercher les fonctions de gestion d'erreurs personnalisÃ©es
        $customFunctionMatches = [regex]::Matches($FunctionCode, "function\s+([a-zA-Z0-9_]+Error[a-zA-Z0-9_]*|handle[a-zA-Z0-9_]*Error[a-zA-Z0-9_]*|process[a-zA-Z0-9_]*Error[a-zA-Z0-9_]*|on[a-zA-Z0-9_]*Error[a-zA-Z0-9_]*)\s*\(([^()]|(?<open>\()|(?<-open>\)))*(?(open)(?!))\)\s*{([^{}]|(?<open>{)|(?<-open>}))*(?(open)(?!))}")

        foreach ($match in $customFunctionMatches) {
            # Extraire le nom de la fonction
            $functionNameMatch = [regex]::Match($match.Value, "function\s+([a-zA-Z0-9_]+)")
            $functionName = ""
            if ($functionNameMatch.Success -and $functionNameMatch.Groups.Count -gt 1) {
                $functionName = $functionNameMatch.Groups[1].Value.Trim()
            }

            $customErrorHandlers += [PSCustomObject]@{
                Type       = "CustomErrorFunction"
                Name       = $functionName
                Code       = $match.Value
                StartIndex = $match.Index
                EndIndex   = $match.Index + $match.Length
            }
        }

        # 5. Rechercher les appels Ã  ces fonctions personnalisÃ©es
        if ($customFunctionMatches.Count -gt 0) {
            foreach ($functionMatch in $customFunctionMatches) {
                $functionNameMatch = [regex]::Match($functionMatch.Value, "function\s+([a-zA-Z0-9_]+)")
                if ($functionNameMatch.Success -and $functionNameMatch.Groups.Count -gt 1) {
                    $functionName = $functionNameMatch.Groups[1].Value.Trim()

                    # Rechercher les appels Ã  cette fonction
                    $functionCallMatches = [regex]::Matches($FunctionCode, $functionName + "\s*\(([^()]|(?<open>\()|(?<-open>\)))*(?(open)(?!))\)")

                    foreach ($callMatch in $functionCallMatches) {
                        # VÃ©rifier que ce n'est pas la dÃ©finition de la fonction elle-mÃªme
                        if ($callMatch.Index -ne $functionMatch.Index) {
                            $customErrorHandlers += [PSCustomObject]@{
                                Type       = "CustomErrorFunctionCall"
                                Name       = $functionName
                                Code       = $callMatch.Value
                                StartIndex = $callMatch.Index
                                EndIndex   = $callMatch.Index + $callMatch.Length
                            }
                        }
                    }
                }
            }
        }

        return $customErrorHandlers
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des gestionnaires d'erreurs personnalisÃ©s: $_"
        return $null
    }
}

# Fonction pour analyser les gestionnaires d'erreurs personnalisÃ©s dans un workflow n8n
function Get-N8nWorkflowCustomErrorHandlers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $customErrorNodes = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un nÅ“ud de fonction
                if ($node.type -eq "n8n-nodes-base.function" -or $node.type -eq "n8n-nodes-base.functionItem" -or $node.type -eq "n8n-nodes-base.code") {
                    # Extraire le code de la fonction
                    $functionCode = ""

                    if ($node.parameters.functionCode) {
                        $functionCode = $node.parameters.functionCode
                    } elseif ($node.parameters.jsCode) {
                        $functionCode = $node.parameters.jsCode
                    }

                    if ($functionCode) {
                        # DÃ©tecter les gestionnaires d'erreurs personnalisÃ©s
                        $customErrorHandlers = Get-CustomErrorHandlers -FunctionCode $functionCode

                        if ($customErrorHandlers -and $customErrorHandlers.Count -gt 0) {
                            # CrÃ©er un objet pour reprÃ©senter le nÅ“ud avec des gestionnaires d'erreurs personnalisÃ©s
                            $customErrorNode = [PSCustomObject]@{
                                Id                       = $node.id
                                Name                     = $node.name
                                Type                     = $node.type
                                CustomErrorHandlersCount = $customErrorHandlers.Count
                                FunctionCode             = $functionCode
                                Handlers                 = $customErrorHandlers
                            }

                            # Ajouter le nÅ“ud aux rÃ©sultats
                            $customErrorNodes += $customErrorNode
                        }
                    }
                }
                # VÃ©rifier si le nÅ“ud est un nÅ“ud Stop And Error
                elseif ($node.type -eq "n8n-nodes-base.stopAndError") {
                    # CrÃ©er un objet pour reprÃ©senter le nÅ“ud Stop And Error
                    $customErrorNode = [PSCustomObject]@{
                        Id                       = $node.id
                        Name                     = $node.name
                        Type                     = $node.type
                        CustomErrorHandlersCount = 1
                        ErrorType                = if ($node.parameters.errorType) { $node.parameters.errorType } else { "Message" }
                        ErrorMessage             = if ($node.parameters.errorMessage) { $node.parameters.errorMessage } else { "" }
                        ErrorObject              = if ($node.parameters.errorObject) { $node.parameters.errorObject } else { "" }
                    }

                    # Ajouter le nÅ“ud aux rÃ©sultats
                    $customErrorNodes += $customErrorNode
                }
            }

            # VÃ©rifier si le workflow a un workflow d'erreur configurÃ©
            if ($Workflow.settings -and $Workflow.settings.errorWorkflow) {
                $customErrorNodes += [PSCustomObject]@{
                    Id                       = "error-workflow-config"
                    Name                     = "Error Workflow Configuration"
                    Type                     = "ErrorWorkflowConfig"
                    CustomErrorHandlersCount = 1
                    ErrorWorkflow            = $Workflow.settings.errorWorkflow
                }
            }

            return $customErrorNodes
        } catch {
            Write-Error "Erreur lors de l'analyse des gestionnaires d'erreurs personnalisÃ©s: $_"
            return $null
        }
    }
}

# Fonction pour extraire les conditions de dÃ©clenchement d'un workflow n8n
function Get-N8nWorkflowTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $triggerConditions = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un dÃ©clencheur
                $category = Get-NodeCategory -NodeType $node.type
                if ($category -eq "Trigger") {
                    # CrÃ©er un objet de base pour reprÃ©senter le dÃ©clencheur
                    $trigger = [PSCustomObject]@{
                        Id          = $node.id
                        Name        = $node.name
                        Type        = $node.type
                        TriggerType = Get-TriggerType -NodeType $node.type
                        Conditions  = @()
                    }

                    # Extraire les conditions spÃ©cifiques au type de dÃ©clencheur
                    switch -Wildcard ($node.type) {
                        "n8n-nodes-base.cron" {
                            # DÃ©clencheur Cron (planification)
                            $trigger.Conditions = Get-CronTriggerConditions -Node $node
                        }
                        "n8n-nodes-base.webhook" {
                            # DÃ©clencheur Webhook
                            $trigger.Conditions = Get-WebhookTriggerConditions -Node $node
                        }
                        "n8n-nodes-base.manualTrigger" {
                            # DÃ©clencheur Manuel
                            $trigger.Conditions = Get-ManualTriggerConditions -Node $node
                        }
                        "n8n-nodes-base.emailReadImap" {
                            # DÃ©clencheur Email
                            $trigger.Conditions = Get-EmailTriggerConditions -Node $node
                        }
                        "n8n-nodes-base.workflowTrigger" {
                            # DÃ©clencheur de Workflow
                            $trigger.Conditions = Get-WorkflowTriggerConditions -Node $node
                        }
                        default {
                            # Autres types de dÃ©clencheurs
                            $trigger.Conditions = Get-GenericTriggerConditions -Node $node
                        }
                    }

                    # Ajouter des dÃ©tails si demandÃ©
                    if ($IncludeDetails) {
                        $trigger | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $node.parameters
                        $trigger | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion
                        $trigger | Add-Member -MemberType NoteProperty -Name "Position" -Value $node.position
                    }

                    # Ajouter le dÃ©clencheur aux rÃ©sultats
                    $triggerConditions += $trigger
                }
            }

            return $triggerConditions
        } catch {
            Write-Error "Erreur lors de l'extraction des conditions de dÃ©clenchement: $_"
            return $null
        }
    }
}

# Fonction pour dÃ©terminer le type de dÃ©clencheur
function Get-TriggerType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NodeType
    )

    switch -Wildcard ($NodeType) {
        "n8n-nodes-base.cron" { return "Schedule" }
        "n8n-nodes-base.manualTrigger" { return "Manual" }
        "n8n-nodes-base.webhook" { return "Webhook" }
        "n8n-nodes-base.emailReadImap" { return "Email" }
        "n8n-nodes-base.workflowTrigger" { return "Workflow" }
        "n8n-nodes-base.start" { return "Start" }
        default { return "Other" }
    }
}

# Fonction pour extraire les conditions d'un dÃ©clencheur Cron
function Get-CronTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    $conditions = @()

    if ($Node.parameters.triggerTimes) {
        foreach ($item in $Node.parameters.triggerTimes.item) {
            if ($item.mode -eq "everyMinute") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Every Minute"
                }
            } elseif ($item.mode -eq "everyHour") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Every Hour"
                }
            } elseif ($item.mode -eq "everyDay") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Every Day"
                }
            } elseif ($item.mode -eq "everyWeek") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Every Week"
                }
            } elseif ($item.mode -eq "everyMonth") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Every Month"
                }
            } elseif ($item.mode -eq "everyX") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Every $($item.value) $($item.unit)"
                }
            } elseif ($item.mode -eq "custom") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Custom: $($item.cronExpression)"
                }
            } elseif ($item.mode -eq "manual") {
                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = "Manual"
                }
            } else {
                # Planification spÃ©cifique (heure, minute, jour, etc.)
                $scheduleDetails = @()

                if ($null -ne $item.hour) {
                    $scheduleDetails += "Hour: $($item.hour)"
                }
                if ($null -ne $item.minute) {
                    $scheduleDetails += "Minute: $($item.minute)"
                }
                if ($null -ne $item.weekday) {
                    $scheduleDetails += "Weekday: $($item.weekday -join ', ')"
                }
                if ($null -ne $item.dayOfMonth) {
                    $scheduleDetails += "Day of Month: $($item.dayOfMonth -join ', ')"
                }
                if ($null -ne $item.month) {
                    $scheduleDetails += "Month: $($item.month -join ', ')"
                }

                $conditions += [PSCustomObject]@{
                    Type  = "Schedule"
                    Value = $scheduleDetails -join "; "
                }
            }
        }
    }

    return $conditions
}

# Fonction pour extraire les conditions d'un dÃ©clencheur Webhook
function Get-WebhookTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    $conditions = @()

    # Extraire les informations sur le webhook
    if ($Node.parameters.path) {
        $conditions += [PSCustomObject]@{
            Type  = "Path"
            Value = $Node.parameters.path
        }
    }

    if ($Node.parameters.httpMethod) {
        $conditions += [PSCustomObject]@{
            Type  = "HttpMethod"
            Value = $Node.parameters.httpMethod
        }
    }

    if ($Node.parameters.authentication) {
        $conditions += [PSCustomObject]@{
            Type  = "Authentication"
            Value = $Node.parameters.authentication
        }
    }

    if ($Node.parameters.responseMode) {
        $conditions += [PSCustomObject]@{
            Type  = "ResponseMode"
            Value = $Node.parameters.responseMode
        }
    }

    return $conditions
}

# Fonction pour extraire les conditions d'un dÃ©clencheur Manuel
function Get-ManualTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    # Le dÃ©clencheur manuel n'a pas de conditions spÃ©cifiques
    return @([PSCustomObject]@{
            Type  = "Manual"
            Value = "Triggered manually by user"
        })
}

# Fonction pour extraire les conditions d'un dÃ©clencheur Email
function Get-EmailTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    $conditions = @()

    # Extraire les informations sur le dÃ©clencheur email
    if ($Node.parameters.mailbox) {
        $conditions += [PSCustomObject]@{
            Type  = "Mailbox"
            Value = $Node.parameters.mailbox
        }
    }

    if ($Node.parameters.options -and $Node.parameters.options.criteria) {
        $conditions += [PSCustomObject]@{
            Type  = "Criteria"
            Value = $Node.parameters.options.criteria
        }
    }

    if ($Node.parameters.postProcessAction) {
        $conditions += [PSCustomObject]@{
            Type  = "PostProcessAction"
            Value = $Node.parameters.postProcessAction
        }
    }

    return $conditions
}

# Fonction pour extraire les conditions d'un dÃ©clencheur de Workflow
function Get-WorkflowTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    $conditions = @()

    # Extraire les informations sur le dÃ©clencheur de workflow
    if ($Node.parameters.workflowId) {
        $conditions += [PSCustomObject]@{
            Type  = "WorkflowId"
            Value = $Node.parameters.workflowId
        }
    }

    if ($Node.parameters.triggerOn) {
        $conditions += [PSCustomObject]@{
            Type  = "TriggerOn"
            Value = $Node.parameters.triggerOn
        }
    }

    return $conditions
}

# Fonction pour extraire les conditions d'un dÃ©clencheur gÃ©nÃ©rique
function Get-GenericTriggerConditions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    $conditions = @()

    # Extraire les paramÃ¨tres gÃ©nÃ©riques
    if ($Node.parameters) {
        foreach ($param in $Node.parameters.PSObject.Properties) {
            $conditions += [PSCustomObject]@{
                Type  = $param.Name
                Value = $param.Value
            }
        }
    }

    return $conditions
}

# Fonction pour dÃ©tecter les sources d'Ã©vÃ©nements d'un workflow n8n
function Get-N8nWorkflowEventSources {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $eventSources = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un dÃ©clencheur ou une source d'Ã©vÃ©nements
                $category = Get-NodeCategory -NodeType $node.type
                if ($category -eq "Trigger" -or $node.type -match "webhook|event|trigger") {
                    # DÃ©terminer le type de source d'Ã©vÃ©nements
                    $sourceType = Get-EventSourceType -NodeType $node.type

                    # CrÃ©er un objet pour reprÃ©senter la source d'Ã©vÃ©nements
                    $eventSource = [PSCustomObject]@{
                        Id         = $node.id
                        Name       = $node.name
                        Type       = $node.type
                        SourceType = $sourceType
                        Details    = Get-EventSourceDetails -Node $node -SourceType $sourceType
                    }

                    # Ajouter des dÃ©tails si demandÃ©
                    if ($IncludeDetails) {
                        $eventSource | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $node.parameters
                        $eventSource | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion
                        $eventSource | Add-Member -MemberType NoteProperty -Name "Position" -Value $node.position
                    }

                    # Ajouter la source d'Ã©vÃ©nements aux rÃ©sultats
                    $eventSources += $eventSource
                }
            }

            return $eventSources
        } catch {
            Write-Error "Erreur lors de la dÃ©tection des sources d'Ã©vÃ©nements: $_"
            return $null
        }
    }
}

# Fonction pour dÃ©terminer le type de source d'Ã©vÃ©nements
function Get-EventSourceType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NodeType
    )

    switch -Wildcard ($NodeType) {
        "n8n-nodes-base.cron" { return "Schedule" }
        "n8n-nodes-base.manualTrigger" { return "Manual" }
        "n8n-nodes-base.webhook" { return "HTTP" }
        "n8n-nodes-base.emailReadImap" { return "Email" }
        "n8n-nodes-base.workflowTrigger" { return "Workflow" }
        "*webhook*" { return "HTTP" }
        "*email*" { return "Email" }
        "*trigger*" { return "External" }
        "*event*" { return "Event" }
        default { return "Other" }
    }
}

# Fonction pour extraire les dÃ©tails d'une source d'Ã©vÃ©nements
function Get-EventSourceDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node,

        [Parameter(Mandatory = $true)]
        [string]$SourceType
    )

    $details = @{}

    switch ($SourceType) {
        "Schedule" {
            if ($Node.parameters.triggerTimes) {
                $details["Schedule"] = $Node.parameters.triggerTimes
            }
        }
        "HTTP" {
            if ($Node.parameters.path) {
                $details["Path"] = $Node.parameters.path
            }
            if ($Node.parameters.httpMethod) {
                $details["Method"] = $Node.parameters.httpMethod
            }
            if ($Node.parameters.authentication) {
                $details["Authentication"] = $Node.parameters.authentication
            }
        }
        "Email" {
            if ($Node.parameters.mailbox) {
                $details["Mailbox"] = $Node.parameters.mailbox
            }
            if ($Node.parameters.options -and $Node.parameters.options.criteria) {
                $details["Criteria"] = $Node.parameters.options.criteria
            }
        }
        "Workflow" {
            if ($Node.parameters.workflowId) {
                $details["WorkflowId"] = $Node.parameters.workflowId
            }
            if ($Node.parameters.triggerOn) {
                $details["TriggerOn"] = $Node.parameters.triggerOn
            }
        }
        default {
            # Extraire tous les paramÃ¨tres pour les autres types
            if ($Node.parameters) {
                foreach ($param in $Node.parameters.PSObject.Properties) {
                    $details[$param.Name] = $param.Value
                }
            }
        }
    }

    return $details
}

# Fonction pour analyser les paramÃ¨tres de dÃ©clenchement d'un workflow n8n
function Get-N8nWorkflowTriggerParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $triggerParameters = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est un dÃ©clencheur
                $category = Get-NodeCategory -NodeType $node.type
                if ($category -eq "Trigger") {
                    # CrÃ©er un objet pour reprÃ©senter les paramÃ¨tres du dÃ©clencheur
                    $triggerParam = [PSCustomObject]@{
                        Id          = $node.id
                        Name        = $node.name
                        Type        = $node.type
                        TriggerType = Get-TriggerType -NodeType $node.type
                        Parameters  = @()
                        Impact      = Get-TriggerParameterImpact -Node $node
                    }

                    # Extraire les paramÃ¨tres spÃ©cifiques au type de dÃ©clencheur
                    $triggerParam.Parameters = Get-SpecificTriggerParameters -Node $node -TriggerType (Get-TriggerType -NodeType $node.type)

                    # Ajouter des dÃ©tails si demandÃ©
                    if ($IncludeDetails) {
                        $triggerParam | Add-Member -MemberType NoteProperty -Name "RawParameters" -Value $node.parameters
                        $triggerParam | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion
                        $triggerParam | Add-Member -MemberType NoteProperty -Name "Position" -Value $node.position
                    }

                    # Ajouter les paramÃ¨tres du dÃ©clencheur aux rÃ©sultats
                    $triggerParameters += $triggerParam
                }
            }

            return $triggerParameters
        } catch {
            Write-Error "Erreur lors de l'analyse des paramÃ¨tres de dÃ©clenchement: $_"
            return $null
        }
    }
}

# Fonction pour extraire les paramÃ¨tres spÃ©cifiques Ã  un type de dÃ©clencheur
function Get-SpecificTriggerParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node,

        [Parameter(Mandatory = $true)]
        [string]$TriggerType
    )

    $parameters = @()

    switch ($TriggerType) {
        "Schedule" {
            # ParamÃ¨tres pour les dÃ©clencheurs de planification
            if ($Node.parameters.triggerTimes) {
                foreach ($item in $Node.parameters.triggerTimes.item) {
                    foreach ($prop in $item.PSObject.Properties) {
                        $parameters += [PSCustomObject]@{
                            Name  = $prop.Name
                            Value = $prop.Value
                            Type  = "Schedule"
                        }
                    }
                }
            }
        }
        "Webhook" {
            # ParamÃ¨tres pour les dÃ©clencheurs webhook
            if ($Node.parameters.path) {
                $parameters += [PSCustomObject]@{
                    Name  = "path"
                    Value = $Node.parameters.path
                    Type  = "Path"
                }
            }
            if ($Node.parameters.httpMethod) {
                $parameters += [PSCustomObject]@{
                    Name  = "httpMethod"
                    Value = $Node.parameters.httpMethod
                    Type  = "Method"
                }
            }
            if ($Node.parameters.authentication) {
                $parameters += [PSCustomObject]@{
                    Name  = "authentication"
                    Value = $Node.parameters.authentication
                    Type  = "Authentication"
                }
            }
            if ($Node.parameters.responseMode) {
                $parameters += [PSCustomObject]@{
                    Name  = "responseMode"
                    Value = $Node.parameters.responseMode
                    Type  = "Response"
                }
            }
        }
        "Email" {
            # ParamÃ¨tres pour les dÃ©clencheurs email
            if ($Node.parameters.mailbox) {
                $parameters += [PSCustomObject]@{
                    Name  = "mailbox"
                    Value = $Node.parameters.mailbox
                    Type  = "Mailbox"
                }
            }
            if ($Node.parameters.options -and $Node.parameters.options.criteria) {
                $parameters += [PSCustomObject]@{
                    Name  = "criteria"
                    Value = $Node.parameters.options.criteria
                    Type  = "Filter"
                }
            }
            if ($Node.parameters.postProcessAction) {
                $parameters += [PSCustomObject]@{
                    Name  = "postProcessAction"
                    Value = $Node.parameters.postProcessAction
                    Type  = "Action"
                }
            }
        }
        "Workflow" {
            # ParamÃ¨tres pour les dÃ©clencheurs de workflow
            if ($Node.parameters.workflowId) {
                $parameters += [PSCustomObject]@{
                    Name  = "workflowId"
                    Value = $Node.parameters.workflowId
                    Type  = "Workflow"
                }
            }
            if ($Node.parameters.triggerOn) {
                $parameters += [PSCustomObject]@{
                    Name  = "triggerOn"
                    Value = $Node.parameters.triggerOn
                    Type  = "Event"
                }
            }
        }
        default {
            # ParamÃ¨tres gÃ©nÃ©riques pour les autres types de dÃ©clencheurs
            if ($Node.parameters) {
                foreach ($param in $Node.parameters.PSObject.Properties) {
                    $parameters += [PSCustomObject]@{
                        Name  = $param.Name
                        Value = $param.Value
                        Type  = "Generic"
                    }
                }
            }
        }
    }

    return $parameters
}

# Fonction pour analyser l'impact des paramÃ¨tres de dÃ©clenchement
function Get-TriggerParameterImpact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node
    )

    $impact = [PSCustomObject]@{
        Frequency    = "Unknown"
        DataVolume   = "Unknown"
        Reliability  = "Unknown"
        Security     = "Unknown"
        Dependencies = @()
    }

    # DÃ©terminer l'impact en fonction du type de dÃ©clencheur
    $triggerType = Get-TriggerType -NodeType $node.type

    switch ($triggerType) {
        "Schedule" {
            # Analyser la frÃ©quence pour les dÃ©clencheurs de planification
            if ($Node.parameters.triggerTimes) {
                foreach ($item in $Node.parameters.triggerTimes.item) {
                    if ($item.mode -eq "everyMinute") {
                        $impact.Frequency = "Very High"
                        $impact.DataVolume = "High"
                    } elseif ($item.mode -eq "everyHour") {
                        $impact.Frequency = "High"
                        $impact.DataVolume = "Medium"
                    } elseif ($item.mode -eq "everyDay") {
                        $impact.Frequency = "Medium"
                        $impact.DataVolume = "Low"
                    } elseif ($item.mode -eq "everyWeek" -or $item.mode -eq "everyMonth") {
                        $impact.Frequency = "Low"
                        $impact.DataVolume = "Low"
                    } elseif ($item.mode -eq "everyX") {
                        if ($item.unit -eq "seconds" -or ($item.unit -eq "minutes" -and $item.value -lt 5)) {
                            $impact.Frequency = "Very High"
                            $impact.DataVolume = "Very High"
                        } elseif ($item.unit -eq "minutes") {
                            $impact.Frequency = "High"
                            $impact.DataVolume = "Medium"
                        } elseif ($item.unit -eq "hours") {
                            $impact.Frequency = "Medium"
                            $impact.DataVolume = "Medium"
                        } else {
                            $impact.Frequency = "Low"
                            $impact.DataVolume = "Low"
                        }
                    }
                }
            }
            $impact.Reliability = "High"
            $impact.Security = "High"
            $impact.Dependencies = @("System Clock")
        }
        "Webhook" {
            $impact.Frequency = "Variable"
            $impact.DataVolume = "Variable"
            $impact.Reliability = "Medium"
            $impact.Security = if ($Node.parameters.authentication) { "Medium" } else { "Low" }
            $impact.Dependencies = @("HTTP Server", "Network")
        }
        "Email" {
            $impact.Frequency = "Variable"
            $impact.DataVolume = "Medium"
            $impact.Reliability = "Medium"
            $impact.Security = "Medium"
            $impact.Dependencies = @("Email Server", "Network")
        }
        "Workflow" {
            $impact.Frequency = "Variable"
            $impact.DataVolume = "Low"
            $impact.Reliability = "High"
            $impact.Security = "High"
            if ($Node.parameters.workflowId) {
                $impact.Dependencies = @("n8n Server", "Workflow ID: $($Node.parameters.workflowId)")
            } else {
                $impact.Dependencies = @("n8n Server", "Unknown Workflow")
            }
        }
        "Manual" {
            $impact.Frequency = "Low"
            $impact.DataVolume = "Low"
            $impact.Reliability = "High"
            $impact.Security = "High"
            $impact.Dependencies = @("User Interaction")
        }
        default {
            # Valeurs par dÃ©faut pour les autres types
            $impact.Frequency = "Unknown"
            $impact.DataVolume = "Unknown"
            $impact.Reliability = "Unknown"
            $impact.Security = "Unknown"
            $impact.Dependencies = @("External System")
        }
    }

    return $impact
}

# Fonction pour extraire les actions exÃ©cutÃ©es dans un workflow n8n
function Get-N8nWorkflowActions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRelationships
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $actions = @()

            # CrÃ©er un dictionnaire pour accÃ©der rapidement aux nÅ“uds par ID
            $nodesById = @{}
            foreach ($node in $Workflow.nodes) {
                $nodesById[$node.id] = $node
            }

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est une action (pas un dÃ©clencheur)
                $category = Get-NodeCategory -NodeType $node.type
                if ($category -ne "Trigger") {
                    # CrÃ©er un objet de base pour reprÃ©senter l'action
                    $action = [PSCustomObject]@{
                        Id         = $node.id
                        Name       = $node.name
                        Type       = $node.type
                        Category   = $category
                        ActionType = Get-ActionType -NodeType $node.type
                        Parameters = @()
                    }

                    # Extraire les paramÃ¨tres spÃ©cifiques au type d'action
                    $action.Parameters = Get-ActionParameters -Node $node -ActionType (Get-ActionType -NodeType $node.type)

                    # Ajouter des dÃ©tails si demandÃ©
                    if ($IncludeDetails) {
                        $action | Add-Member -MemberType NoteProperty -Name "RawParameters" -Value $node.parameters
                        $action | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion
                        $action | Add-Member -MemberType NoteProperty -Name "Position" -Value $node.position
                    }

                    # Ajouter les relations si demandÃ©
                    if ($IncludeRelationships) {
                        # Trouver les nÅ“uds sources (entrÃ©es)
                        $inputNodes = @()
                        foreach ($sourceNodeId in $Workflow.connections.PSObject.Properties.Name) {
                            foreach ($connectionArray in $Workflow.connections.$sourceNodeId.main) {
                                foreach ($connection in $connectionArray) {
                                    if ($connection.node -eq $node.id) {
                                        $inputNodes += [PSCustomObject]@{
                                            NodeId   = $sourceNodeId
                                            NodeName = $nodesById[$sourceNodeId].name
                                            NodeType = $nodesById[$sourceNodeId].type
                                        }
                                    }
                                }
                            }
                        }

                        # Trouver les nÅ“uds cibles (sorties)
                        $outputNodes = @()
                        if ($Workflow.connections.$($node.id)) {
                            foreach ($connectionArray in $Workflow.connections.$($node.id).main) {
                                foreach ($connection in $connectionArray) {
                                    $outputNodes += [PSCustomObject]@{
                                        NodeId   = $connection.node
                                        NodeName = $nodesById[$connection.node].name
                                        NodeType = $nodesById[$connection.node].type
                                    }
                                }
                            }
                        }

                        $action | Add-Member -MemberType NoteProperty -Name "InputNodes" -Value $inputNodes
                        $action | Add-Member -MemberType NoteProperty -Name "OutputNodes" -Value $outputNodes
                    }

                    # Ajouter l'action aux rÃ©sultats
                    $actions += $action
                }
            }

            return $actions
        } catch {
            Write-Error "Erreur lors de l'extraction des actions: $_"
            return $null
        }
    }
}

# Fonction pour dÃ©terminer le type d'action
function Get-ActionType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NodeType
    )

    switch -Wildcard ($NodeType) {
        "n8n-nodes-base.httpRequest" { return "HTTP" }
        "n8n-nodes-base.set" { return "DataManipulation" }
        "n8n-nodes-base.function" { return "CodeExecution" }
        "n8n-nodes-base.functionItem" { return "CodeExecution" }
        "n8n-nodes-base.code" { return "CodeExecution" }
        "n8n-nodes-base.if" { return "FlowControl" }
        "n8n-nodes-base.switch" { return "FlowControl" }
        "n8n-nodes-base.merge" { return "FlowControl" }
        "n8n-nodes-base.splitInBatches" { return "FlowControl" }
        "n8n-nodes-base.wait" { return "FlowControl" }
        "n8n-nodes-base.emailSend" { return "Communication" }
        "n8n-nodes-base.slack" { return "Communication" }
        "n8n-nodes-base.telegram" { return "Communication" }
        "n8n-nodes-base.googleSheets" { return "Integration" }
        "n8n-nodes-base.notion" { return "Integration" }
        "n8n-nodes-base.airtable" { return "Integration" }
        "n8n-nodes-base.stickyNote" { return "Documentation" }
        "n8n-nodes-base.stopAndError" { return "ErrorHandling" }
        default { return "Other" }
    }
}

# Fonction pour extraire les paramÃ¨tres d'une action
function Get-ActionParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node,

        [Parameter(Mandatory = $true)]
        [string]$ActionType
    )

    $parameters = @()

    switch ($ActionType) {
        "HTTP" {
            # ParamÃ¨tres pour les actions HTTP
            if ($Node.parameters.url) {
                $parameters += [PSCustomObject]@{
                    Name  = "url"
                    Value = $Node.parameters.url
                    Type  = "URL"
                }
            }
            if ($Node.parameters.method) {
                $parameters += [PSCustomObject]@{
                    Name  = "method"
                    Value = $Node.parameters.method
                    Type  = "Method"
                }
            }
            if ($Node.parameters.authentication) {
                $parameters += [PSCustomObject]@{
                    Name  = "authentication"
                    Value = $Node.parameters.authentication
                    Type  = "Authentication"
                }
            }
            if ($Node.parameters.options) {
                foreach ($option in $Node.parameters.options.PSObject.Properties) {
                    $parameters += [PSCustomObject]@{
                        Name  = $option.Name
                        Value = $option.Value
                        Type  = "Option"
                    }
                }
            }
        }
        "DataManipulation" {
            # ParamÃ¨tres pour les actions de manipulation de donnÃ©es
            if ($Node.parameters.values) {
                foreach ($valueType in $Node.parameters.values.PSObject.Properties) {
                    foreach ($value in $Node.parameters.values.$($valueType.Name)) {
                        $parameters += [PSCustomObject]@{
                            Name  = $value.name
                            Value = $value.value
                            Type  = $valueType.Name
                        }
                    }
                }
            }
            if ($Node.parameters.options) {
                foreach ($option in $Node.parameters.options.PSObject.Properties) {
                    $parameters += [PSCustomObject]@{
                        Name  = $option.Name
                        Value = $option.Value
                        Type  = "Option"
                    }
                }
            }
        }
        "CodeExecution" {
            # ParamÃ¨tres pour les actions d'exÃ©cution de code
            if ($Node.parameters.functionCode) {
                $parameters += [PSCustomObject]@{
                    Name  = "functionCode"
                    Value = "Code JavaScript"
                    Type  = "Code"
                }
            }
            if ($Node.parameters.jsCode) {
                $parameters += [PSCustomObject]@{
                    Name  = "jsCode"
                    Value = "Code JavaScript"
                    Type  = "Code"
                }
            }
            if ($Node.parameters.language) {
                $parameters += [PSCustomObject]@{
                    Name  = "language"
                    Value = $Node.parameters.language
                    Type  = "Language"
                }
            }
        }
        "FlowControl" {
            # ParamÃ¨tres pour les actions de contrÃ´le de flux
            if ($Node.parameters.conditions) {
                foreach ($conditionType in $Node.parameters.conditions.PSObject.Properties) {
                    foreach ($condition in $Node.parameters.conditions.$($conditionType.Name)) {
                        $parameters += [PSCustomObject]@{
                            Name  = "condition"
                            Value = "$($condition.value1) $($condition.operation) $($condition.value2)"
                            Type  = $conditionType.Name
                        }
                    }
                }
            }
            if ($Node.parameters.rules) {
                foreach ($rule in $Node.parameters.rules) {
                    $parameters += [PSCustomObject]@{
                        Name  = "rule"
                        Value = "$($rule.value) $($rule.operation) (Output: $($rule.output))"
                        Type  = "Rule"
                    }
                }
            }
            if ($Node.parameters.mode) {
                $parameters += [PSCustomObject]@{
                    Name  = "mode"
                    Value = $Node.parameters.mode
                    Type  = "Mode"
                }
            }
        }
        "Communication" {
            # ParamÃ¨tres pour les actions de communication
            if ($Node.parameters.to) {
                $parameters += [PSCustomObject]@{
                    Name  = "to"
                    Value = $Node.parameters.to
                    Type  = "Recipient"
                }
            }
            if ($Node.parameters.subject) {
                $parameters += [PSCustomObject]@{
                    Name  = "subject"
                    Value = $Node.parameters.subject
                    Type  = "Subject"
                }
            }
            if ($Node.parameters.text) {
                $parameters += [PSCustomObject]@{
                    Name  = "text"
                    Value = $Node.parameters.text
                    Type  = "Content"
                }
            }
            if ($Node.parameters.channel) {
                $parameters += [PSCustomObject]@{
                    Name  = "channel"
                    Value = $Node.parameters.channel
                    Type  = "Channel"
                }
            }
            if ($Node.parameters.message) {
                $parameters += [PSCustomObject]@{
                    Name  = "message"
                    Value = $Node.parameters.message
                    Type  = "Message"
                }
            }
        }
        "Integration" {
            # ParamÃ¨tres pour les actions d'intÃ©gration
            if ($Node.parameters.resource) {
                $parameters += [PSCustomObject]@{
                    Name  = "resource"
                    Value = $Node.parameters.resource
                    Type  = "Resource"
                }
            }
            if ($Node.parameters.operation) {
                $parameters += [PSCustomObject]@{
                    Name  = "operation"
                    Value = $Node.parameters.operation
                    Type  = "Operation"
                }
            }
            if ($Node.parameters.documentId) {
                $parameters += [PSCustomObject]@{
                    Name  = "documentId"
                    Value = $Node.parameters.documentId
                    Type  = "DocumentID"
                }
            }
            if ($Node.parameters.spreadsheetId) {
                $parameters += [PSCustomObject]@{
                    Name  = "spreadsheetId"
                    Value = $Node.parameters.spreadsheetId
                    Type  = "SpreadsheetID"
                }
            }
        }
        "ErrorHandling" {
            # ParamÃ¨tres pour les actions de gestion d'erreurs
            if ($Node.parameters.errorMessage) {
                $parameters += [PSCustomObject]@{
                    Name  = "errorMessage"
                    Value = $Node.parameters.errorMessage
                    Type  = "ErrorMessage"
                }
            }
            if ($Node.parameters.errorDescription) {
                $parameters += [PSCustomObject]@{
                    Name  = "errorDescription"
                    Value = $Node.parameters.errorDescription
                    Type  = "ErrorDescription"
                }
            }
            if ($Node.parameters.continueOnFail) {
                $parameters += [PSCustomObject]@{
                    Name  = "continueOnFail"
                    Value = $Node.parameters.continueOnFail
                    Type  = "ContinueOnFail"
                }
            }
        }
        default {
            # ParamÃ¨tres gÃ©nÃ©riques pour les autres types d'actions
            if ($Node.parameters) {
                foreach ($param in $Node.parameters.PSObject.Properties) {
                    # Exclure les paramÃ¨tres complexes ou trop volumineux
                    if ($param.Value -isnot [System.Management.Automation.PSCustomObject] -and
                        $param.Value -isnot [System.Object[]] -and
                        $param.Name -ne "functionCode" -and
                        $param.Name -ne "jsCode") {
                        $parameters += [PSCustomObject]@{
                            Name  = $param.Name
                            Value = $param.Value
                            Type  = "Generic"
                        }
                    }
                }
            }
        }
    }

    return $parameters
}

# Fonction pour dÃ©tecter les paramÃ¨tres d'action dans un workflow n8n
function Get-N8nWorkflowActionParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $actionParameters = @()

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est une action (pas un dÃ©clencheur)
                $category = Get-NodeCategory -NodeType $node.type
                if ($category -ne "Trigger") {
                    # CrÃ©er un objet pour reprÃ©senter les paramÃ¨tres de l'action
                    $actionParam = [PSCustomObject]@{
                        Id         = $node.id
                        Name       = $node.name
                        Type       = $node.type
                        Category   = $category
                        ActionType = Get-ActionType -NodeType $node.type
                        Parameters = @()
                        Impact     = Get-ActionParameterImpact -Node $node -ActionType (Get-ActionType -NodeType $node.type)
                    }

                    # Extraire les paramÃ¨tres spÃ©cifiques au type d'action
                    $actionParam.Parameters = Get-ActionParameters -Node $node -ActionType (Get-ActionType -NodeType $node.type)

                    # Ajouter des dÃ©tails si demandÃ©
                    if ($IncludeDetails) {
                        $actionParam | Add-Member -MemberType NoteProperty -Name "RawParameters" -Value $node.parameters
                        $actionParam | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion
                        $actionParam | Add-Member -MemberType NoteProperty -Name "Position" -Value $node.position
                    }

                    # Ajouter les paramÃ¨tres de l'action aux rÃ©sultats
                    $actionParameters += $actionParam
                }
            }

            return $actionParameters
        } catch {
            Write-Error "Erreur lors de l'analyse des paramÃ¨tres d'action: $_"
            return $null
        }
    }
}

# Fonction pour analyser l'impact des paramÃ¨tres d'action
function Get-ActionParameterImpact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node,

        [Parameter(Mandatory = $true)]
        [string]$ActionType
    )

    $impact = [PSCustomObject]@{
        Performance  = "Unknown"
        DataSize     = "Unknown"
        Reliability  = "Unknown"
        Security     = "Unknown"
        Dependencies = @()
    }

    # DÃ©terminer l'impact en fonction du type d'action
    switch ($ActionType) {
        "HTTP" {
            $impact.Performance = "Medium"
            $impact.DataSize = "Variable"
            $impact.Reliability = "Medium"
            $impact.Security = if ($Node.parameters.authentication) { "Medium" } else { "Low" }
            $impact.Dependencies = @("External API", "Network")
        }
        "DataManipulation" {
            $impact.Performance = "High"
            $impact.DataSize = "Low"
            $impact.Reliability = "High"
            $impact.Security = "High"
            $impact.Dependencies = @("Internal Data Processing")
        }
        "CodeExecution" {
            $impact.Performance = "Variable"
            $impact.DataSize = "Variable"
            $impact.Reliability = "Medium"
            $impact.Security = "Medium"
            $impact.Dependencies = @("JavaScript Runtime")
        }
        "FlowControl" {
            $impact.Performance = "High"
            $impact.DataSize = "Low"
            $impact.Reliability = "High"
            $impact.Security = "High"
            $impact.Dependencies = @("Workflow Engine")
        }
        "Communication" {
            $impact.Performance = "Low"
            $impact.DataSize = "Medium"
            $impact.Reliability = "Medium"
            $impact.Security = "Medium"
            $impact.Dependencies = @("Communication Service", "Network")
        }
        "Integration" {
            $impact.Performance = "Low"
            $impact.DataSize = "Variable"
            $impact.Reliability = "Medium"
            $impact.Security = "Medium"
            $impact.Dependencies = @("External Service", "Network", "API")
        }
        "ErrorHandling" {
            $impact.Performance = "High"
            $impact.DataSize = "Low"
            $impact.Reliability = "High"
            $impact.Security = "High"
            $impact.Dependencies = @("Workflow Engine")
        }
        default {
            $impact.Performance = "Unknown"
            $impact.DataSize = "Unknown"
            $impact.Reliability = "Unknown"
            $impact.Security = "Unknown"
            $impact.Dependencies = @("Unknown")
        }
    }

    return $impact
}

# Fonction pour analyser les rÃ©sultats d'action dans un workflow n8n
function Get-N8nWorkflowActionResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Workflow,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    process {
        try {
            # VÃ©rifier si le workflow est valide
            if (-not $Workflow.nodes -or -not $Workflow.connections) {
                Write-Error "Le workflow fourni n'est pas valide."
                return $null
            }

            # Initialiser les rÃ©sultats
            $actionResults = @()

            # CrÃ©er un dictionnaire pour accÃ©der rapidement aux nÅ“uds par ID
            $nodesById = @{}
            foreach ($node in $Workflow.nodes) {
                $nodesById[$node.id] = $node
            }

            # Analyser chaque nÅ“ud du workflow
            foreach ($node in $Workflow.nodes) {
                # VÃ©rifier si le nÅ“ud est une action (pas un dÃ©clencheur)
                $category = Get-NodeCategory -NodeType $node.type
                if ($category -ne "Trigger") {
                    # CrÃ©er un objet pour reprÃ©senter les rÃ©sultats de l'action
                    $actionResult = [PSCustomObject]@{
                        Id         = $node.id
                        Name       = $node.name
                        Type       = $node.type
                        Category   = $category
                        ActionType = Get-ActionType -NodeType $node.type
                        OutputType = Get-ActionOutputType -Node $node -ActionType (Get-ActionType -NodeType $node.type)
                        Consumers  = @()
                        DataFlow   = @()
                    }

                    # Trouver les nÅ“uds qui consomment les rÃ©sultats de cette action
                    if ($Workflow.connections.$($node.id)) {
                        foreach ($outputIndex in 0..($Workflow.connections.$($node.id).main.Count - 1)) {
                            foreach ($connection in $Workflow.connections.$($node.id).main[$outputIndex]) {
                                $targetNode = $nodesById[$connection.node]

                                $consumer = [PSCustomObject]@{
                                    NodeId      = $targetNode.id
                                    NodeName    = $targetNode.name
                                    NodeType    = $targetNode.type
                                    OutputIndex = $outputIndex
                                }

                                $actionResult.Consumers += $consumer

                                # Ajouter l'information de flux de donnÃ©es
                                $dataFlow = [PSCustomObject]@{
                                    SourceNode      = $node.name
                                    SourceType      = $node.type
                                    TargetNode      = $targetNode.name
                                    TargetType      = $targetNode.type
                                    OutputIndex     = $outputIndex
                                    DataTransformed = $false
                                }

                                # DÃ©terminer si les donnÃ©es sont transformÃ©es
                                if ($targetNode.type -match "function|code|set|if|switch") {
                                    $dataFlow.DataTransformed = $true
                                }

                                $actionResult.DataFlow += $dataFlow
                            }
                        }
                    }

                    # Ajouter des dÃ©tails si demandÃ©
                    if ($IncludeDetails) {
                        $actionResult | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $node.parameters
                        $actionResult | Add-Member -MemberType NoteProperty -Name "TypeVersion" -Value $node.typeVersion
                        $actionResult | Add-Member -MemberType NoteProperty -Name "Position" -Value $node.position
                    }

                    # Ajouter les rÃ©sultats de l'action aux rÃ©sultats
                    $actionResults += $actionResult
                }
            }

            return $actionResults
        } catch {
            Write-Error "Erreur lors de l'analyse des rÃ©sultats d'action: $_"
            return $null
        }
    }
}

# Fonction pour dÃ©terminer le type de sortie d'une action
function Get-ActionOutputType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Node,

        [Parameter(Mandatory = $true)]
        [string]$ActionType
    )

    switch ($ActionType) {
        "HTTP" {
            return "JSON/Text"
        }
        "DataManipulation" {
            return "JSON"
        }
        "CodeExecution" {
            return "JSON"
        }
        "FlowControl" {
            if ($Node.type -eq "n8n-nodes-base.if") {
                return "Boolean"
            } elseif ($Node.type -eq "n8n-nodes-base.switch") {
                return "Multiple"
            } else {
                return "JSON"
            }
        }
        "Communication" {
            return "Status"
        }
        "Integration" {
            return "JSON"
        }
        "ErrorHandling" {
            return "Error"
        }
        default {
            return "Unknown"
        }
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function Get-N8nWorkflow, Get-N8nWorkflowActivities, Get-N8nWorkflowTransitions, Get-N8nWorkflowConditions, Get-N8nWorkflowAnalysisReport, Get-N8nWorkflowTryCatchBlocks, Get-N8nWorkflowTrapBlocks, Get-N8nWorkflowCustomErrorHandlers, Get-N8nWorkflowTriggerConditions, Get-N8nWorkflowEventSources, Get-N8nWorkflowTriggerParameters, Get-N8nWorkflowActions, Get-N8nWorkflowActionParameters, Get-N8nWorkflowActionResults
