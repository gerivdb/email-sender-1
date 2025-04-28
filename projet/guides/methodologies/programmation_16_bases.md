# Les 16 Bases de la Programmation

Ce document présente les 16 bases fondamentales de la programmation qui guident le développement de notre projet.

## 1. Modularité

La modularité consiste à diviser le code en modules indépendants et réutilisables. Chaque module doit avoir une responsabilité unique et bien définie.

**Principes clés :**
- Un module = une responsabilité
- Interfaces claires entre modules
- Faible couplage, forte cohésion
- Réutilisabilité des modules

**Exemple :**
```powershell
# Module de gestion des fichiers
function Get-FileContent { ... }
function Save-FileContent { ... }
function Test-FileExists { ... }
```

## 2. Abstraction

L'abstraction consiste à masquer les détails d'implémentation complexes derrière des interfaces simples et intuitives.

**Principes clés :**
- Cacher la complexité
- Exposer uniquement ce qui est nécessaire
- Interfaces stables et intuitives
- Séparation des préoccupations

**Exemple :**
```powershell
# Interface abstraite pour différentes sources de données
function Get-Data {
    param (
        [string]$Source,
        [string]$Query
    )
    
    switch ($Source) {
        "Database" { Get-DatabaseData -Query $Query }
        "API" { Get-APIData -Endpoint $Query }
        "File" { Get-FileData -Path $Query }
        default { throw "Source non supportée" }
    }
}
```

## 3. Encapsulation

L'encapsulation consiste à regrouper les données et les méthodes qui les manipulent dans une même unité, et à contrôler l'accès à ces données.

**Principes clés :**
- Regrouper données et comportements
- Contrôler l'accès aux données
- Protéger l'intégrité des données
- Cacher l'implémentation interne

**Exemple :**
```powershell
# Classe encapsulant les données d'un utilisateur
class User {
    [string]$Name
    [int]$Age
    hidden [string]$Password
    
    [void] SetPassword([string]$NewPassword) {
        # Validation et hachage du mot de passe
        $this.Password = (Get-Hash $NewPassword)
    }
    
    [bool] ValidatePassword([string]$InputPassword) {
        return (Get-Hash $InputPassword) -eq $this.Password
    }
}
```

## 4. Héritage

L'héritage permet à une classe de réutiliser les propriétés et méthodes d'une autre classe, facilitant la réutilisation du code et la création de hiérarchies.

**Principes clés :**
- Réutilisation du code
- Spécialisation des classes
- Hiérarchies de classes
- Polymorphisme

**Exemple :**
```powershell
# Classe de base
class Vehicle {
    [int]$Speed
    [string]$Color
    
    [void] Start() { ... }
    [void] Stop() { ... }
}

# Classe dérivée
class Car : Vehicle {
    [int]$Doors
    
    [void] Start() {
        # Surcharge de la méthode de base
        Write-Host "Démarrage de la voiture"
        ([Vehicle]$this).Start()
    }
    
    [void] OpenTrunk() { ... }
}
```

## 5. Polymorphisme

Le polymorphisme permet à des objets de différentes classes d'être traités comme des objets d'une classe commune, simplifiant le code et augmentant sa flexibilité.

**Principes clés :**
- Traitement uniforme d'objets différents
- Interfaces communes
- Surcharge de méthodes
- Extensibilité

**Exemple :**
```powershell
# Interface commune
class Shape {
    [double] Area() { return 0 }
    [double] Perimeter() { return 0 }
}

# Implémentations spécifiques
class Circle : Shape {
    [double]$Radius
    
    [double] Area() {
        return [Math]::PI * $this.Radius * $this.Radius
    }
    
    [double] Perimeter() {
        return 2 * [Math]::PI * $this.Radius
    }
}

class Rectangle : Shape {
    [double]$Width
    [double]$Height
    
    [double] Area() {
        return $this.Width * $this.Height
    }
    
    [double] Perimeter() {
        return 2 * ($this.Width + $this.Height)
    }
}

# Utilisation polymorphique
function PrintShapeInfo([Shape]$Shape) {
    Write-Host "Aire: $($Shape.Area())"
    Write-Host "Périmètre: $($Shape.Perimeter())"
}
```

## 6. Composition

La composition consiste à créer des objets complexes en combinant des objets plus simples, plutôt qu'en utilisant l'héritage.

**Principes clés :**
- Combiner des objets simples
- "A a" plutôt que "A est un"
- Flexibilité et adaptabilité
- Éviter les hiérarchies profondes

