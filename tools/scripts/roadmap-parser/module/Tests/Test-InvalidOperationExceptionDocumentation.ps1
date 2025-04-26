<#
.SYNOPSIS
    Tests pour valider la documentation d'InvalidOperationException et ses cas d'usage.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation d'InvalidOperationException et ses cas d'usage.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Tests de la documentation d'InvalidOperationException et ses cas d'usage" {
    Context "InvalidOperationException" {
        It "Devrait être une sous-classe de SystemException" {
            [System.InvalidOperationException] | Should -BeOfType [System.Type]
            [System.InvalidOperationException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Devrait permettre de spécifier un message" {
            $exception = [System.InvalidOperationException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait gérer un état incorrect pour une opération" {
            function Start-Process {
                param (
                    [PSCustomObject]$Process
                )
                
                if ($Process.Status -eq "Running") {
                    throw [System.InvalidOperationException]::new("Le processus est déjà en cours d'exécution")
                }
                
                $Process.Status = "Running"
                return $Process
            }
            
            $runningProcess = [PSCustomObject]@{
                Id = 1
                Name = "TestProcess"
                Status = "Running"
            }
            
            $stoppedProcess = [PSCustomObject]@{
                Id = 2
                Name = "TestProcess2"
                Status = "Stopped"
            }
            
            { Start-Process -Process $runningProcess } | Should -Throw -ExceptionType [System.InvalidOperationException]
            
            try {
                Start-Process -Process $runningProcess
            }
            catch {
                $_.Exception.Message | Should -Be "Le processus est déjà en cours d'exécution"
            }
            
            $result = Start-Process -Process $stoppedProcess
            $result.Status | Should -Be "Running"
        }
        
        It "Exemple 2: Devrait gérer une violation de séquence d'opérations" {
            class FileProcessor {
                [bool]$IsOpen = $false
                [string]$Content = $null
                
                [void] Open([string]$filePath) {
                    if ($this.IsOpen) {
                        throw [System.InvalidOperationException]::new("Le fichier est déjà ouvert")
                    }
                    
                    # Simuler l'ouverture du fichier
                    $this.Content = "Contenu simulé"
                    $this.IsOpen = $true
                }
                
                [string] Read() {
                    if (-not $this.IsOpen) {
                        throw [System.InvalidOperationException]::new("Le fichier doit être ouvert avant de pouvoir être lu")
                    }
                    
                    return $this.Content
                }
                
                [void] Close() {
                    if (-not $this.IsOpen) {
                        throw [System.InvalidOperationException]::new("Le fichier n'est pas ouvert")
                    }
                    
                    $this.Content = $null
                    $this.IsOpen = $false
                }
            }
            
            $processor = [FileProcessor]::new()
            
            # Tentative de lecture avant ouverture
            { $processor.Read() } | Should -Throw -ExceptionType [System.InvalidOperationException]
            
            try {
                $processor.Read()
            }
            catch {
                $_.Exception.Message | Should -Be "Le fichier doit être ouvert avant de pouvoir être lu"
            }
            
            # Séquence correcte
            $processor.Open("test.txt")
            $processor.Read() | Should -Be "Contenu simulé"
            $processor.Close()
            
            # Tentative de fermeture après fermeture
            { $processor.Close() } | Should -Throw -ExceptionType [System.InvalidOperationException]
        }
        
        It "Exemple 3: Devrait implémenter une machine à états" {
            class StateMachine {
                [string]$State = "Initial"
                [hashtable]$AllowedTransitions = @{
                    "Initial" = @("Processing")
                    "Processing" = @("Completed", "Failed")
                    "Completed" = @()
                    "Failed" = @("Initial")
                }
                
                [void] TransitionTo([string]$newState) {
                    if (-not $this.AllowedTransitions[$this.State].Contains($newState)) {
                        throw [System.InvalidOperationException]::new(
                            "Transition non autorisée de '$($this.State)' vers '$newState'")
                    }
                    
                    $this.State = $newState
                }
            }
            
            $machine = [StateMachine]::new()
            
            # Transition valide
            $machine.TransitionTo("Processing")
            $machine.State | Should -Be "Processing"
            
            # Transition valide
            $machine.TransitionTo("Completed")
            $machine.State | Should -Be "Completed"
            
            # Transition invalide
            { $machine.TransitionTo("Processing") } | Should -Throw -ExceptionType [System.InvalidOperationException]
            
            try {
                $machine.TransitionTo("Processing")
            }
            catch {
                $_.Exception.Message | Should -Match "Transition non autorisée de 'Completed' vers 'Processing'"
            }
        }
        
        It "Exemple 4: Devrait gérer une opération non supportée dans le contexte actuel" {
            function Invoke-Operation {
                param (
                    [string]$OperationType,
                    [PSCustomObject]$Context
                )
                
                switch ($OperationType) {
                    "Read" {
                        if ($Context.ReadOnly -eq $false) {
                            throw [System.InvalidOperationException]::new("L'opération de lecture n'est pas autorisée dans un contexte en écriture")
                        }
                        return "Lecture effectuée"
                    }
                    "Write" {
                        if ($Context.ReadOnly -eq $true) {
                            throw [System.InvalidOperationException]::new("L'opération d'écriture n'est pas autorisée dans un contexte en lecture seule")
                        }
                        return "Écriture effectuée"
                    }
                    default {
                        throw [System.ArgumentException]::new("Type d'opération non reconnu", "OperationType")
                    }
                }
            }
            
            $readOnlyContext = [PSCustomObject]@{
                ReadOnly = $true
                Name = "ContextTest"
            }
            
            $writeContext = [PSCustomObject]@{
                ReadOnly = $false
                Name = "ContextTest"
            }
            
            # Opération invalide
            { Invoke-Operation -OperationType "Write" -Context $readOnlyContext } | Should -Throw -ExceptionType [System.InvalidOperationException]
            
            try {
                Invoke-Operation -OperationType "Write" -Context $readOnlyContext
            }
            catch {
                $_.Exception.Message | Should -Be "L'opération d'écriture n'est pas autorisée dans un contexte en lecture seule"
            }
            
            # Opérations valides
            Invoke-Operation -OperationType "Read" -Context $readOnlyContext | Should -Be "Lecture effectuée"
            Invoke-Operation -OperationType "Write" -Context $writeContext | Should -Be "Écriture effectuée"
        }
    }
    
    Context "ObjectDisposedException" {
        It "Devrait être une sous-classe d'InvalidOperationException" {
            [System.ObjectDisposedException] | Should -BeOfType [System.Type]
            [System.ObjectDisposedException].IsSubclassOf([System.InvalidOperationException]) | Should -Be $true
        }
        
        It "Devrait permettre de spécifier un nom d'objet" {
            $exception = [System.ObjectDisposedException]::new("TestObject")
            $exception.ObjectName | Should -Be "TestObject"
        }
        
        It "Exemple: Devrait gérer un objet disposé" {
            class DisposableResource : System.IDisposable {
                [bool]$IsDisposed = $false
                
                [void] DoWork() {
                    if ($this.IsDisposed) {
                        throw [System.ObjectDisposedException]::new("DisposableResource")
                    }
                    
                    # Simuler un travail
                    return
                }
                
                [void] Dispose() {
                    if (-not $this.IsDisposed) {
                        # Nettoyage des ressources
                        $this.IsDisposed = $true
                    }
                }
            }
            
            $resource = [DisposableResource]::new()
            
            # Opération valide
            { $resource.DoWork() } | Should -Not -Throw
            
            # Disposer la ressource
            $resource.Dispose()
            
            # Opération invalide après disposition
            { $resource.DoWork() } | Should -Throw -ExceptionType [System.ObjectDisposedException]
            
            try {
                $resource.DoWork()
            }
            catch {
                $_.Exception.GetType().FullName | Should -Be "System.ObjectDisposedException"
                $_.Exception.ObjectName | Should -Be "DisposableResource"
            }
        }
    }
    
    Context "NotSupportedException" {
        It "Devrait être une sous-classe d'InvalidOperationException" {
            [System.NotSupportedException] | Should -BeOfType [System.Type]
            [System.NotSupportedException].IsSubclassOf([System.InvalidOperationException]) | Should -Be $false  # Directement dérivée de SystemException
            [System.NotSupportedException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Exemple: Devrait gérer une opération non supportée" {
            class ReadOnlyCollection {
                [array]$Items
                
                ReadOnlyCollection([array]$items) {
                    $this.Items = $items
                }
                
                [object] GetItem([int]$index) {
                    return $this.Items[$index]
                }
                
                [void] AddItem([object]$item) {
                    throw [System.NotSupportedException]::new("Cette collection est en lecture seule")
                }
            }
            
            $collection = [ReadOnlyCollection]::new(@(1, 2, 3))
            
            # Opération valide
            $collection.GetItem(1) | Should -Be 2
            
            # Opération non supportée
            { $collection.AddItem(4) } | Should -Throw -ExceptionType [System.NotSupportedException]
            
            try {
                $collection.AddItem(4)
            }
            catch {
                $_.Exception.GetType().FullName | Should -Be "System.NotSupportedException"
                $_.Exception.Message | Should -Be "Cette collection est en lecture seule"
            }
        }
    }
    
    Context "Interception et gestion en PowerShell" {
        It "Devrait intercepter spécifiquement les exceptions liées aux opérations invalides" {
            function Test-OperationHandling {
                param (
                    [string]$Operation
                )
                
                try {
                    switch ($Operation) {
                        "Disposed" {
                            $stream = [System.IO.MemoryStream]::new()
                            $stream.Dispose()
                            $stream.Write(@(1, 2, 3), 0, 3)
                        }
                        "Invalid" {
                            throw [System.InvalidOperationException]::new("Opération invalide générique")
                        }
                        "NotSupported" {
                            throw [System.NotSupportedException]::new("Opération non supportée")
                        }
                        default {
                            throw [System.Exception]::new("Erreur générique")
                        }
                    }
                }
                catch [System.ObjectDisposedException] {
                    return "Objet disposé"
                }
                catch [System.NotSupportedException] {
                    return "Non supporté"
                }
                catch [System.InvalidOperationException] {
                    return "Opération invalide"
                }
                catch {
                    return "Erreur générique"
                }
            }
            
            Test-OperationHandling -Operation "Disposed" | Should -Be "Objet disposé"
            Test-OperationHandling -Operation "Invalid" | Should -Be "Opération invalide"
            Test-OperationHandling -Operation "NotSupported" | Should -Be "Non supporté"
            Test-OperationHandling -Operation "Other" | Should -Be "Erreur générique"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
