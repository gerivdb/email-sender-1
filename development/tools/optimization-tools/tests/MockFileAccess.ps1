<#
.SYNOPSIS
    Mocks pour les fonctions d'accÃ¨s aux fichiers.
.DESCRIPTION
    Ce script contient des mocks pour les fonctions d'accÃ¨s aux fichiers.
#>

# Mock pour Test-Path
function Test-MockPath {
    param (
        [string]$Path
    )

    # Simuler l'existence de certains fichiers
    if ($Path -like "*Test1.ps1" -or $Path -like "*Test2.ps1" -or $Path -like "*Test3.ps1") {
        return $true
    }

    # Simuler l'existence de certains dossiers
    if ($Path -like "*\TestReports" -or $Path -like "*\UsageData") {
        return $true
    }

    # Par dÃ©faut, retourner false
    return $false
}

# Mock pour Get-Content
function Get-MockContent {
    param (
        [string]$Path,
        [switch]$Raw
    )

    # Simuler le contenu de certains fichiers
    if ($Path -like "*Test1.ps1") {
        if ($Raw) {
            return @'
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputData
    )

    # Utilisation de la parallÃ©lisation
    $results = $InputData | ForEach-Object -Parallel {
        # Traitement parallÃ¨le
        Start-Sleep -Milliseconds 100
        return "Processed: $_"
    } -ThrottleLimit 5

    return $results
}
'@
        } else {
            return @(
                'function Test-Function {',
                '    param (',
                '        [Parameter(Mandatory = $true)]',
                '        [string]$InputData',
                '    )',
                '    ',
                '    # Utilisation de la parallÃ©lisation',
                '    $results = $InputData | ForEach-Object -Parallel {',
                '        # Traitement parallÃ¨le',
                '        Start-Sleep -Milliseconds 100',
                '        return "Processed: $_"',
                '    } -ThrottleLimit 5',
                '    ',
                '    return $results',
                '}'
            )
        }
    } elseif ($Path -like "*Test2.ps1") {
        if ($Raw) {
            return @'
function Process-Data {
    param (
        [string]$InputFile,
        [string]$OutputFile
    )

    $data = Get-Content -Path $InputFile
    $processedData = $data | ForEach-Object { $_.ToUpper() }
    $processedData | Out-File -FilePath $OutputFile

    return $processedData
}
'@
        } else {
            return @(
                'function Process-Data {',
                '    param (',
                '        [string]$InputFile,',
                '        [string]$OutputFile',
                '    )',
                '    ',
                '    $data = Get-Content -Path $InputFile',
                '    $processedData = $data | ForEach-Object { $_.ToUpper() }',
                '    $processedData | Out-File -FilePath $OutputFile',
                '    ',
                '    return $processedData',
                '}'
            )
        }
    } elseif ($Path -like "*Test3.ps1") {
        if ($Raw) {
            return @'
function Process-DataInParallel {
    param (
        [string[]]$InputFiles,
        [string]$OutputFolder
    )

    $pool = [RunspaceFactory]::CreateRunspacePool(1, 10)
    $pool.Open()

    $jobs = @()
    foreach ($file in $InputFiles) {
        $job = [PowerShell]::Create().AddScript({
            param($file, $outputFolder)
            $data = Get-Content -Path $file
            $processedData = $data | ForEach-Object { $_.ToUpper() }
            $outputFile = Join-Path -Path $outputFolder -ChildPath (Split-Path -Path $file -Leaf)
            $processedData | Out-File -FilePath $outputFile
            return $outputFile
        }).AddParameter("file", $file).AddParameter("outputFolder", $OutputFolder)

        $job.RunspacePool = $pool
        $jobs += [PSCustomObject]@{
            Job = $job
            Result = $job.BeginInvoke()
        }
    }

    $results = @()
    foreach ($job in $jobs) {
        $results += $job.Job.EndInvoke($job.Result)
    }

    $pool.Close()
    $pool.Dispose()

    return $results
}
'@
        } else {
            return @(
                'function Process-DataInParallel {',
                '    param (',
                '        [string[]]$InputFiles,',
                '        [string]$OutputFolder',
                '    )',
                '    ',
                '    $pool = [RunspaceFactory]::CreateRunspacePool(1, 10)',
                '    $pool.Open()',
                '    ',
                '    $jobs = @()',
                '    foreach ($file in $InputFiles) {',
                '        $job = [PowerShell]::Create().AddScript({',
                '            param($file, $outputFolder)',
                '            $data = Get-Content -Path $file',
                '            $processedData = $data | ForEach-Object { $_.ToUpper() }',
                '            $outputFile = Join-Path -Path $outputFolder -ChildPath (Split-Path -Path $file -Leaf)',
                '            $processedData | Out-File -FilePath $outputFile',
                '            return $outputFile',
                '        }).AddParameter("file", $file).AddParameter("outputFolder", $OutputFolder)',
                '        ',
                '        $job.RunspacePool = $pool',
                '        $jobs += [PSCustomObject]@{',
                '            Job = $job',
                '            Result = $job.BeginInvoke()',
                '        }',
                '    }',
                '    ',
                '    $results = @()',
                '    foreach ($job in $jobs) {',
                '        $results += $job.Job.EndInvoke($job.Result)',
                '    }',
                '    ',
                '    $pool.Close()',
                '    $pool.Dispose()',
                '    ',
                '    return $results',
                '}'
            )
        }
    } else {
        if ($Raw) {
            return ""
        } else {
            return @()
        }
    }
}

# Mock pour Out-File
function Out-MockFile {
    param (
        [string]$FilePath,
        [object]$InputObject,
        [string]$Encoding = "UTF8"
    )

    # Simuler l'Ã©criture dans un fichier
    return $true
}

# Mock pour New-Item
function New-MockItem {
    param (
        [string]$Path,
        [string]$ItemType,
        [switch]$Force
    )

    # Simuler la crÃ©ation d'un Ã©lÃ©ment
    return [PSCustomObject]@{
        Path     = $Path
        ItemType = $ItemType
        Exists   = $true
    }
}

# Pas besoin d'exporter les fonctions dans un script .ps1
# Les fonctions sont automatiquement disponibles dans le scope du script qui l'appelle
