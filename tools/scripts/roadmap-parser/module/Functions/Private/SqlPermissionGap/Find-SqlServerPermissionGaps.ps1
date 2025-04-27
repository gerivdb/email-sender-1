# Find-SqlServerPermissionGaps.ps1
# ImplÃ©mente l'algorithme de dÃ©tection des permissions manquantes au niveau serveur

<#
.SYNOPSIS
    ImplÃ©mente l'algorithme de dÃ©tection des permissions manquantes au niveau serveur SQL.

.DESCRIPTION
    Ce fichier contient les fonctions nÃ©cessaires pour dÃ©tecter les permissions manquantes
    au niveau serveur SQL en comparant les permissions actuelles avec un modÃ¨le de rÃ©fÃ©rence.
    Il utilise les fonctions de comparaison ensembliste pour identifier les Ã©carts et
    fournit des mÃ©thodes pour capturer les permissions actuelles directement depuis une
    instance SQL Server.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-15
#>

# Importer les modules nÃ©cessaires
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

# Fonction pour capturer les permissions au niveau serveur depuis une instance SQL Server
function Get-SqlServerPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseIntegratedSecurity = $true,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeLogins = @("sa", "NT AUTHORITY\SYSTEM", "NT SERVICE\MSSQLSERVER"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeLogins,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePermissions = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludePermissions
    )
    
    try {
        # Construire la chaÃ®ne de connexion
        $connectionString = "Server=$ServerInstance;"
        if ($UseIntegratedSecurity) {
            $connectionString += "Integrated Security=True;"
        }
        else {
            if ($null -eq $Credential) {
                throw "Credential parameter is required when UseIntegratedSecurity is set to false."
            }
            $connectionString += "User ID=$($Credential.UserName);Password=$($Credential.GetNetworkCredential().Password);"
        }
        
        # CrÃ©er la connexion SQL
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        # RequÃªte SQL pour obtenir les permissions au niveau serveur
        $query = @"
SELECT 
    p.state_desc AS PermissionState,
    p.permission_name AS PermissionName,
    CASE 
        WHEN l.name IS NOT NULL THEN l.name
        WHEN r.name IS NOT NULL THEN r.name
        ELSE CAST(p.grantee_principal_id AS NVARCHAR(128))
    END AS LoginName,
    'SERVER' AS SecurableType,
    @@SERVERNAME AS SecurableName
FROM sys.server_permissions p
LEFT JOIN sys.server_principals l ON p.grantee_principal_id = l.principal_id AND l.type IN ('S', 'U', 'G')
LEFT JOIN sys.server_principals r ON p.grantee_principal_id = r.principal_id AND r.type = 'R'
WHERE 1=1
"@
        
        # Ajouter des filtres pour les logins
        if ($IncludeLogins -and $IncludeLogins.Count -gt 0) {
            $loginList = "'" + ($IncludeLogins -join "','") + "'"
            $query += " AND (l.name IN ($loginList) OR r.name IN ($loginList))"
        }
        elseif ($ExcludeLogins -and $ExcludeLogins.Count -gt 0) {
            $loginList = "'" + ($ExcludeLogins -join "','") + "'"
            $query += " AND (l.name NOT IN ($loginList) OR l.name IS NULL) AND (r.name NOT IN ($loginList) OR r.name IS NULL)"
        }
        
        # Ajouter des filtres pour les permissions
        if ($IncludePermissions -and $IncludePermissions.Count -gt 0) {
            $permissionList = "'" + ($IncludePermissions -join "','") + "'"
            $query += " AND p.permission_name IN ($permissionList)"
        }
        elseif ($ExcludePermissions -and $ExcludePermissions.Count -gt 0) {
            $permissionList = "'" + ($ExcludePermissions -join "','") + "'"
            $query += " AND p.permission_name NOT IN ($permissionList)"
        }
        
        # ExÃ©cuter la requÃªte
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        
        # Convertir les rÃ©sultats en objets PowerShell
        $serverPermissions = @()
        foreach ($row in $dataset.Tables[0].Rows) {
            $permissionState = switch ($row.PermissionState) {
                "GRANT" { "GRANT" }
                "DENY" { "DENY" }
                default { "GRANT" }
            }
            
            $serverPermissions += [PSCustomObject]@{
                PermissionName = $row.PermissionName
                LoginName = $row.LoginName
                PermissionState = $permissionState
                SecurableType = $row.SecurableType
                SecurableName = $row.SecurableName
            }
        }
        
        # Fermer la connexion
        $connection.Close()
        
        return $serverPermissions
    }
    catch {
        Write-Error "Error capturing server permissions: $_"
        if ($null -ne $connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
            $connection.Close()
        }
        throw
    }
}

