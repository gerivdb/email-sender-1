# Tests unitaires pour start-all-mcp-complete-v2.ps1
# Utilise le framework Pester pour les tests

BeforeAll {
    # Chemin vers le script à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\start-all-mcp-complete-v2.ps1"
    
    # Vérifier que le script existe
    if (-not (Test-Path $scriptPath)) {
        throw "Le script à tester n'existe pas: $scriptPath"
    }
    
    # Charger les fonctions du script dans la session de test
    . $scriptPath
}

Describe "Write-Log" {
    It "Écrit correctement dans la console" {
        # Arrange
        $message = "Test message"
        $level = "INFO"
        
        # Act & Assert
        { Write-Log -Message $message -Level $level } | Should -Not -Throw
    }
    
    It "Gère correctement les différents niveaux de log" {
        # Arrange
        $message = "Test message"
        $levels = @("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG", "TITLE")
        
        # Act & Assert
        foreach ($level in $levels) {
            { Write-Log -Message $message -Level $level } | Should -Not -Throw
        }
    }
}

Describe "Test-CommandExists" {
    It "Détecte correctement une commande existante" {
        # Arrange
        Mock Get-Command { return @{Name = "powershell"} }
        
        # Act
        $result = Test-CommandExists -Command "powershell"
        
        # Assert
        $result | Should -Be $true
    }
    
    It "Détecte correctement une commande inexistante" {
        # Arrange
        Mock Get-Command { return $null }
        
        # Act
        $result = Test-CommandExists -Command "commande-inexistante"
        
        # Assert
        $result | Should -Be $false
    }
}

Describe "Start-McpServer" {
    It "Démarre correctement un serveur MCP" {
        # Arrange
        Mock Test-CommandExists { return $true }
        Mock Start-Process { 
            $obj = New-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name "Id" -Value 1001
            return $obj
        }
        
        # Act
        $result = Start-McpServer -Name "Test Server" -Command "node" -Arguments @("server.js")
        
        # Assert
        $result | Should -Be $true
    }
    
    It "Gère correctement une commande inexistante" {
        # Arrange
        Mock Test-CommandExists { return $false }
        Mock npm { return $null }
        
        # Act
        $result = Start-McpServer -Name "Test Server" -Command "commande-inexistante"
        
        # Assert
        $result | Should -Be $false
    }
    
    It "Gère correctement une erreur lors du démarrage" {
        # Arrange
        Mock Test-CommandExists { return $true }
        Mock Start-Process { throw "Erreur de démarrage" }
        
        # Act
        $result = Start-McpServer -Name "Test Server" -Command "node" -Arguments @("server.js")
        
        # Assert
        $result | Should -Be $false
    }
}

Describe "Start-McpServerWithScript" {
    It "Démarre correctement un serveur MCP avec un script" {
        # Arrange
        Mock Test-Path { return $true }
        Mock Start-Process { 
            $obj = New-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name "Id" -Value 1001
            return $obj
        }
        
        # Act
        $result = Start-McpServerWithScript -Name "Test Server" -ScriptPath "test.cmd"
        
        # Assert
        $result | Should -Be $true
    }
    
    It "Gère correctement un script inexistant" {
        # Arrange
        Mock Test-Path { return $false }
        
        # Act
        $result = Start-McpServerWithScript -Name "Test Server" -ScriptPath "script-inexistant.cmd"
        
        # Assert
        $result | Should -Be $false
    }
    
    It "Gère correctement une erreur lors du démarrage" {
        # Arrange
        Mock Test-Path { return $true }
        Mock Start-Process { throw "Erreur de démarrage" }
        
        # Act
        $result = Start-McpServerWithScript -Name "Test Server" -ScriptPath "test.cmd"
        
        # Assert
        $result | Should -Be $false
    }
}
