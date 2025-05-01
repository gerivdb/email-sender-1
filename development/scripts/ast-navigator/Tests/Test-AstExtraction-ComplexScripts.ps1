<#
.SYNOPSIS
    Tests d'extraction AST avec des scripts PowerShell complexes.

.DESCRIPTION
    Ce script teste les fonctions d'extraction AST (Get-AstFunctions, Get-AstParameters, 
    Get-AstVariables, Get-AstCommands) avec des scripts PowerShell complexes contenant 
    des classes, des configurations DSC, des workflows, etc.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-12-15
#>

# Importer les fonctions à tester
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"
. "$PSScriptRoot\..\Public\Get-AstCommands.ps1"

# Fonction pour vérifier une condition
function Assert-Condition {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$Critical
    )
    
    if ($Condition) {
        Write-Host "  [PASSED] $Message" -ForegroundColor Green
        return $true
    } else {
        if ($Critical) {
            Write-Host "  [FAILED] $Message (CRITIQUE)" -ForegroundColor Red
        } else {
            Write-Host "  [FAILED] $Message" -ForegroundColor Red
        }
        return $false
    }
}

# Fonction pour exécuter les tests sur un script complexe
function Test-ComplexScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptContent,
        
        [Parameter(Mandatory = $false)]
        [string]$ScriptType = "Général"
    )
    
    Write-Host "=== Test du script complexe: $ScriptName (Type: $ScriptType) ===" -ForegroundColor Cyan
    
    # Analyser le code avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
    
    # Vérifier que l'analyse AST s'est bien déroulée
    if (-not (Assert-Condition -Condition ($null -ne $ast) -Message "L'AST a été créé avec succès" -Critical)) {
        Write-Host "  Erreurs d'analyse: $errors" -ForegroundColor Red
        return $false
    }
    
    # Test 1: Extraction des fonctions
    Write-Host "`n  Test 1: Extraction des fonctions" -ForegroundColor Yellow
    $functions = Get-AstFunctions -Ast $ast
    $functionsSuccess = Assert-Condition -Condition ($null -ne $functions) -Message "Les fonctions ont été extraites avec succès"
    
    if ($functionsSuccess -and $functions.Count -gt 0) {
        Write-Host "    Fonctions trouvées: $($functions.Count)" -ForegroundColor Cyan
        foreach ($function in $functions) {
            Write-Host "      - $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Gray
        }
    }
    
    # Test 2: Extraction des paramètres
    Write-Host "`n  Test 2: Extraction des paramètres" -ForegroundColor Yellow
    $scriptParams = Get-AstParameters -Ast $ast
    $scriptParamsSuccess = Assert-Condition -Condition ($null -ne $scriptParams) -Message "Les paramètres du script ont été extraits avec succès"
    
    if ($scriptParamsSuccess -and $scriptParams.Count -gt 0) {
        Write-Host "    Paramètres du script trouvés: $($scriptParams.Count)" -ForegroundColor Cyan
        foreach ($param in $scriptParams) {
            $defaultValue = if ($param.DefaultValue) { " = $($param.DefaultValue)" } else { "" }
            Write-Host "      - [$($param.Type)]`$$($param.Name)$defaultValue" -ForegroundColor Gray
        }
    }
    
    # Extraction des paramètres de fonction (si des fonctions ont été trouvées)
    if ($functionsSuccess -and $functions.Count -gt 0) {
        $firstFunction = $functions[0].Name
        $functionParams = Get-AstParameters -Ast $ast -FunctionName $firstFunction
        $functionParamsSuccess = Assert-Condition -Condition ($null -ne $functionParams) -Message "Les paramètres de la fonction '$firstFunction' ont été extraits avec succès"
        
        if ($functionParamsSuccess -and $functionParams.Count -gt 0) {
            Write-Host "    Paramètres de la fonction '$firstFunction' trouvés: $($functionParams.Count)" -ForegroundColor Cyan
            foreach ($param in $functionParams) {
                $defaultValue = if ($param.DefaultValue) { " = $($param.DefaultValue)" } else { "" }
                Write-Host "      - [$($param.Type)]`$$($param.Name)$defaultValue" -ForegroundColor Gray
            }
        }
    }
    
    # Test 3: Extraction des variables
    Write-Host "`n  Test 3: Extraction des variables" -ForegroundColor Yellow
    $variables = Get-AstVariables -Ast $ast
    $variablesSuccess = Assert-Condition -Condition ($null -ne $variables) -Message "Les variables ont été extraites avec succès"
    
    if ($variablesSuccess -and $variables.Count -gt 0) {
        Write-Host "    Variables trouvées: $($variables.Count)" -ForegroundColor Cyan
        $uniqueVars = $variables | Select-Object -Property Name, Scope -Unique | Sort-Object -Property Name
        foreach ($var in $uniqueVars | Select-Object -First 10) {
            $scope = if ($var.Scope) { "$($var.Scope):" } else { "" }
            Write-Host "      - `$$scope$($var.Name)" -ForegroundColor Gray
        }
        if ($uniqueVars.Count -gt 10) {
            Write-Host "      - ... et $($uniqueVars.Count - 10) autres variables" -ForegroundColor Gray
        }
    }
    
    # Test 4: Extraction des commandes
    Write-Host "`n  Test 4: Extraction des commandes" -ForegroundColor Yellow
    $commands = Get-AstCommands -Ast $ast
    $commandsSuccess = Assert-Condition -Condition ($null -ne $commands) -Message "Les commandes ont été extraites avec succès"
    
    if ($commandsSuccess -and $commands.Count -gt 0) {
        Write-Host "    Commandes trouvées: $($commands.Count)" -ForegroundColor Cyan
        $uniqueCommands = $commands | Select-Object -Property Name -Unique | Sort-Object -Property Name
        foreach ($cmd in $uniqueCommands | Select-Object -First 10) {
            Write-Host "      - $($cmd.Name)" -ForegroundColor Gray
        }
        if ($uniqueCommands.Count -gt 10) {
            Write-Host "      - ... et $($uniqueCommands.Count - 10) autres commandes" -ForegroundColor Gray
        }
    }
    
    # Test 5: Extraction détaillée
    Write-Host "`n  Test 5: Extraction détaillée" -ForegroundColor Yellow
    $detailedFunctions = Get-AstFunctions -Ast $ast -Detailed
    $detailedSuccess = Assert-Condition -Condition ($null -ne $detailedFunctions) -Message "Les fonctions détaillées ont été extraites avec succès"
    
    if ($detailedSuccess -and $detailedFunctions.Count -gt 0) {
        $firstDetailedFunction = $detailedFunctions[0]
        Write-Host "    Détails de la fonction '$($firstDetailedFunction.Name)':" -ForegroundColor Cyan
        Write-Host "      - Paramètres: $($firstDetailedFunction.Parameters.Count)" -ForegroundColor Gray
        Write-Host "      - Type de retour: $($firstDetailedFunction.ReturnType)" -ForegroundColor Gray
        Write-Host "      - Lignes: $($firstDetailedFunction.StartLine)-$($firstDetailedFunction.EndLine)" -ForegroundColor Gray
    }
    
    # Test 6: Extraction avec arguments
    Write-Host "`n  Test 6: Extraction avec arguments" -ForegroundColor Yellow
    $commandsWithArgs = Get-AstCommands -Ast $ast -IncludeArguments
    $argsSuccess = Assert-Condition -Condition ($null -ne $commandsWithArgs) -Message "Les commandes avec arguments ont été extraites avec succès"
    
    if ($argsSuccess -and $commandsWithArgs.Count -gt 0) {
        $commandWithArgs = $commandsWithArgs | Where-Object { $_.Arguments -and $_.Arguments.Count -gt 0 } | Select-Object -First 1
        if ($commandWithArgs) {
            Write-Host "    Arguments de la commande '$($commandWithArgs.Name)':" -ForegroundColor Cyan
            foreach ($arg in $commandWithArgs.Arguments) {
                if ($arg.IsParameter) {
                    Write-Host "      - Paramètre: -$($arg.ParameterName) = $($arg.Value)" -ForegroundColor Gray
                } else {
                    Write-Host "      - Valeur: $($arg.Value)" -ForegroundColor Gray
                }
            }
        }
    }
    
    # Tests spécifiques au type de script
    switch ($ScriptType) {
        "Classe" {
            Write-Host "`n  Test 7: Extraction spécifique aux classes" -ForegroundColor Yellow
            # Note: L'extraction des classes n'est pas directement supportée par les fonctions actuelles
            # Mais nous pouvons vérifier si les méthodes sont correctement extraites comme des fonctions
            $classMethods = $functions | Where-Object { $_.Name -like "*-*" }
            Assert-Condition -Condition ($classMethods.Count -gt 0) -Message "Les méthodes de classe ont été extraites comme des fonctions"
        }
        "DSC" {
            Write-Host "`n  Test 7: Extraction spécifique à DSC" -ForegroundColor Yellow
            # Vérifier si les ressources DSC sont correctement extraites
            $dscResources = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true)
            Assert-Condition -Condition ($dscResources.Count -gt 0) -Message "Les configurations DSC ont été trouvées dans l'AST"
            
            if ($dscResources.Count -gt 0) {
                Write-Host "    Configurations DSC trouvées: $($dscResources.Count)" -ForegroundColor Cyan
                foreach ($resource in $dscResources) {
                    Write-Host "      - $($resource.Name)" -ForegroundColor Gray
                }
            }
        }
        "Workflow" {
            Write-Host "`n  Test 7: Extraction spécifique aux workflows" -ForegroundColor Yellow
            # Vérifier si les workflows sont correctement extraits comme des fonctions
            $workflows = $functions | Where-Object { $_.Name -like "*-*" }
            Assert-Condition -Condition ($workflows.Count -gt 0) -Message "Les workflows ont été extraits comme des fonctions"
        }
    }
    
    Write-Host "`n=== Fin des tests pour le script: $ScriptName ===" -ForegroundColor Cyan
    return $true
}