# Fonction pour dÃ©tecter les permissions manquantes au niveau serveur
function Find-SqlServerPermissionGaps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromServer")]
        [string]$ServerInstance,
        
        [Parameter(Mandatory = $false, ParameterSetName = "FromServer")]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory = $false, ParameterSetName = "FromServer")]
        [switch]$UseIntegratedSecurity = $true,
        
        [Parameter(Mandatory = $true, ParameterSetName = "FromPermissions")]
        [PSObject[]]$CurrentPermissions,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$ReferenceModel,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SeverityMap,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeLogins = @("sa", "NT AUTHORITY\SYSTEM", "NT SERVICE\MSSQLSERVER"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeLogins,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePermissions = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludePermissions,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeImpact = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeRecommendations = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateFixScript = $false
    )
    
    # DÃ©finir la carte de sÃ©vÃ©ritÃ© par dÃ©faut si non fournie
    if (-not $PSBoundParameters.ContainsKey("SeverityMap")) {
        $SeverityMap = @{
            "CONNECT SQL" = "Critique"
            "ALTER ANY LOGIN" = "Ã‰levÃ©e"
            "CONTROL SERVER" = "Ã‰levÃ©e"
            "VIEW SERVER STATE" = "Moyenne"
            "VIEW ANY DATABASE" = "Moyenne"
            "DEFAULT" = "Moyenne"
        }
    }
    
    try {
        # Obtenir les permissions actuelles si le paramÃ¨tre ServerInstance est fourni
        if ($PSCmdlet.ParameterSetName -eq "FromServer") {
            $params = @{
                ServerInstance = $ServerInstance
                UseIntegratedSecurity = $UseIntegratedSecurity
            }
            
            if ($PSBoundParameters.ContainsKey("Credential")) {
                $params.Credential = $Credential
            }
            
            if ($PSBoundParameters.ContainsKey("ExcludeLogins")) {
                $params.ExcludeLogins = $ExcludeLogins
            }
            
            if ($PSBoundParameters.ContainsKey("IncludeLogins")) {
                $params.IncludeLogins = $IncludeLogins
            }
            
            if ($PSBoundParameters.ContainsKey("ExcludePermissions")) {
                $params.ExcludePermissions = $ExcludePermissions
            }
            
            if ($PSBoundParameters.ContainsKey("IncludePermissions")) {
                $params.IncludePermissions = $IncludePermissions
            }
            
            $CurrentPermissions = Get-SqlServerPermissions @params
        }
        
        # VÃ©rifier que le modÃ¨le de rÃ©fÃ©rence contient des permissions au niveau serveur
        if (-not ($ReferenceModel.PSObject.Properties.Name -contains "ServerPermissions")) {
            Write-Warning "Reference model does not contain server permissions."
            return New-SqlMissingPermissionsSet -ServerInstance $ServerInstance -ModelName $ReferenceModel.ModelName
        }
        
        # Filtrer les permissions de rÃ©fÃ©rence si nÃ©cessaire
        $referenceServerPermissions = $ReferenceModel.ServerPermissions
        
        if ($PSBoundParameters.ContainsKey("ExcludeLogins") -and $ExcludeLogins.Count -gt 0) {
            $referenceServerPermissions = $referenceServerPermissions | Where-Object { $ExcludeLogins -notcontains $_.LoginName }
        }
        
        if ($PSBoundParameters.ContainsKey("IncludeLogins") -and $IncludeLogins.Count -gt 0) {
            $referenceServerPermissions = $referenceServerPermissions | Where-Object { $IncludeLogins -contains $_.LoginName }
        }
        
        if ($PSBoundParameters.ContainsKey("ExcludePermissions") -and $ExcludePermissions.Count -gt 0) {
            $referenceServerPermissions = $referenceServerPermissions | Where-Object { $ExcludePermissions -notcontains $_.PermissionName }
        }
        
        if ($PSBoundParameters.ContainsKey("IncludePermissions") -and $IncludePermissions.Count -gt 0) {
            $referenceServerPermissions = $referenceServerPermissions | Where-Object { $IncludePermissions -contains $_.PermissionName }
        }
        
        # Comparer les permissions actuelles avec le modÃ¨le de rÃ©fÃ©rence
        $compareParams = @{
            ReferencePermissions = $referenceServerPermissions
            CurrentPermissions = $CurrentPermissions
            ServerInstance = $ServerInstance
            ModelName = $ReferenceModel.ModelName
            SeverityMap = $SeverityMap
        }
        
        $missingPermissions = Compare-SqlServerPermissionSets @compareParams
        
        # Ajouter des informations d'impact si demandÃ©
        if ($IncludeImpact) {
            foreach ($perm in $missingPermissions.ServerPermissions) {
                if ([string]::IsNullOrEmpty($perm.Impact)) {
                    $perm.Impact = Get-SqlServerPermissionImpact -PermissionName $perm.PermissionName -LoginName $perm.LoginName
                }
            }
        }
        
        # Ajouter des recommandations si demandÃ©
        if ($IncludeRecommendations) {
            foreach ($perm in $missingPermissions.ServerPermissions) {
                if ([string]::IsNullOrEmpty($perm.RecommendedAction)) {
                    $perm.RecommendedAction = Get-SqlServerPermissionRecommendation -PermissionName $perm.PermissionName -LoginName $perm.LoginName
                }
            }
        }
        
        # GÃ©nÃ©rer un script de correction si demandÃ©
        if ($GenerateFixScript) {
            $fixScript = $missingPermissions.GenerateFixScript()
            $missingPermissions | Add-Member -MemberType NoteProperty -Name "FixScript" -Value $fixScript
        }
        
        return $missingPermissions
    }
    catch {
        Write-Error "Error detecting server permission gaps: $_"
        throw
    }
}