**Exemple :**
```powershell
# Composition d'objets
class Engine {
    [int]$Power
    [void] Start() { ... }
    [void] Stop() { ... }
}

class Transmission {
    [string]$Type
    [void] ChangeGear([int]$Gear) { ... }
}

class Car {
    [Engine]$Engine
    [Transmission]$Transmission
    [string]$Model
    
    Car([string]$Model) {
        $this.Model = $Model
        $this.Engine = [Engine]::new()
        $this.Transmission = [Transmission]::new()
    }
    
    [void] Start() {
        $this.Engine.Start()
    }
    
    [void] ChangeGear([int]$Gear) {
        $this.Transmission.ChangeGear($Gear)
    }
}
```

## 7. Interfaces

Les interfaces définissent un contrat que les classes doivent respecter, assurant qu'elles implémentent certaines méthodes et propriétés.

**Principes clés :**
- Définir des contrats
- Garantir l'implémentation de méthodes
- Permettre le polymorphisme
- Découpler les composants

**Exemple :**
```powershell
# Interface en PowerShell (simulation)
function Test-ImplementsInterface {
    param (
        [object]$Object,
        [string[]]$RequiredMethods,
        [string[]]$RequiredProperties
    )
    
    $allImplemented = $true
    
    foreach ($method in $RequiredMethods) {
        if (-not $Object.GetType().GetMethod($method)) {
            $allImplemented = $false
            break
        }
    }
    
    foreach ($property in $RequiredProperties) {
        if (-not $Object.GetType().GetProperty($property)) {
            $allImplemented = $false
            break
        }
    }
    
    return $allImplemented
}

# Utilisation
$requiredMethods = @("Connect", "Disconnect", "SendData")
$requiredProperties = @("IsConnected", "Name")

if (Test-ImplementsInterface -Object $device -RequiredMethods $requiredMethods -RequiredProperties $requiredProperties) {
    # L'objet implémente l'interface
}
```

## 8. Gestion des erreurs

La gestion des erreurs consiste à anticiper, détecter et traiter les situations exceptionnelles pour assurer la robustesse du code.

**Principes clés :**
- Anticiper les erreurs
- Valider les entrées
- Utiliser try/catch/finally
- Journaliser les erreurs

**Exemple :**
```powershell
function Get-UserData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId
    )
    
    # Validation des entrées
    if (-not [Guid]::TryParse($UserId, [ref]$null)) {
        throw [ArgumentException]::new("L'ID utilisateur doit être un GUID valide")
    }
    
    try {
        # Tentative d'accès à la base de données
        $connection = Open-DatabaseConnection
        $userData = $connection.Query("SELECT * FROM Users WHERE Id = @UserId", @{UserId = $UserId})
        return $userData
    }
    catch [System.Data.SqlClient.SqlException] {
        # Erreur spécifique à la base de données
        Write-Log -Level Error -Message "Erreur de base de données: $_"
        throw
    }
    catch {
        # Autres erreurs
        Write-Log -Level Error -Message "Erreur lors de la récupération des données utilisateur: $_"
        throw
    }
    finally {
        # Nettoyage, toujours exécuté
        if ($connection) {
            $connection.Close()
        }
    }
}
```

## 9. Tests unitaires

Les tests unitaires vérifient que chaque unité de code fonctionne correctement de manière isolée, assurant la qualité et facilitant la maintenance.

**Principes clés :**
- Tester chaque unité isolément
- Automatiser les tests
- Couvrir les cas normaux et limites
- Faciliter la régression

**Exemple :**
```powershell
# Fonction à tester
function Add-Numbers {
    param (
        [int]$A,
        [int]$B
    )
    
    return $A + $B
}

# Tests unitaires avec Pester
Describe "Add-Numbers" {
    It "Additionne correctement deux nombres positifs" {
        Add-Numbers -A 2 -B 3 | Should -Be 5
    }
    
    It "Gère correctement les nombres négatifs" {
        Add-Numbers -A -2 -B -3 | Should -Be -5
    }
    
    It "Gère correctement un nombre positif et un négatif" {
        Add-Numbers -A 2 -B -3 | Should -Be -1
    }
}
```

## 10. Documentation

La documentation explique comment utiliser et maintenir le code, facilitant la collaboration et la maintenance à long terme.

**Principes clés :**
- Documenter l'API publique
- Expliquer le pourquoi, pas seulement le comment
- Maintenir la documentation à jour
- Utiliser des formats standards