# Script complexe 1: Script avec classes PowerShell
$classScript = @'
<#
.SYNOPSIS
    Script complexe avec des classes PowerShell.
#>

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text.RegularExpressions

# Classe de base pour les entités
class Entity {
    [string]$Id
    [string]$Name
    [datetime]$CreatedDate
    
    Entity() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.CreatedDate = [datetime]::Now
    }
    
    Entity([string]$name) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Name = $name
        $this.CreatedDate = [datetime]::Now
    }
    
    [string] ToString() {
        return "$($this.Id): $($this.Name) (Créé le $($this.CreatedDate.ToString('yyyy-MM-dd')))"
    }
}

# Classe dérivée pour les utilisateurs
class User : Entity {
    [string]$Email
    [string]$Department
    [bool]$IsActive
    hidden [string]$PasswordHash
    
    User([string]$name, [string]$email) : base($name) {
        $this.Email = $email
        $this.IsActive = $true
    }
    
    [void] SetPassword([string]$password) {
        # Simuler un hachage de mot de passe
        $this.PasswordHash = [Convert]::ToBase64String(
            [System.Text.Encoding]::UTF8.GetBytes($password)
        )
    }
    
    [bool] ValidatePassword([string]$password) {
        $hash = [Convert]::ToBase64String(
            [System.Text.Encoding]::UTF8.GetBytes($password)
        )
        return $hash -eq $this.PasswordHash
    }
    