# Fonction pour obtenir l'impact d'une permission manquante au niveau serveur
function Get-SqlServerPermissionImpact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,
        
        [Parameter(Mandatory = $true)]
        [string]$LoginName
    )
    
    # DÃ©finir les impacts par dÃ©faut pour les permissions courantes
    $impactMap = @{
        "CONNECT SQL" = "Le login '$LoginName' ne peut pas se connecter au serveur SQL, ce qui empÃªche toute opÃ©ration."
        "VIEW SERVER STATE" = "Le login '$LoginName' ne peut pas voir l'Ã©tat du serveur, ce qui limite la surveillance et le diagnostic."
        "ALTER ANY LOGIN" = "Le login '$LoginName' ne peut pas gÃ©rer les logins, ce qui limite les capacitÃ©s d'administration."
        "CONTROL SERVER" = "Le login '$LoginName' n'a pas le contrÃ´le complet du serveur, ce qui limite les capacitÃ©s d'administration."
        "VIEW ANY DATABASE" = "Le login '$LoginName' ne peut pas voir toutes les bases de donnÃ©es, ce qui limite la visibilitÃ©."
        "ALTER ANY DATABASE" = "Le login '$LoginName' ne peut pas modifier les bases de donnÃ©es, ce qui limite les capacitÃ©s d'administration."
        "CREATE ANY DATABASE" = "Le login '$LoginName' ne peut pas crÃ©er de nouvelles bases de donnÃ©es."
        "ALTER ANY CREDENTIAL" = "Le login '$LoginName' ne peut pas gÃ©rer les informations d'identification."
        "ALTER RESOURCES" = "Le login '$LoginName' ne peut pas modifier les paramÃ¨tres de ressources du serveur."
        "SHUTDOWN" = "Le login '$LoginName' ne peut pas arrÃªter l'instance SQL Server."
        "ALTER SETTINGS" = "Le login '$LoginName' ne peut pas modifier les paramÃ¨tres de configuration du serveur."
        "ALTER TRACE" = "Le login '$LoginName' ne peut pas contrÃ´ler les traces SQL Server."
    }
    
    # Retourner l'impact spÃ©cifique ou un impact gÃ©nÃ©rique
    if ($impactMap.ContainsKey($PermissionName)) {
        return $impactMap[$PermissionName]
    }
    else {
        return "Le login '$LoginName' ne dispose pas de la permission '$PermissionName' au niveau serveur, ce qui peut limiter certaines fonctionnalitÃ©s."
    }
}

