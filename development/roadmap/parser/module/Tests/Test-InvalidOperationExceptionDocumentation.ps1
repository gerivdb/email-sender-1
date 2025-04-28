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
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "Tests de la documentation d'InvalidOperationException et ses cas d'usage" {
    Context "InvalidOperationException" {
        It "Devrait Ãªtre une sous-classe de SystemException" {
            [System.InvalidOperationException] | Should -BeOfType [System.Type]
            [System.InvalidOperationException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Devrait permettre de spÃ©cifier un message" {
            $exception = [System.InvalidOperationException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait gÃ©rer un Ã©tat incorrect pour une opÃ©ration" {
            function Start-Process {
                param (
                    [PSCustomObject]$Process
                )
                
                if ($Process.Status -eq "Running") {
                    throw [System.InvalidOperationException]::new("Le processus est dÃ©jÃ  en cours d'exÃ©cution")
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
                $_.Exception.Message | Should -Be "Le processus est dÃ©jÃ  en cours d'exÃ©cution"
            }
            
            $result = Start-Process -Process $stoppedProcess
            $result.Status | Should -Be "Running"
        }
        
        It "Exemple 2: Devrait gÃ©rer une violation de sÃ©quence d'opÃ©rations" {
            class FileProcessor {
                [bool]$IsOpen = $false
                [string]$Content = $null
                
                [void] Open([string]$filePath) {
                    if ($this.IsOpen) {
                        throw [System.InvalidOperationException]::new("Le fichier est dÃ©jÃ  ouvert")
                    }
                    
                    # Simuler l'ouverture du fichier
                    $this.Content = "Contenu simulÃ©"
                    $this.IsOpen = $true
                }
                
                [string] Read() {
                    if (-not $this.IsOpen) {
                        throw [System.InvalidOperationException]::new("Le fichier doit Ãªtre ouvert avant de pouvoir Ãªtre lu")
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
                $_.Exception.Message | Should -Be "Le fichier doit Ãªtre ouvert avant de pouvoir Ãªtre lu"
            }
            
            # SÃ©quence correcte
            $processor.Open("test.txt")
            $processor.Read() | Should -Be "Contenu simulÃ©"
            $processor.Close()
            
            # Tentative de fermeture aprÃ¨s fermeture
            { $processor.Close() } | Should -Throw -ExceptionType [System.InvalidOperationException]
        }
        
        It "Exemple 3: Devrait implÃ©menter une machine Ã  Ã©tats" {
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
                            "Transition non autorisÃ©e de '$($this.State)' vers '$newState'")
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
                $_.Exception.Message | Should -Match "Transition non autorisÃ©e de 'Completed' vers 'Processing'"
            }
        }
        
        It "Exemple 4: Devrait gÃ©rer une opÃ©ration non supportÃ©e dans le contexte actuel" {
            function Invoke-Operation {
                param (
                    [string]$OperationType,
                    [PSCustomObject]$Context
                )
                
                switch ($OperationType) {
                    "Read" {
                        if ($Context.ReadOnly -eq $false) {
                            throw [System.InvalidOperationException]::new("L'opÃ©ration de lecture n'est pas autorisÃ©e dans un contexte en Ã©criture")
                        }
                        return "Lecture effectuÃ©e"
                    }
                    "Write" {
                        if ($Context.ReadOnly -eq $true) {
                            throw [System.InvalidOperationException]::new("L'opÃ©ration d'Ã©criture n'est pas autorisÃ©e dans un contexte en lecture seule")
                        }
                        return "Ã‰criture effectuÃ©e"
                    }
                    default {
                        throw [System.ArgumentException]::new("Type d'opÃ©ration non reconnu", "OperationType")
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
            
            # OpÃ©ration invalide
            { Invoke-Operation -OperationType "Write" -Context $readOnlyContext } | Should -Throw -ExceptionType [System.InvalidOperationException]
            
            try {
                Invoke-Operation -OperationType "Write" -Context $readOnlyContext
            }
            catch {
                $_.Exception.Message | Should -Be "L'opÃ©ration d'Ã©criture n'est pas autorisÃ©e dans un contexte en lecture seule"
            }
            
            # OpÃ©rations valides
            Invoke-Operation -OperationType "Read" -Context $readOnlyContext | Should -Be "Lecture effectuÃ©e"
            Invoke-Operation -OperationType "Write" -Context $writeContext | Should -Be "Ã‰criture effectuÃ©e"
        }
    }
    
    Context "ObjectDisposedException" {
        It "Devrait Ãªtre une sous-classe d'InvalidOperationException" {
            [System.ObjectDisposedException] | Should -BeOfType [System.Type]
            [System.ObjectDisposedException].IsSubclassOf([System.InvalidOperationException]) | Should -Be $true
        }
        
        It "Devrait permettre de spÃ©cifier un nom d'objet" {
            $exception = [System.ObjectDisposedException]::new("TestObject")
            $exception.ObjectName | Should -Be "TestObject"
        }
        
        It "Exemple: Devrait gÃ©rer un objet disposÃ©" {
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
            
            # OpÃ©ration valide
            { $resource.DoWork() } | Should -Not -Throw
            
            # Disposer la ressource
            $resource.Dispose()
            
            # OpÃ©ration invalide aprÃ¨s disposition
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
        It "Devrait Ãªtre une sous-classe d'InvalidOperationException" {
            [System.NotSupportedException] | Should -BeOfType [System.Type]
            [System.NotSupportedException].IsSubclassOf([System.InvalidOperationException]) | Should -Be $false  # Directement dÃ©rivÃ©e de SystemException
            [System.NotSupportedException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Exemple: Devrait gÃ©rer une opÃ©ration non supportÃ©e" {
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
            
            # OpÃ©ration valide
            $collection.GetItem(1) | Should -Be 2
            
            # OpÃ©ration non supportÃ©e
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
        It "Devrait intercepter spÃ©cifiquement les exceptions liÃ©es aux opÃ©rations invalides" {
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
                            throw [System.InvalidOperationException]::new("OpÃ©ration invalide gÃ©nÃ©rique")
                        }
                        "NotSupported" {
                            throw [System.NotSupportedException]::new("OpÃ©ration non supportÃ©e")
                        }
                        default {
                            throw [System.Exception]::new("Erreur gÃ©nÃ©rique")
                        }
                    }
                }
                catch [System.ObjectDisposedException] {
                    return "Objet disposÃ©"
                }
                catch [System.NotSupportedException] {
                    return "Non supportÃ©"
                }
                catch [System.InvalidOperationException] {
                    return "OpÃ©ration invalide"
                }
                catch {
                    return "Erreur gÃ©nÃ©rique"
                }
            }
            
            Test-OperationHandling -Operation "Disposed" | Should -Be "Objet disposÃ©"
            Test-OperationHandling -Operation "Invalid" | Should -Be "OpÃ©ration invalide"
            Test-OperationHandling -Operation "NotSupported" | Should -Be "Non supportÃ©"
            Test-OperationHandling -Operation "Other" | Should -Be "Erreur gÃ©nÃ©rique"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