**Exemple :**
```powershell
<#
.SYNOPSIS
    Récupère les données d'un utilisateur à partir de son ID.

.DESCRIPTION
    Cette fonction interroge la base de données pour récupérer toutes les informations
    associées à un utilisateur spécifique. Elle gère les erreurs de connexion et de requête.

.PARAMETER UserId
    L'identifiant unique (GUID) de l'utilisateur à récupérer.

.EXAMPLE
    Get-UserData -UserId "12345678-1234-1234-1234-123456789012"
    
    Récupère les données de l'utilisateur avec l'ID spécifié.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
    Date de dernière modification: 2023-06-15
#>
function Get-UserData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId
    )
    
    # Implémentation...
}
```

## 11. Gestion de la configuration

La gestion de la configuration permet d'adapter le comportement du code sans le modifier, facilitant le déploiement dans différents environnements.

**Principes clés :**
- Externaliser la configuration
- Utiliser des fichiers de configuration
- Supporter différents environnements
- Sécuriser les informations sensibles

**Exemple :**
```powershell
# Chargement de la configuration
function Get-Configuration {
    param (
        [string]$Environment = "Development"
    )
    
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "../config/settings.$Environment.json"
    
    if (-not (Test-Path $configPath)) {
        throw "Configuration pour l'environnement '$Environment' introuvable"
    }
    
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    
    # Charger les secrets si nécessaire
    if ($config.UseSecrets) {
        $secretsPath = Join-Path -Path $PSScriptRoot -ChildPath "../config/secrets.$Environment.json"
        if (Test-Path $secretsPath) {
            $secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json
            # Fusionner les secrets avec la configuration
            $config | Add-Member -NotePropertyMembers $secrets
        }
    }
    
    return $config
}

# Utilisation
$config = Get-Configuration -Environment "Production"
$connectionString = $config.Database.ConnectionString
```

## 12. Journalisation

La journalisation enregistre les événements et les erreurs pendant l'exécution du code, facilitant le débogage et la surveillance.

**Principes clés :**
- Niveaux de journalisation (Debug, Info, Warning, Error)
- Formats structurés (JSON, XML)
- Rotation des journaux
- Filtrage et recherche

**Exemple :**
```powershell
# Module de journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile = "application.log",
        
        [Parameter(Mandatory = $false)]
        [switch]$Console
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = [PSCustomObject]@{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
        Source = (Get-PSCallStack)[1].Command
    }
    
    # Format JSON pour le fichier
    $jsonEntry = $logEntry | ConvertTo-Json -Compress
    
    # Ajouter au fichier
    Add-Content -Path $LogFile -Value $jsonEntry
    
    # Afficher dans la console si demandé
    if ($Console) {
        $color = switch ($Level) {
            "Debug" { "Gray" }
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            default { "White" }
        }
        
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

# Utilisation
Write-Log -Message "Démarrage de l'application" -Level Info -Console
try {
    # Code...
}
catch {
    Write-Log -Message "Erreur: $_" -Level Error -Console
}
```

## 13. Performance

L'optimisation des performances vise à améliorer la vitesse d'exécution, réduire l'utilisation des ressources et améliorer l'expérience utilisateur.

**Principes clés :**
- Mesurer avant d'optimiser
- Identifier les goulots d'étranglement
- Optimiser les algorithmes
- Utiliser la mise en cache

**Exemple :**
```powershell
# Mesure de performance
function Measure-ExecutionTime {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 1
    )
    
    $results = @()
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Exécuter le code
        & $ScriptBlock
        
        $stopwatch.Stop()
        $results += $stopwatch.ElapsedMilliseconds
    }
    
    # Calculer les statistiques
    $avg = ($results | Measure-Object -Average).Average
    $min = ($results | Measure-Object -Minimum).Minimum
    $max = ($results | Measure-Object -Maximum).Maximum
    
    return [PSCustomObject]@{
        AverageMs = $avg
        MinimumMs = $min
        MaximumMs = $max
        Iterations = $Iterations
    }
}

# Utilisation
$result = Measure-ExecutionTime -ScriptBlock {
    # Code à mesurer
    Get-Process | Where-Object { $_.CPU -gt 10 }
} -Iterations 10

Write-Host "Temps moyen: $($result.AverageMs) ms"
```

## 14. Sécurité

La sécurité protège le code et les données contre les accès non autorisés, les attaques et les vulnérabilités.

**Principes clés :**
- Valider toutes les entrées
- Principe du moindre privilège
- Chiffrer les données sensibles
- Auditer les accès