# Fonction pour obtenir une recommandation pour une permission manquante au niveau serveur
function Get-SqlServerPermissionRecommendation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,
        
        [Parameter(Mandatory = $true)]
        [string]$LoginName
    )
    
    # DÃ©finir les recommandations par dÃ©faut pour les permissions courantes
    $recommendationMap = @{
        "CONNECT SQL" = "Accorder la permission CONNECT SQL au login '$LoginName' pour permettre la connexion au serveur."
        "VIEW SERVER STATE" = "Accorder la permission VIEW SERVER STATE au login '$LoginName' pour permettre la surveillance et le diagnostic."
        "ALTER ANY LOGIN" = "Accorder la permission ALTER ANY LOGIN au login '$LoginName' pour permettre la gestion des logins."
        "CONTROL SERVER" = "Accorder la permission CONTROL SERVER au login '$LoginName' avec prÃ©caution, car elle donne un contrÃ´le complet du serveur."
        "VIEW ANY DATABASE" = "Accorder la permission VIEW ANY DATABASE au login '$LoginName' pour permettre la visibilitÃ© de toutes les bases de donnÃ©es."
        "ALTER ANY DATABASE" = "Accorder la permission ALTER ANY DATABASE au login '$LoginName' pour permettre la modification des bases de donnÃ©es."
        "CREATE ANY DATABASE" = "Accorder la permission CREATE ANY DATABASE au login '$LoginName' pour permettre la crÃ©ation de nouvelles bases de donnÃ©es."
        "ALTER ANY CREDENTIAL" = "Accorder la permission ALTER ANY CREDENTIAL au login '$LoginName' pour permettre la gestion des informations d'identification."
        "ALTER RESOURCES" = "Accorder la permission ALTER RESOURCES au login '$LoginName' pour permettre la modification des paramÃ¨tres de ressources."
        "SHUTDOWN" = "Accorder la permission SHUTDOWN au login '$LoginName' avec prÃ©caution, car elle permet d'arrÃªter l'instance SQL Server."
        "ALTER SETTINGS" = "Accorder la permission ALTER SETTINGS au login '$LoginName' pour permettre la modification des paramÃ¨tres de configuration."
        "ALTER TRACE" = "Accorder la permission ALTER TRACE au login '$LoginName' pour permettre le contrÃ´le des traces SQL Server."
    }
    
    # Retourner la recommandation spÃ©cifique ou une recommandation gÃ©nÃ©rique
    if ($recommendationMap.ContainsKey($PermissionName)) {
        return $recommendationMap[$PermissionName]
    }
    else {
        return "Accorder la permission '$PermissionName' au login '$LoginName' au niveau serveur si cette fonctionnalitÃ© est nÃ©cessaire."
    }
}