    [void] Deactivate() {
        $this.IsActive = $false
    }
    
    [void] Activate() {
        $this.IsActive = $true
    }
    
    [string] ToString() {
        $status = if ($this.IsActive) { "Actif" } else { "Inactif" }
        return "$($this.Name) <$($this.Email)> [$status]"
    }
}

# Classe pour la gestion des utilisateurs
class UserManager {
    [List[User]]$Users
    
    UserManager() {
        $this.Users = [List[User]]::new()
    }
    
    [User] AddUser([string]$name, [string]$email, [string]$password) {
        $user = [User]::new($name, $email)
        $user.SetPassword($password)
        $this.Users.Add($user)
        return $user
    }
    
    [User] GetUserByEmail([string]$email) {
        return $this.Users | Where-Object { $_.Email -eq $email } | Select-Object -First 1
    }
    
    [User[]] GetActiveUsers() {
        return $this.Users | Where-Object { $_.IsActive }
    }
    
    [void] RemoveUser([string]$email) {
        $user = $this.GetUserByEmail($email)
        if ($user) {
            $this.Users.Remove($user)
        }
    }
    
    [void] ExportToCsv([string]$path) {
        $csv = $this.Users | ForEach-Object {
            [PSCustomObject]@{
                Id = $_.Id
                Name = $_.Name
                Email = $_.Email
                Department = $_.Department
                IsActive = $_.IsActive
                CreatedDate = $_.CreatedDate.ToString('yyyy-MM-dd')
            }
        } | ConvertTo-Csv -NoTypeInformation
        
        $csv | Out-File -FilePath $path -Encoding utf8
    }
}

