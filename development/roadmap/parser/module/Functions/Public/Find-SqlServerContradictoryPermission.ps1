<#
.SYNOPSIS
    DÃ©tecte les permissions contradictoires dans SQL Server.

.DESCRIPTION
    Cette fonction analyse les permissions SQL Server pour dÃ©tecter les contradictions,
    comme des permissions GRANT et DENY sur le mÃªme objet pour le mÃªme login.

.PARAMETER ServerInstance
    Le nom de l'instance SQL Server Ã  analyser.

.PARAMETER Credential
    Les informations d'identification Ã  utiliser pour la connexion Ã  SQL Server.

.PARAMETER LoginName
    Filtre les rÃ©sultats pour un login spÃ©cifique.

.PARAMETER PermissionName
    Filtre les rÃ©sultats pour une permission spÃ©cifique.

.PARAMETER ContradictionType
    Filtre les rÃ©sultats par type de contradiction (GRANT/DENY, HÃ©ritage, RÃ´le/Utilisateur).

.PARAMETER OutputFormat
    Format de sortie des rÃ©sultats (Object, Text, HTML, JSON).

.EXAMPLE
    Find-SqlServerContradictoryPermission -ServerInstance "SQLSERVER01"

.EXAMPLE
    Find-SqlServerContradictoryPermission -ServerInstance "SQLSERVER01" -LoginName "AppUser" -ContradictionType "GRANT/DENY"

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-20
#>
function Find-SqlServerContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory = $false)]
        [string]$LoginName,
        
        [Parameter(Mandatory = $false)]
        [string]$PermissionName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "HÃ©ritage", "RÃ´le/Utilisateur", "Tous")]
        [string]$ContradictionType = "Tous",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Object", "Text", "HTML", "JSON")]
        [string]$OutputFormat = "Object"
    )
    
    begin {
        # VÃ©rifier si le module SqlServer est installÃ©
        if (-not (Get-Module -Name SqlServer -ListAvailable)) {
            Write-Warning "Le module SqlServer n'est pas installÃ©. Installation en cours..."
            try {
                Install-Module -Name SqlServer -Force -Scope CurrentUser
            } catch {
                throw "Impossible d'installer le module SqlServer. Veuillez l'installer manuellement avec la commande: Install-Module -Name SqlServer -Force"
            }
        }
        
        # Importer le module SqlServer
        Import-Module -Name SqlServer -ErrorAction Stop
        
        # Charger le modÃ¨le de permissions contradictoires
        $contradictoryPermissionModelPath = Join-Path -Path $script:PrivateFunctionsPath -ChildPath "SqlPermissionModels\ContradictoryPermissionModel.ps1"
        if (Test-Path -Path $contradictoryPermissionModelPath) {
            . $contradictoryPermissionModelPath
        } else {
            throw "Le fichier de modÃ¨le de permissions contradictoires est introuvable: $contradictoryPermissionModelPath"
        }
        
        # CrÃ©er une liste pour stocker les contradictions dÃ©tectÃ©es
        $contradictions = New-Object System.Collections.Generic.List[object]
    }
    
    process {
        try {
            Write-Verbose "Connexion Ã  l'instance SQL Server: $ServerInstance"
            
            # ParamÃ¨tres de connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
                ErrorAction = "Stop"
            }
            
            if ($Credential) {
                $sqlParams.Credential = $Credential
            }
            
            # RÃ©cupÃ©rer les permissions au niveau serveur
            Write-Verbose "RÃ©cupÃ©ration des permissions au niveau serveur"
            $query = @"
SELECT 
    p.class_desc AS SecurableType,
    p.permission_name AS PermissionName,
    p.state_desc AS PermissionState,
    CASE WHEN p.class = 100 OR p.class = 105 THEN OBJECT_NAME(p.major_id)
         ELSE CAST(SERVERPROPERTY('ServerName') AS nvarchar(128))
    END AS SecurableName,
    l.name AS LoginName
FROM sys.server_permissions p
JOIN sys.server_principals l ON p.grantee_principal_id = l.principal_id
WHERE l.type IN ('S', 'U', 'G', 'R')
ORDER BY l.name, p.permission_name, p.state_desc
"@
            
            $serverPermissions = Invoke-Sqlcmd @sqlParams -Query $query
            
            # Regrouper les permissions par login et nom de permission
            $permissionsByLogin = $serverPermissions | Group-Object -Property LoginName, PermissionName
            
            # DÃ©tecter les contradictions GRANT/DENY
            foreach ($group in $permissionsByLogin) {
                $loginName = ($group.Name -split ", ")[0]
                $permissionName = ($group.Name -split ", ")[1]
                
                # Filtrer par login si spÃ©cifiÃ©
                if ($LoginName -and $loginName -ne $LoginName) {
                    continue
                }
                
                # Filtrer par permission si spÃ©cifiÃ©
                if ($PermissionName -and $permissionName -ne $PermissionName) {
                    continue
                }
                
                $grantPermission = $group.Group | Where-Object { $_.PermissionState -eq "GRANT" }
                $denyPermission = $group.Group | Where-Object { $_.PermissionState -eq "DENY" }
                
                if ($grantPermission -and $denyPermission) {
                    # Filtrer par type de contradiction si spÃ©cifiÃ©
                    if ($ContradictionType -ne "Tous" -and $ContradictionType -ne "GRANT/DENY") {
                        continue
                    }
                    
                    $contradiction = New-SqlServerContradictoryPermission `
                        -PermissionName $permissionName `
                        -LoginName $loginName `
                        -SecurableName $ServerInstance `
                        -ContradictionType "GRANT/DENY" `
                        -RiskLevel "Ã‰levÃ©" `
                        -Impact "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s intermittents" `
                        -RecommendedAction "Supprimer l'une des permissions contradictoires (GRANT ou DENY)"
                    
                    $contradictions.Add($contradiction)
                }
            }
            
            # DÃ©tecter les contradictions d'hÃ©ritage (exemple simplifiÃ©)
            if ($ContradictionType -eq "Tous" -or $ContradictionType -eq "HÃ©ritage") {
                # RÃ©cupÃ©rer les rÃ´les de serveur et leurs membres
                $rolesQuery = @"
SELECT 
    r.name AS RoleName,
    m.name AS MemberName
FROM sys.server_role_members rm
JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
"@
                
                $serverRoles = Invoke-Sqlcmd @sqlParams -Query $rolesQuery
                
                # Regrouper les rÃ´les par membre
                $rolesByMember = $serverRoles | Group-Object -Property MemberName
                
                foreach ($member in $rolesByMember) {
                    $memberName = $member.Name
                    
                    # Filtrer par login si spÃ©cifiÃ©
                    if ($LoginName -and $memberName -ne $LoginName) {
                        continue
                    }
                    
                    $memberPermissions = $serverPermissions | Where-Object { $_.LoginName -eq $memberName }
                    
                    foreach ($role in $member.Group) {
                        $roleName = $role.RoleName
                        $rolePermissions = $serverPermissions | Where-Object { $_.LoginName -eq $roleName }
                        
                        foreach ($rolePermission in $rolePermissions) {
                            $memberContradiction = $memberPermissions | Where-Object { 
                                $_.PermissionName -eq $rolePermission.PermissionName -and 
                                $_.PermissionState -ne $rolePermission.PermissionState 
                            }
                            
                            if ($memberContradiction) {
                                # Filtrer par permission si spÃ©cifiÃ©
                                if ($PermissionName -and $rolePermission.PermissionName -ne $PermissionName) {
                                    continue
                                }
                                
                                $contradiction = New-SqlServerContradictoryPermission `
                                    -PermissionName $rolePermission.PermissionName `
                                    -LoginName $memberName `
                                    -SecurableName $ServerInstance `
                                    -ContradictionType "HÃ©ritage" `
                                    -RiskLevel "Moyen" `
                                    -Impact "L'utilisateur hÃ©rite de permissions contradictoires du rÃ´le $roleName" `
                                    -RecommendedAction "VÃ©rifier les permissions du rÃ´le et de l'utilisateur"
                                
                                $contradictions.Add($contradiction)
                            }
                        }
                    }
                }
            }
            
            # Formater la sortie selon le format demandÃ©
            switch ($OutputFormat) {
                "Object" {
                    return $contradictions
                }
                "Text" {
                    $result = "Permissions contradictoires dÃ©tectÃ©es sur $ServerInstance:`n`n"
                    foreach ($contradiction in $contradictions) {
                        $result += $contradiction.GetDetailedDescription() + "`n`n"
                    }
                    return $result
                }
                "HTML" {
                    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de permissions contradictoires - $ServerInstance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #003366; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .critical { background-color: #ffdddd; }
        .high { background-color: #ffffcc; }
        .medium { background-color: #e6f2ff; }
        .low { background-color: #e6ffe6; }
    </style>
</head>
<body>
    <h1>Rapport de permissions contradictoires - $ServerInstance</h1>
    <p>Date du rapport: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <p>Nombre de contradictions dÃ©tectÃ©es: $($contradictions.Count)</p>
    
    <table>
        <tr>
            <th>Login</th>
            <th>Permission</th>
            <th>Type de contradiction</th>
            <th>Niveau de risque</th>
            <th>Impact</th>
            <th>Action recommandÃ©e</th>
        </tr>
"@
                    
                    foreach ($contradiction in $contradictions) {
                        $riskClass = switch ($contradiction.RiskLevel) {
                            "Critique" { "critical" }
                            "Ã‰levÃ©" { "high" }
                            "Moyen" { "medium" }
                            "Faible" { "low" }
                            default { "" }
                        }
                        
                        $html += @"
        <tr class="$riskClass">
            <td>$($contradiction.LoginName)</td>
            <td>$($contradiction.PermissionName)</td>
            <td>$($contradiction.ContradictionType)</td>
            <td>$($contradiction.RiskLevel)</td>
            <td>$($contradiction.Impact)</td>
            <td>$($contradiction.RecommendedAction)</td>
        </tr>
"@
                    }
                    
                    $html += @"
    </table>
</body>
</html>
"@
                    
                    return $html
                }
                "JSON" {
                    $jsonObj = @{
                        ServerInstance = $ServerInstance
                        ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        ContradictionCount = $contradictions.Count
                        Contradictions = @()
                    }
                    
                    foreach ($contradiction in $contradictions) {
                        $jsonObj.Contradictions += @{
                            LoginName = $contradiction.LoginName
                            PermissionName = $contradiction.PermissionName
                            ContradictionType = $contradiction.ContradictionType
                            RiskLevel = $contradiction.RiskLevel
                            Impact = $contradiction.Impact
                            RecommendedAction = $contradiction.RecommendedAction
                        }
                    }
                    
                    return $jsonObj | ConvertTo-Json -Depth 5
                }
            }
        } catch {
            Write-Error "Erreur lors de la dÃ©tection des permissions contradictoires: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "DÃ©tection des permissions contradictoires terminÃ©e. $($contradictions.Count) contradictions trouvÃ©es."
    }
}

# Exporter la fonction
Export-ModuleMember -Function Find-SqlServerContradictoryPermission