# Fonction pour gÃ©nÃ©rer un rapport de conformitÃ© des permissions au niveau serveur
function New-SqlServerPermissionComplianceReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$MissingPermissions,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$ReferenceModel,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "CSV", "JSON")]
        [string]$Format = "Text",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeFixScript = $true
    )
    
    try {
        # Calculer le score de conformitÃ©
        $totalPermissions = $ReferenceModel.ServerPermissions.Count
        $missingCount = $MissingPermissions.ServerPermissions.Count
        $complianceScore = if ($totalPermissions -gt 0) {
            [math]::Round(100 - ($missingCount / $totalPermissions * 100), 2)
        }
        else {
            100
        }
        
        # CrÃ©er le rapport en fonction du format demandÃ©
        switch ($Format) {
            "Text" {
                $report = "Rapport de conformitÃ© des permissions au niveau serveur`n"
                $report += "================================================`n`n"
                $report += "Instance: $($MissingPermissions.ServerInstance)`n"
                $report += "ModÃ¨le de rÃ©fÃ©rence: $($ReferenceModel.ModelName)`n"
                $report += "Date: $($MissingPermissions.ComparisonDate)`n`n"
                
                $report += "Score de conformitÃ©: $complianceScore%`n"
                $report += "Permissions conformes: $($totalPermissions - $missingCount)/$totalPermissions`n"
                $report += "Permissions manquantes: $missingCount/$totalPermissions`n`n"
                
                $report += "RÃ©partition par sÃ©vÃ©ritÃ©:`n"
                $report += "- Critique: $($MissingPermissions.SeverityCounts['Critique'])`n"
                $report += "- Ã‰levÃ©e: $($MissingPermissions.SeverityCounts['Ã‰levÃ©e'])`n"
                $report += "- Moyenne: $($MissingPermissions.SeverityCounts['Moyenne'])`n"
                $report += "- Faible: $($MissingPermissions.SeverityCounts['Faible'])`n`n"
                
                if ($missingCount -gt 0) {
                    $report += "Permissions manquantes:`n"
                    foreach ($perm in $MissingPermissions.ServerPermissions) {
                        $report += "- $($perm.ToString())`n"
                        $report += "  SÃ©vÃ©ritÃ©: $($perm.Severity)`n"
                        if (-not [string]::IsNullOrEmpty($perm.Impact)) {
                            $report += "  Impact: $($perm.Impact)`n"
                        }
                        if (-not [string]::IsNullOrEmpty($perm.RecommendedAction)) {
                            $report += "  Action recommandÃ©e: $($perm.RecommendedAction)`n"
                        }
                        $report += "`n"
                    }
                }
                
                if ($IncludeFixScript -and $missingCount -gt 0) {
                    $report += "Script de correction:`n"
                    $report += "-------------------`n"
                    $report += $MissingPermissions.GenerateFixScript()
                    $report += "`n"
                }
            }
            "HTML" {
                $report = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de conformitÃ© des permissions SQL Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0066cc; }
        .summary { margin: 20px 0; }
        .score { font-size: 24px; font-weight: bold; }
        .high { color: green; }
        .medium { color: orange; }
        .low { color: red; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .severity-Critique { color: red; font-weight: bold; }
        .severity-Ã‰levÃ©e { color: orange; font-weight: bold; }
        .severity-Moyenne { color: blue; }
        .severity-Faible { color: green; }
        pre { background-color: #f5f5f5; padding: 10px; border: 1px solid #ddd; overflow: auto; }
    </style>
</head>
<body>
    <h1>Rapport de conformitÃ© des permissions SQL Server</h1>
    
    <div class="summary">
        <p><strong>Instance:</strong> $($MissingPermissions.ServerInstance)</p>
        <p><strong>ModÃ¨le de rÃ©fÃ©rence:</strong> $($ReferenceModel.ModelName)</p>
        <p><strong>Date:</strong> $($MissingPermissions.ComparisonDate)</p>
    </div>
    
    <h2>Score de conformitÃ©</h2>
    <div class="score $($complianceScore -ge 90 ? 'high' : ($complianceScore -ge 70 ? 'medium' : 'low'))">
        $complianceScore%
    </div>
    
    <p>Permissions conformes: $($totalPermissions - $missingCount)/$totalPermissions</p>
    <p>Permissions manquantes: $missingCount/$totalPermissions</p>
    
    <h2>RÃ©partition par sÃ©vÃ©ritÃ©</h2>
    <ul>
        <li class="severity-Critique">Critique: $($MissingPermissions.SeverityCounts['Critique'])</li>
        <li class="severity-Ã‰levÃ©e">Ã‰levÃ©e: $($MissingPermissions.SeverityCounts['Ã‰levÃ©e'])</li>
        <li class="severity-Moyenne">Moyenne: $($MissingPermissions.SeverityCounts['Moyenne'])</li>
        <li class="severity-Faible">Faible: $($MissingPermissions.SeverityCounts['Faible'])</li>
    </ul>
"@
                
                if ($missingCount -gt 0) {
                    $report += @"
    <h2>Permissions manquantes</h2>
    <table>
        <tr>
            <th>Permission</th>
            <th>Login</th>
            <th>Ã‰tat</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Impact</th>
            <th>Action recommandÃ©e</th>
        </tr>
"@
                    
                    foreach ($perm in $MissingPermissions.ServerPermissions) {
                        $report += @"
        <tr>
            <td>$($perm.PermissionName)</td>
            <td>$($perm.LoginName)</td>
            <td>$($perm.PermissionState)</td>
            <td class="severity-$($perm.Severity)">$($perm.Severity)</td>
            <td>$($perm.Impact)</td>
            <td>$($perm.RecommendedAction)</td>
        </tr>
"@
                    }
                    
                    $report += @"
    </table>
"@
                }
                
                if ($IncludeFixScript -and $missingCount -gt 0) {
                    $fixScript = $MissingPermissions.GenerateFixScript() -replace "`n", "<br>" -replace " ", "&nbsp;"
                    $report += @"
    <h2>Script de correction</h2>
    <pre>$fixScript</pre>
"@
                }
                
                $report += @"
</body>
</html>
"@
            }
            "CSV" {
                $report = "Instance,ModelName,ComparisonDate,ComplianceScore,TotalPermissions,MissingPermissions,CriticalCount,HighCount,MediumCount,LowCount`n"
                $report += "$($MissingPermissions.ServerInstance),$($ReferenceModel.ModelName),$($MissingPermissions.ComparisonDate),$complianceScore,$totalPermissions,$missingCount,$($MissingPermissions.SeverityCounts['Critique']),$($MissingPermissions.SeverityCounts['Ã‰levÃ©e']),$($MissingPermissions.SeverityCounts['Moyenne']),$($MissingPermissions.SeverityCounts['Faible'])`n`n"
                
                if ($missingCount -gt 0) {
                    $report += "PermissionName,LoginName,PermissionState,Severity,Impact,RecommendedAction`n"
                    foreach ($perm in $MissingPermissions.ServerPermissions) {
                        $impact = $perm.Impact -replace ",", ";"
                        $recommendedAction = $perm.RecommendedAction -replace ",", ";"
                        $report += "$($perm.PermissionName),$($perm.LoginName),$($perm.PermissionState),$($perm.Severity),`"$impact`",`"$recommendedAction`"`n"
                    }
                }
            }
            "JSON" {
                $reportObj = [PSCustomObject]@{
                    Instance = $MissingPermissions.ServerInstance
                    ModelName = $ReferenceModel.ModelName
                    ComparisonDate = $MissingPermissions.ComparisonDate
                    ComplianceScore = $complianceScore
                    TotalPermissions = $totalPermissions
                    MissingPermissions = $missingCount
                    SeverityCounts = $MissingPermissions.SeverityCounts
                    MissingPermissionDetails = $MissingPermissions.ServerPermissions
                }
                
                if ($IncludeFixScript -and $missingCount -gt 0) {
                    $reportObj | Add-Member -MemberType NoteProperty -Name "FixScript" -Value $MissingPermissions.GenerateFixScript()
                }
                
                $report = $reportObj | ConvertTo-Json -Depth 5
            }
        }
        
        # Enregistrer le rapport si un chemin de sortie est spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $report | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        return $report
    }
    catch {
        Write-Error "Error generating server permission compliance report: $_"
        throw
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-SqlServerPermissions, Find-SqlServerPermissionGaps, New-SqlServerPermissionComplianceReport