**Exemple :**
```powershell
# Validation des entrées
function Invoke-SafeCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments
    )
    
    # Liste blanche de commandes autorisées
    $allowedCommands = @("Get-Process", "Get-Service", "Get-ChildItem")
    
    if ($allowedCommands -notcontains $Command) {
        throw "Commande non autorisée: $Command"
    }
    
    # Valider les arguments
    foreach ($arg in $Arguments) {
        if ($arg -match "[;&|]") {
            throw "Argument non valide: $arg"
        }
    }
    
    # Exécuter la commande
    $scriptBlock = [scriptblock]::Create("$Command $($Arguments -join ' ')")
    return & $scriptBlock
}

# Chiffrement des données sensibles
function Protect-String {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String
    )
    
    $secureString = ConvertTo-SecureString -String $String -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $secureString
    
    return $encrypted
}

function Unprotect-String {
    param (
        [Parameter(Mandatory = $true)]
        [string]$EncryptedString
    )
    
    $secureString = ConvertTo-SecureString -String $EncryptedString
    $credential = New-Object System.Management.Automation.PSCredential("dummy", $secureString)
    
    return $credential.GetNetworkCredential().Password
}
```

## 15. Concurrence

La gestion de la concurrence permet d'exécuter plusieurs tâches simultanément, améliorant les performances et la réactivité.

**Principes clés :**
- Parallélisme et multithreading
- Synchronisation des accès
- Éviter les conditions de course
- Gestion des ressources partagées

**Exemple :**
```powershell
# Traitement parallèle
function Invoke-ParallelProcessing {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Items,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 5
    )
    
    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $pool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
    $pool.Open()
    
    $jobs = @()
    $results = @()
    
    foreach ($item in $Items) {
        $job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($item)
        $job.RunspacePool = $pool
        
        $jobs += [PSCustomObject]@{
            Pipe = $job
            Result = $job.BeginInvoke()
        }
    }
    
    # Récupérer les résultats
    foreach ($job in $jobs) {
        $results += $job.Pipe.EndInvoke($job.Result)
        $job.Pipe.Dispose()
    }
    
    # Fermer le pool
    $pool.Close()
    $pool.Dispose()
    
    return $results
}

# Utilisation
$files = Get-ChildItem -Path "C:\Data" -Filter "*.txt"
$results = Invoke-ParallelProcessing -Items $files -ScriptBlock {
    param($file)
    
    $content = Get-Content -Path $file.FullName
    return [PSCustomObject]@{
        FileName = $file.Name
        LineCount = $content.Count
        Size = $file.Length
    }
}
```

## 16. Versionnement

Le versionnement permet de suivre les modifications du code, de gérer les dépendances et de faciliter la collaboration.

**Principes clés :**
- Versionnement sémantique (SemVer)
- Gestion des dépendances
- Compatibilité ascendante
- Documentation des changements

**Exemple :**
```powershell
# Module avec versionnement
<#
.SYNOPSIS
    Module de gestion des utilisateurs
.DESCRIPTION
    Ce module fournit des fonctions pour gérer les utilisateurs dans le système.
.NOTES
    Version: 1.2.3
    Auteur: Équipe de développement
    Changelog:
    - 1.2.3: Correction de bugs dans Get-User
    - 1.2.0: Ajout de Remove-User
    - 1.1.0: Ajout de Update-User
    - 1.0.0: Version initiale avec Get-User et New-User
#>

# Vérification de compatibilité
function Test-ModuleCompatibility {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [version]$RequiredVersion,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoInstall
    )
    
    $module = Get-Module -Name $ModuleName -ListAvailable
    
    if (-not $module) {
        if ($AutoInstall) {
            Install-Module -Name $ModuleName -MinimumVersion $RequiredVersion -Force
            return $true
        }
        
        return $false
    }
    
    $latestVersion = $module | Sort-Object Version -Descending | Select-Object -First 1 -ExpandProperty Version
    
    if ($latestVersion -lt $RequiredVersion) {
        if ($AutoInstall) {
            Install-Module -Name $ModuleName -MinimumVersion $RequiredVersion -Force
            return $true
        }
        
        return $false
    }
    
    return $true
}

# Utilisation
if (-not (Test-ModuleCompatibility -ModuleName "UserManagement" -RequiredVersion "1.2.0")) {
    Write-Error "Ce script nécessite le module UserManagement v1.2.0 ou supérieur"
    exit 1
}
```

## Conclusion

Ces 16 bases de la programmation forment le socle de notre approche de développement. En les appliquant systématiquement, nous assurons la qualité, la maintenabilité et l'évolutivité de notre code.

Chaque mode opérationnel du projet s'appuie sur ces bases pour résoudre des problèmes spécifiques et accomplir des tâches particulières. La combinaison de ces bases et des modes opérationnels nous permet de développer efficacement et de maintenir notre code à long terme.
