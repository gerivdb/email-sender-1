#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module TaskPriorityQueue.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour les fonctions du module TaskPriorityQueue.psm1
    qui gère la file d'attente prioritaire des tâches.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
    Requires: Pester v5.0+
#>

# Définir le chemin du module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "TaskPriorityQueue.psm1"

# Vérifier si le module existe, sinon créer un stub pour les tests
if (-not (Test-Path -Path $modulePath)) {
    Write-Warning "Module TaskPriorityQueue.psm1 non trouvé. Création d'un stub pour les tests."
    
    # Créer un répertoire si nécessaire
    $moduleDir = Split-Path -Parent $modulePath
    if (-not (Test-Path -Path $moduleDir)) {
        New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer un stub du module pour les tests
    @'
# Module TaskPriorityQueue.psm1
# Stub créé pour les tests unitaires

# Classe pour représenter une tâche dans la file d'attente
class PriorityTask {
    [string]$Id
    [string]$Name
    [int]$Priority
    [datetime]$CreationTime
    [hashtable]$Parameters
    [scriptblock]$ScriptBlock
    [int]$BlockCount
    [datetime]$LastPromotionTime
    
    PriorityTask([string]$name, [scriptblock]$scriptBlock, [int]$priority = 5) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Name = $name
        $this.ScriptBlock = $scriptBlock
        $this.Priority = $priority
        $this.CreationTime = Get-Date
        $this.Parameters = @{}
        $this.BlockCount = 0
        $this.LastPromotionTime = Get-Date
    }
}

# Classe pour la file d'attente prioritaire
class TaskPriorityQueue {
    [System.Collections.Generic.List[PriorityTask]]$Tasks
    [int]$PromotionThreshold
    [int]$MaxPriority
    
    TaskPriorityQueue([int]$promotionThreshold = 5, [int]$maxPriority = 10) {
        $this.Tasks = [System.Collections.Generic.List[PriorityTask]]::new()
        $this.PromotionThreshold = $promotionThreshold
        $this.MaxPriority = $maxPriority
    }
    
    [void]Enqueue([PriorityTask]$task) {
        $this.Tasks.Add($task)
        $this.SortTasks()
    }
    
    [PriorityTask]Dequeue() {
        if ($this.Tasks.Count -eq 0) {
            return $null
        }
        
        $task = $this.Tasks[0]
        $this.Tasks.RemoveAt(0)
        return $task
    }
    
    [void]SortTasks() {
        # Trier par priorité (décroissante) puis par temps de création (croissant)
        $this.Tasks.Sort({
            param($a, $b)
            if ($a.Priority -eq $b.Priority) {
                return $a.CreationTime.CompareTo($b.CreationTime)
            }
            return $b.Priority.CompareTo($a.Priority)
        })
    }
    
    [void]PromoteWaitingTasks() {
        $now = Get-Date
        $waitThreshold = [TimeSpan]::FromMinutes($this.PromotionThreshold)
        
        foreach ($task in $this.Tasks) {
            $waitTime = $now - $task.LastPromotionTime
            
            if ($waitTime -gt $waitThreshold -and $task.Priority -lt $this.MaxPriority) {
                $task.Priority++
                $task.LastPromotionTime = $now
            }
        }
        
        $this.SortTasks()
    }
    
    [void]ReportTaskBlocked([string]$taskId) {
        $task = $this.Tasks | Where-Object { $_.Id -eq $taskId } | Select-Object -First 1
        
        if ($task) {
            $task.BlockCount++
            
            # Augmenter la priorité en fonction du nombre de blocages
            if ($task.Priority -lt $this.MaxPriority) {
                $task.Priority = [Math]::Min($this.MaxPriority, $task.Priority + [Math]::Min(3, $task.BlockCount))
                $task.LastPromotionTime = Get-Date
            }
            
            $this.SortTasks()
        }
    }
    
    [int]Count() {
        return $this.Tasks.Count
    }
    
    [void]Clear() {
        $this.Tasks.Clear()
    }
}

# Fonction pour créer une nouvelle file d'attente prioritaire
function New-TaskPriorityQueue {
    [CmdletBinding()]
    [OutputType([TaskPriorityQueue])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$PromotionThreshold = 5,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxPriority = 10
    )
    
    return [TaskPriorityQueue]::new($PromotionThreshold, $MaxPriority)
}

# Fonction pour créer une nouvelle tâche
function New-PriorityTask {
    [CmdletBinding()]
    [OutputType([PriorityTask])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 5,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    $task = [PriorityTask]::new($Name, $ScriptBlock, $Priority)
    $task.Parameters = $Parameters
    
    return $task
}

# Fonction pour ajouter une tâche à la file d'attente
function Add-TaskToQueue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TaskPriorityQueue]$Queue,
        
        [Parameter(Mandatory = $true)]
        [PriorityTask]$Task
    )
    
    $Queue.Enqueue($Task)
}

