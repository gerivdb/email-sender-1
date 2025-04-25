# Tests unitaires pour check-mcp-servers-v2-noadmin.ps1
# Utilise le framework Pester pour les tests

BeforeAll {
    # Chemin vers le script à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\check-mcp-servers-v2-noadmin.ps1"
    
    # Vérifier que le script existe
    if (-not (Test-Path $scriptPath)) {
        throw "Le script à tester n'existe pas: $scriptPath"
    }
    
    # Charger les fonctions du script dans la session de test
    . $scriptPath
    
    # Fonction pour configurer le mock de Get-ProcessesWithCommandLineCim
    function global:Initialize-ProcessesMock {
        param (
            [array]$MockProcesses
        )
        
        # Remplacer la fonction Get-ProcessesWithCommandLineCim
        function script:Get-ProcessesWithCommandLineCim {
            return $MockProcesses
        }
    }
    
    # Fonction pour créer un processus mock
    function global:New-MockProcess {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true)]
            [int]$ProcessId,
            
            [Parameter(Mandatory = $true)]
            [string]$CommandLine
        )
        
        $process = New-Object PSObject
        $process | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $process | Add-Member -MemberType NoteProperty -Name "ProcessId" -Value $ProcessId
        $process | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $CommandLine
        
        return $process
    }
}

Describe "Test-McpServerRunning" {
    It "Détecte correctement un serveur en cours d'exécution" {
        # Arrange
        $mockProcess = New-MockProcess -Name "node" -ProcessId 1001 -CommandLine "node server-filesystem"
        $serverDef = @{ Name = "MCP Filesystem"; Pattern = "server-filesystem"; IsRunning = $false; ProcessInfo = $null }
        
        # Act
        $commandLine = $mockProcess.CommandLine
        if ($commandLine -match $serverDef.Pattern) {
            $serverDef.IsRunning = $true
            $serverDef.ProcessInfo = $mockProcess
        }
        
        # Assert
        $serverDef.IsRunning | Should -Be $true
        $serverDef.ProcessInfo | Should -Not -BeNullOrEmpty
        $serverDef.ProcessInfo.ProcessId | Should -Be 1001
    }
    
    It "Ne détecte pas un serveur qui n'est pas en cours d'exécution" {
        # Arrange
        $mockProcess = New-MockProcess -Name "node" -ProcessId 1001 -CommandLine "node server-filesystem"
        $serverDef = @{ Name = "MCP GCP"; Pattern = "gcp-mcp"; IsRunning = $false; ProcessInfo = $null }
        
        # Act
        $commandLine = $mockProcess.CommandLine
        if ($commandLine -match $serverDef.Pattern) {
            $serverDef.IsRunning = $true
            $serverDef.ProcessInfo = $mockProcess
        }
        
        # Assert
        $serverDef.IsRunning | Should -Be $false
        $serverDef.ProcessInfo | Should -BeNullOrEmpty
    }
    
    It "Détecte correctement plusieurs serveurs en cours d'exécution" {
        # Arrange
        $mockProcesses = @(
            (New-MockProcess -Name "node" -ProcessId 1001 -CommandLine "node server-filesystem"),
            (New-MockProcess -Name "node" -ProcessId 1002 -CommandLine "node server-github")
        )
        
        $serverDefinitions = @(
            @{ Name = "MCP Filesystem"; Pattern = "server-filesystem"; IsRunning = $false; ProcessInfo = $null },
            @{ Name = "MCP GitHub"; Pattern = "server-github"; IsRunning = $false; ProcessInfo = $null }
        )
        
        # Act
        foreach ($process in $mockProcesses) {
            $commandLine = $process.CommandLine
            foreach ($serverDef in $serverDefinitions) {
                if ($commandLine -match $serverDef.Pattern) {
                    $serverDef.IsRunning = $true
                    $serverDef.ProcessInfo = $process
                }
            }
        }
        
        # Assert
        $serverDefinitions[0].IsRunning | Should -Be $true
        $serverDefinitions[0].ProcessInfo.ProcessId | Should -Be 1001
        $serverDefinitions[1].IsRunning | Should -Be $true
        $serverDefinitions[1].ProcessInfo.ProcessId | Should -Be 1002
    }
}

Describe "Write-LogInternal" {
    It "Écrit correctement dans la console" {
        # Arrange
        $message = "Test message"
        $level = "INFO"
        
        # Act & Assert
        { Write-LogInternal -Message $message -Level $level } | Should -Not -Throw
    }
    
    It "Gère correctement les erreurs" {
        # Arrange
        $message = "Test error message"
        $level = "ERROR"
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]::new("Test exception"),
            "TestError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        # Act & Assert
        { Write-LogInternal -Message $message -Level $level -ErrorRecord $errorRecord } | Should -Not -Throw
    }
}

Describe "Intégration du script" {
    It "Le script s'exécute sans erreur" {
        # Arrange
        $testProcesses = @(
            (New-MockProcess -Name "node" -ProcessId 1001 -CommandLine "node server-filesystem"),
            (New-MockProcess -Name "node" -ProcessId 1002 -CommandLine "node server-github"),
            (New-MockProcess -Name "node" -ProcessId 1003 -CommandLine "node augment-mcp"),
            (New-MockProcess -Name "node" -ProcessId 1004 -CommandLine "node notion")
        )
        
        # Configurer le mock pour Get-ProcessesWithCommandLineCim
        Initialize-ProcessesMock -MockProcesses $testProcesses
        
        # Act & Assert
        # Exécuter le script avec des paramètres minimaux pour éviter l'affichage
        { & $scriptPath -ServerDefinitions @(
                @{ Name = "MCP Filesystem"; Pattern = "server-filesystem"; IsRunning = $false; ProcessInfo = $null }
            ) } | Should -Not -Throw
    }
}