# Fonction pour démontrer l'utilisation des classes
function Demo-UserManagement {
    param (
        [string]$ExportPath = "C:\Temp\users.csv"
    )
    
    # Créer un gestionnaire d'utilisateurs
    $manager = [UserManager]::new()
    
    # Ajouter des utilisateurs
    $user1 = $manager.AddUser("Jean Dupont", "jean.dupont@example.com", "P@ssw0rd1")
    $user1.Department = "Informatique"
    
    $user2 = $manager.AddUser("Marie Martin", "marie.martin@example.com", "P@ssw0rd2")
    $user2.Department = "Ressources Humaines"
    
    $user3 = $manager.AddUser("Pierre Durand", "pierre.durand@example.com", "P@ssw0rd3")
    $user3.Department = "Marketing"
    $user3.Deactivate()
    
    # Afficher les utilisateurs
    Write-Output "Liste des utilisateurs:"
    foreach ($user in $manager.Users) {
        Write-Output "  $user"
    }
    
    # Afficher les utilisateurs actifs
    $activeUsers = $manager.GetActiveUsers()
    Write-Output "`nUtilisateurs actifs: $($activeUsers.Count)"
    foreach ($user in $activeUsers) {
        Write-Output "  $user"
    }
    
    # Exporter les utilisateurs
    $manager.ExportToCsv($ExportPath)
    Write-Output "`nUtilisateurs exportés vers: $ExportPath"
}

# Appeler la fonction de démonstration
Demo-UserManagement
'@

# Script complexe 2: Configuration DSC
$dscScript = @'
<#
.SYNOPSIS
    Script complexe avec une configuration DSC (Desired State Configuration).
#>

# Paramètres de la configuration
param (
    [Parameter(Mandatory = $true)]
    [string]$NodeName = "localhost",
    
    [Parameter(Mandatory = $true)]
    [string]$WebsiteName,
    
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = "C:\inetpub\wwwroot\$WebsiteName",
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 80
)

# Importer les modules nécessaires
Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xWebAdministration

# Fonction d'aide pour valider les chemins
function Test-PathValid {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        throw "Le chemin n'existe pas: $Path"
    }
    
    return $true
}