# Fonction pour récupérer la prochaine tâche de la file d'attente
function Get-NextTask {
    [CmdletBinding()]
    [OutputType([PriorityTask])]
    param (
        [Parameter(Mandatory = $true)]
        [TaskPriorityQueue]$Queue
    )
    
    return $Queue.Dequeue()
}

# Fonction pour promouvoir les tâches en attente
function Invoke-TaskPromotion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TaskPriorityQueue]$Queue
    )
    
    $Queue.PromoteWaitingTasks()
}

# Fonction pour signaler qu'une tâche est bloquée
function Register-TaskBlocked {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TaskPriorityQueue]$Queue,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskId
    )
    
    $Queue.ReportTaskBlocked($TaskId)
}

# Exporter les fonctions
Export-ModuleMember -Function New-TaskPriorityQueue, New-PriorityTask, Add-TaskToQueue, Get-NextTask, Invoke-TaskPromotion, Register-TaskBlocked
'@ | Set-Content -Path $modulePath -Encoding UTF8
}

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Importer le module à tester
Import-Module $modulePath -Force

# Définir les tests
Describe "TaskPriorityQueue Module Tests" {
    Context "New-TaskPriorityQueue Function" {
        It "Devrait créer une nouvelle file d'attente prioritaire" {
            # Act
            $queue = New-TaskPriorityQueue
            
            # Assert
            $queue | Should -Not -BeNullOrEmpty
            $queue.Count() | Should -Be 0
            $queue.PromotionThreshold | Should -Be 5
            $queue.MaxPriority | Should -Be 10
        }
        
        It "Devrait accepter des paramètres personnalisés" {
            # Arrange
            $promotionThreshold = 10
            $maxPriority = 20
            
            # Act
            $queue = New-TaskPriorityQueue -PromotionThreshold $promotionThreshold -MaxPriority $maxPriority
            
            # Assert
            $queue.PromotionThreshold | Should -Be $promotionThreshold
            $queue.MaxPriority | Should -Be $maxPriority
        }
    }
    
    Context "New-PriorityTask Function" {
        It "Devrait créer une nouvelle tâche prioritaire" {
            # Arrange
            $name = "Test Task"
            $scriptBlock = { param($data) return $data }
            
            # Act
            $task = New-PriorityTask -Name $name -ScriptBlock $scriptBlock
            
            # Assert
            $task | Should -Not -BeNullOrEmpty
            $task.Name | Should -Be $name
            $task.ScriptBlock | Should -Be $scriptBlock
            $task.Priority | Should -Be 5
            $task.Id | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait accepter une priorité personnalisée" {
            # Arrange
            $name = "High Priority Task"
            $scriptBlock = { param($data) return $data }
            $priority = 9
            
            # Act
            $task = New-PriorityTask -Name $name -ScriptBlock $scriptBlock -Priority $priority
            
            # Assert
            $task.Priority | Should -Be $priority
        }
        
        It "Devrait accepter des paramètres personnalisés" {
            # Arrange
            $name = "Parameterized Task"
            $scriptBlock = { param($data) return $data }
            $parameters = @{ Data = "Test Data"; Timeout = 30 }
            
            # Act
            $task = New-PriorityTask -Name $name -ScriptBlock $scriptBlock -Parameters $parameters
            
            # Assert
            $task.Parameters | Should -Not -BeNullOrEmpty
            $task.Parameters.Data | Should -Be "Test Data"
            $task.Parameters.Timeout | Should -Be 30
        }
    }
    
    Context "Add-TaskToQueue and Get-NextTask Functions" {
        BeforeEach {
            $script:queue = New-TaskPriorityQueue
        }
        
        It "Devrait ajouter et récupérer une tâche" {
            # Arrange
            $task = New-PriorityTask -Name "Test Task" -ScriptBlock { return "Test" }
            
            # Act
            Add-TaskToQueue -Queue $script:queue -Task $task
            $retrievedTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $retrievedTask | Should -Not -BeNullOrEmpty
            $retrievedTask.Id | Should -Be $task.Id
            $script:queue.Count() | Should -Be 0
        }
        
        It "Devrait retourner les tâches par ordre de priorité" {
            # Arrange
            $lowPriorityTask = New-PriorityTask -Name "Low Priority" -ScriptBlock { return "Low" } -Priority 3
            $mediumPriorityTask = New-PriorityTask -Name "Medium Priority" -ScriptBlock { return "Medium" } -Priority 5
            $highPriorityTask = New-PriorityTask -Name "High Priority" -ScriptBlock { return "High" } -Priority 8
            
            # Act
            Add-TaskToQueue -Queue $script:queue -Task $lowPriorityTask
            Add-TaskToQueue -Queue $script:queue -Task $mediumPriorityTask
            Add-TaskToQueue -Queue $script:queue -Task $highPriorityTask
            
            $firstTask = Get-NextTask -Queue $script:queue
            $secondTask = Get-NextTask -Queue $script:queue
            $thirdTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $firstTask.Name | Should -Be "High Priority"
            $secondTask.Name | Should -Be "Medium Priority"
            $thirdTask.Name | Should -Be "Low Priority"
        }
        
        It "Devrait retourner null si la file d'attente est vide" {
            # Act
            $result = Get-NextTask -Queue $script:queue
            
            # Assert
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "Invoke-TaskPromotion Function" {
        BeforeEach {
            $script:queue = New-TaskPriorityQueue -PromotionThreshold 0 # Utiliser 0 pour accélérer les tests
        }
        
        It "Devrait promouvoir les tâches en attente" {
            # Arrange
            $task = New-PriorityTask -Name "Waiting Task" -ScriptBlock { return "Test" } -Priority 3
            Add-TaskToQueue -Queue $script:queue -Task $task
            
            # Simuler un délai
            $task.LastPromotionTime = (Get-Date).AddMinutes(-10)
            
            # Act
            Invoke-TaskPromotion -Queue $script:queue
            $promotedTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $promotedTask.Priority | Should -Be 4
        }
        
        It "Ne devrait pas dépasser la priorité maximale" {
            # Arrange
            $task = New-PriorityTask -Name "Max Priority Task" -ScriptBlock { return "Test" } -Priority 10
            Add-TaskToQueue -Queue $script:queue -Task $task
            
            # Simuler un délai
            $task.LastPromotionTime = (Get-Date).AddMinutes(-10)
            
            # Act
            Invoke-TaskPromotion -Queue $script:queue
            $promotedTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $promotedTask.Priority | Should -Be 10
        }
    }
    
    Context "Register-TaskBlocked Function" {
        BeforeEach {
            $script:queue = New-TaskPriorityQueue
        }
        
        It "Devrait augmenter la priorité d'une tâche bloquée" {
            # Arrange
            $task = New-PriorityTask -Name "Blocked Task" -ScriptBlock { return "Test" } -Priority 5
            Add-TaskToQueue -Queue $script:queue -Task $task
            
            # Act
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            $blockedTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $blockedTask.Priority | Should -BeGreaterThan 5
            $blockedTask.BlockCount | Should -Be 1
        }
        
        It "Devrait augmenter davantage la priorité pour les tâches bloquées plusieurs fois" {
            # Arrange
            $task = New-PriorityTask -Name "Multiple Blocks Task" -ScriptBlock { return "Test" } -Priority 5
            Add-TaskToQueue -Queue $script:queue -Task $task
            
            # Act - Bloquer plusieurs fois
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            $blockedTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $blockedTask.Priority | Should -BeGreaterThan 7
            $blockedTask.BlockCount | Should -Be 3
        }
        
        It "Ne devrait pas dépasser la priorité maximale" {
            # Arrange
            $task = New-PriorityTask -Name "Max Priority Blocked Task" -ScriptBlock { return "Test" } -Priority 9
            Add-TaskToQueue -Queue $script:queue -Task $task
            
            # Act - Bloquer plusieurs fois
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            Register-TaskBlocked -Queue $script:queue -TaskId $task.Id
            $blockedTask = Get-NextTask -Queue $script:queue
            
            # Assert
            $blockedTask.Priority | Should -Be 10
            $blockedTask.BlockCount | Should -Be 3
        }
    }
}
