<#
.SYNOPSIS
    ExÃ©cute le mode de livraison pour une tÃ¢che spÃ©cifique du roadmap.
.DESCRIPTION
    Cette fonction exÃ©cute le mode de livraison pour une tÃ¢che spÃ©cifique du roadmap,
    permettant d'implÃ©menter et de tester les fonctionnalitÃ©s.
.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  implÃ©menter.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap.
.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les fichiers gÃ©nÃ©rÃ©s.
.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire des tests.
.PARAMETER Force
    Si spÃ©cifiÃ©, force l'exÃ©cution sans demander de confirmation.
.EXAMPLE
    Invoke-RoadmapDelivery -TaskIdentifier "1.1" -RoadmapPath "Roadmap\roadmap.md"
    ExÃ©cute le mode de livraison pour la tÃ¢che 1.1.
.EXAMPLE
    Invoke-RoadmapDelivery -TaskIdentifier "1.1" -RoadmapPath "Roadmap\roadmap.md" -Force
    ExÃ©cute le mode de livraison pour la tÃ¢che 1.1 sans demander de confirmation.
#>
function Invoke-RoadmapDelivery {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter()]
        [string]$OutputPath = "output",
        
        [Parameter()]
        [string]$TestsPath = "tests",
        
        [Parameter()]
        [switch]$Force
    )
    
    # Initialiser le rÃ©sultat
    $result = @{
        Success = $false
        Errors = @()
        ImplementedFiles = @()
        TestFiles = @()
    }
    
    try {
        # VÃ©rifier si le fichier de roadmap existe
        if (-not (Test-Path -Path $RoadmapPath)) {
            throw "Le fichier de roadmap n'existe pas Ã  l'emplacement spÃ©cifiÃ© : $RoadmapPath"
        }
        
        # Lire le contenu du roadmap
        $roadmapContent = Get-Content -Path $RoadmapPath -Raw
        
        # Rechercher la tÃ¢che spÃ©cifiÃ©e
        $taskPattern = "(?m)^(\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s+.+?)(?=\n\s*[-*]\s*\[[ x]\]|\z)"
        $taskMatch = [regex]::Match($roadmapContent, $taskPattern)
        
        if (-not $taskMatch.Success) {
            throw "La tÃ¢che $TaskIdentifier n'a pas Ã©tÃ© trouvÃ©e dans le roadmap."
        }
        
        $taskContent = $taskMatch.Groups[1].Value
        Write-Host "TÃ¢che trouvÃ©e : $taskContent" -ForegroundColor Green
        
        # Extraire les sous-tÃ¢ches
        $subTaskPattern = "(?m)^\s+[-*]\s*\[[ x]\]\s*(.+)$"
        $subTasks = [regex]::Matches($taskContent, $subTaskPattern) | ForEach-Object { $_.Groups[1].Value }
        
        if ($subTasks.Count -eq 0) {
            Write-Warning "Aucune sous-tÃ¢che trouvÃ©e pour la tÃ¢che $TaskIdentifier."
        } else {
            Write-Host "Sous-tÃ¢ches trouvÃ©es :" -ForegroundColor Green
            foreach ($subTask in $subTasks) {
                Write-Host "  - $subTask" -ForegroundColor Green
            }
        }
        
        # CrÃ©er les rÃ©pertoires de sortie si nÃ©cessaire
        if (-not (Test-Path -Path $OutputPath)) {
            if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie")) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath" -ForegroundColor Green
            }
        }
        
        if (-not (Test-Path -Path $TestsPath)) {
            if ($PSCmdlet.ShouldProcess($TestsPath, "CrÃ©er le rÃ©pertoire de tests")) {
                New-Item -Path $TestsPath -ItemType Directory -Force | Out-Null
                Write-Host "RÃ©pertoire de tests crÃ©Ã© : $TestsPath" -ForegroundColor Green
            }
        }
        
        # ImplÃ©menter les sous-tÃ¢ches
        foreach ($subTask in $subTasks) {
            Write-Host "ImplÃ©mentation de la sous-tÃ¢che : $subTask" -ForegroundColor Cyan
            
            # GÃ©nÃ©rer un nom de fichier basÃ© sur la sous-tÃ¢che
            $fileName = $subTask -replace '[^\w\-]', '_'
            $fileName = $fileName -replace '_+', '_'
            $fileName = $fileName.Trim('_')
            
            # CrÃ©er le fichier d'implÃ©mentation
            $implementationFile = Join-Path -Path $OutputPath -ChildPath "$fileName.ps1"
            
            if ($PSCmdlet.ShouldProcess($implementationFile, "CrÃ©er le fichier d'implÃ©mentation")) {
                $implementationContent = @"
<#
.SYNOPSIS
    ImplÃ©mentation de la sous-tÃ¢che : $subTask
.DESCRIPTION
    Cette fonction implÃ©mente la sous-tÃ¢che : $subTask
    de la tÃ¢che $TaskIdentifier du roadmap.
.EXAMPLE
    $fileName
    ExÃ©cute l'implÃ©mentation de la sous-tÃ¢che.
#>
function $fileName {
    [CmdletBinding()]
    param (
        # ParamÃ¨tres de la fonction
    )
    
    # ImplÃ©mentation de la sous-tÃ¢che
    Write-Host "ExÃ©cution de la sous-tÃ¢che : $subTask" -ForegroundColor Green
    
    # TODO: ImplÃ©menter la sous-tÃ¢che
    
    return $true
}
"@
                
                Set-Content -Path $implementationFile -Value $implementationContent -Encoding UTF8
                Write-Host "Fichier d'implÃ©mentation crÃ©Ã© : $implementationFile" -ForegroundColor Green
                $result.ImplementedFiles += $implementationFile
            }
            
            # CrÃ©er le fichier de test
            $testFile = Join-Path -Path $TestsPath -ChildPath "Test-$fileName.ps1"
            
            if ($PSCmdlet.ShouldProcess($testFile, "CrÃ©er le fichier de test")) {
                $testContent = @"
# Tests pour la sous-tÃ¢che : $subTask

# Importer la fonction Ã  tester
. "$OutputPath\$fileName.ps1"

Describe "$fileName" {
    It "Should execute without errors" {
        { $fileName } | Should -Not -Throw
    }
    
    It "Should return true" {
        $fileName | Should -Be $true
    }
    
    # TODO: Ajouter des tests spÃ©cifiques pour la sous-tÃ¢che
}
"@
                
                Set-Content -Path $testFile -Value $testContent -Encoding UTF8
                Write-Host "Fichier de test crÃ©Ã© : $testFile" -ForegroundColor Green
                $result.TestFiles += $testFile
            }
        }
        
        $result.Success = $true
        return $result
    } catch {
        $errorMessage = "Erreur lors de l'exÃ©cution du mode de livraison pour la tÃ¢che $TaskIdentifier : $_"
        Write-Error $errorMessage
        
        $result.Errors += $errorMessage
        return $result
    }
}