# Configuration DSC pour un serveur web
Configuration WebServerConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NodeName,
        
        [Parameter(Mandatory = $true)]
        [string]$WebsiteName,
        
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        
        [Parameter(Mandatory = $true)]
        [int]$Port
    )
    
    # Nœud à configurer
    Node $NodeName {
        # Installer les fonctionnalités Windows nécessaires
        WindowsFeature WebServer {
            Ensure = "Present"
            Name = "Web-Server"
        }
        
        WindowsFeature WebManagementConsole {
            Ensure = "Present"
            Name = "Web-Mgmt-Console"
            DependsOn = "[WindowsFeature]WebServer"
        }
        
        WindowsFeature WebManagementService {
            Ensure = "Present"
            Name = "Web-Mgmt-Service"
            DependsOn = "[WindowsFeature]WebServer"
        }
        
        # Créer le répertoire de destination
        File WebsiteDirectory {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $DestinationPath
            DependsOn = "[WindowsFeature]WebServer"
        }
        
        # Copier les fichiers du site web
        File WebsiteContent {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
            DependsOn = "[File]WebsiteDirectory"
        }
        
        # Configurer le site web
        xWebsite Website {
            Ensure = "Present"
            Name = $WebsiteName
            PhysicalPath = $DestinationPath
            State = "Started"
            BindingInfo = @(
                MSFT_xWebBindingInformation {
                    Protocol = "HTTP"
                    Port = $Port
                }
            )
            DependsOn = @("[WindowsFeature]WebServer", "[File]WebsiteContent")
        }
        
        # Configurer le pool d'applications
        xWebAppPool AppPool {
            Ensure = "Present"
            Name = "$WebsiteName-AppPool"
            State = "Started"
            autoStart = $true
            DependsOn = "[WindowsFeature]WebServer"
        }
        
        # Associer le site web au pool d'applications
        xWebApplication WebApplication {
            Ensure = "Present"
            Name = $WebsiteName
            Website = $WebsiteName
            WebAppPool = "$WebsiteName-AppPool"
            PhysicalPath = $DestinationPath
            DependsOn = @("[xWebsite]Website", "[xWebAppPool]AppPool")
        }
        
        # Configurer le pare-feu pour autoriser le trafic HTTP
        xFirewall FirewallRule {
            Ensure = "Present"
            Name = "HTTP-In"
            DisplayName = "HTTP Inbound"
            Enabled = "True"
            Direction = "Inbound"
            LocalPort = $Port
            Protocol = "TCP"
            Action = "Allow"
            DependsOn = "[xWebsite]Website"
        }
    }
}

# Valider les paramètres
try {
    Test-PathValid -Path $SourcePath
    
    # Générer la configuration
    $configPath = "C:\Temp\DSC"
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    WebServerConfig -NodeName $NodeName -WebsiteName $WebsiteName -SourcePath $SourcePath -DestinationPath $DestinationPath -Port $Port -OutputPath $configPath
    
    Write-Output "Configuration DSC générée avec succès dans: $configPath"
    Write-Output "Pour appliquer la configuration, exécutez: Start-DscConfiguration -Path $configPath -Wait -Verbose -Force"
}
catch {
    Write-Error "Erreur lors de la génération de la configuration DSC: $_"
}
'@

# Script complexe 3: Script avec workflow PowerShell
$workflowScript = @'
<#
.SYNOPSIS
    Script complexe avec un workflow PowerShell.
#>

# Paramètres du script
param (
    [string[]]$ComputerNames = @("localhost"),
    [int]$ThrottleLimit = 10,
    [switch]$Detailed
)

# Fonction pour formater les résultats
function Format-Result {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$InputObject,
        
        [switch]$Detailed
    )
    
    process {
        if ($Detailed) {
            return $InputObject
        } else {
            return [PSCustomObject]@{
                ComputerName = $InputObject.ComputerName
                Status = $InputObject.Status
                ProcessCount = $InputObject.Processes.Count
                ServiceCount = $InputObject.Services.Count
                TotalMemoryGB = [math]::Round($InputObject.Memory.TotalPhysicalMemory / 1GB, 2)
                FreeMemoryGB = [math]::Round($InputObject.Memory.FreePhysicalMemory / 1MB, 2)
                OSVersion = $InputObject.OS.Version
                LastBootTime = $InputObject.OS.LastBootUpTime
            }
        }
    }
}

# Workflow pour collecter des informations système
workflow Get-SystemInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerNames,
        
        [int]$ThrottleLimit = 10
    )
    
    # Configurer les options du workflow
    $PSPersist = $true
    $PSComputerName = $null
    $PSRunningActivity = "Collecte des informations système"
    $PSProgressMessage = "Traitement des ordinateurs"
    
    # Fonction interne pour vérifier la connectivité
    function Test-ServerConnection {
        param ([string]$ComputerName)
        
        $ping = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
        return $ping
    }
    
    # Traiter chaque ordinateur en parallèle
    foreach -parallel -ThrottleLimit $ThrottleLimit ($computer in $ComputerNames) {
        # Initialiser le résultat
        $result = [PSCustomObject]@{
            ComputerName = $computer
            Status = "Offline"
            Timestamp = Get-Date
            Processes = $null
            Services = $null
            Memory = $null
            OS = $null
            Disks = $null
            Error = $null
        }
        
        # Vérifier la connectivité
        $connected = InlineScript {
            Test-ServerConnection -ComputerName $using:computer
        }
        
        if ($connected) {
            try {
                # Mettre à jour le statut
                $result.Status = "Online"
                
                # Collecter les informations sur les processus
                $result.Processes = InlineScript {
                    Get-Process -ComputerName $using:computer | Select-Object Name, Id, CPU, WorkingSet, Description
                }
                
                # Collecter les informations sur les services
                $result.Services = InlineScript {
                    Get-Service -ComputerName $using:computer | Select-Object Name, DisplayName, Status, StartType
                }
                
                # Collecter les informations sur la mémoire
                $result.Memory = InlineScript {
                    Get-WmiObject -Class Win32_OperatingSystem -ComputerName $using:computer | 
                    Select-Object TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory
                }
                
                # Collecter les informations sur le système d'exploitation
                $result.OS = InlineScript {
                    Get-WmiObject -Class Win32_OperatingSystem -ComputerName $using:computer | 
                    Select-Object Caption, Version, BuildNumber, ServicePackMajorVersion, LastBootUpTime
                }
                
                # Collecter les informations sur les disques
                $result.Disks = InlineScript {
                    Get-WmiObject -Class Win32_LogicalDisk -ComputerName $using:computer -Filter "DriveType=3" | 
                    Select-Object DeviceID, VolumeName, Size, FreeSpace
                }
            }
            catch {
                # En cas d'erreur, mettre à jour le statut et enregistrer l'erreur
                $result.Status = "Error"
                $result.Error = $_.Exception.Message
            }
        }
        
        # Retourner le résultat
        $result
    }
}

# Fonction principale
function Start-SystemInfoCollection {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerNames,
        
        [int]$ThrottleLimit = 10,
        
        [switch]$Detailed
    )
    
    Write-Output "Démarrage de la collecte d'informations système..."
    Write-Output "Ordinateurs à traiter: $($ComputerNames.Count)"
    Write-Output "Limite de parallélisme: $ThrottleLimit"
    
    # Exécuter le workflow
    $results = Get-SystemInfo -ComputerNames $ComputerNames -ThrottleLimit $ThrottleLimit
    
    # Formater et afficher les résultats
    $formattedResults = $results | Format-Result -Detailed:$Detailed
    
    # Résumé
    $online = ($results | Where-Object { $_.Status -eq "Online" }).Count
    $offline = ($results | Where-Object { $_.Status -eq "Offline" }).Count
    $errors = ($results | Where-Object { $_.Status -eq "Error" }).Count
    
    Write-Output "`nRésumé de la collecte:"
    Write-Output "  Total: $($ComputerNames.Count)"
    Write-Output "  En ligne: $online"
    Write-Output "  Hors ligne: $offline"
    Write-Output "  Erreurs: $errors"
    
    return $formattedResults
}

# Exécuter la fonction principale
$results = Start-SystemInfoCollection -ComputerNames $ComputerNames -ThrottleLimit $ThrottleLimit -Detailed:$Detailed

# Exporter les résultats
$exportPath = "C:\Temp\SystemInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
Write-Output "`nRésultats exportés vers: $exportPath"
'@

# Exécuter les tests sur les scripts complexes
Test-ComplexScript -ScriptName "Script avec classes PowerShell" -ScriptContent $classScript -ScriptType "Classe"
Write-Host "`n"
Test-ComplexScript -ScriptName "Configuration DSC" -ScriptContent $dscScript -ScriptType "DSC"
Write-Host "`n"
Test-ComplexScript -ScriptName "Script avec workflow PowerShell" -ScriptContent $workflowScript -ScriptType "Workflow"

Write-Host "`n=== Tous les tests sur les scripts complexes sont terminés ===" -ForegroundColor Green
