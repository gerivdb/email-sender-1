# Test-TerminalCompatibility.ps1
# Script pour tester la compatibilite multi-terminaux

param (
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput
)

# Fonction pour dÃ©tecter le type de terminal
function Get-TerminalType {
    # VÃ©rifier si nous sommes dans PowerShell Core (qui fonctionne sur diffÃ©rentes plateformes)
    if ($PSVersionTable.PSEdition -eq "Core") {
        if ($IsWindows) {
            return "PowerShell Core (Windows)"
        }
        elseif ($IsLinux) {
            return "PowerShell Core (Linux)"
        }
        elseif ($IsMacOS) {
            return "PowerShell Core (macOS)"
        }
        else {
            return "PowerShell Core (Autre)"
        }
    }
    else {
        # PowerShell Windows classique
        return "Windows PowerShell"
    }
}

# Fonction pour tester la compatibilitÃ© des chemins
function Test-PathCompatibility {
    param (
        [switch]$Verbose
    )

    $tests = @(
        @{
            Name = "Chemin absolu Windows"
            Path = "C:\Users\test\Documents\file.txt"
            ExpectedWindows = "C:\Users\test\Documents\file.txt"
            ExpectedLinux = "C:/Users/test/Documents/file.txt"
            ExpectedMacOS = "C:/Users/test/Documents/file.txt"
        },
        @{
            Name = "Chemin relatif Windows"
            Path = ".\folder\file.txt"
            ExpectedWindows = ".\folder\file.txt"
            ExpectedLinux = "./folder/file.txt"
            ExpectedMacOS = "./folder/file.txt"
        },
        @{
            Name = "Chemin parent Windows"
            Path = "..\folder\file.txt"
            ExpectedWindows = "..\folder\file.txt"
            ExpectedLinux = "../folder/file.txt"
            ExpectedMacOS = "../folder/file.txt"
        },
        @{
            Name = "Chemin absolu Linux"
            Path = "/home/user/documents/file.txt"
            ExpectedWindows = "\home\user\documents\file.txt"
            ExpectedLinux = "/home/user/documents/file.txt"
            ExpectedMacOS = "/home/user/documents/file.txt"
        },
        @{
            Name = "Chemin relatif Linux"
            Path = "./folder/file.txt"
            ExpectedWindows = ".\folder\file.txt"
            ExpectedLinux = "./folder/file.txt"
            ExpectedMacOS = "./folder/file.txt"
        },
        @{
            Name = "Chemin parent Linux"
            Path = "../folder/file.txt"
            ExpectedWindows = "..\folder\file.txt"
            ExpectedLinux = "../folder/file.txt"
            ExpectedMacOS = "../folder/file.txt"
        }
    )

    $terminalType = Get-TerminalType
    Write-Output "Type de terminal dÃ©tectÃ© : $terminalType"
    Write-Output ""

    $passedCount = 0
    $failedCount = 0

    foreach ($test in $tests) {
        Write-Output "Test : $($test.Name)"

        # DÃ©terminer le rÃ©sultat attendu selon le terminal
        $expected = switch -Regex ($terminalType) {
            "Windows" { $test.ExpectedWindows }
            "Linux" { $test.ExpectedLinux }
            "macOS" { $test.ExpectedMacOS }
            default { $test.Path }
        }

        # Normaliser le chemin selon le terminal
        $normalized = switch -Regex ($terminalType) {
            "Windows" { $test.Path -replace "/", "\" }
            "Linux|macOS" { $test.Path -replace "\\", "/" }
            default { $test.Path }
        }

        # VÃ©rifier si le rÃ©sultat est correct
        $result = if ($normalized -eq $expected) { "Reussi" } else { "Echoue" }
        $color = if ($result -eq "Reussi") { "Green" } else { "Red" }

        Write-Output "  Chemin original : $($test.Path)"
        Write-Output "  Chemin normalise : $normalized"
        Write-Output "  Resultat attendu : $expected"
        Write-Output "  Resultat : $result" -ForegroundColor $color

        if ($result -eq "Reussi") {
            $passedCount++
        }
        else {
            $failedCount++
        }

        if ($Verbose) {
            Write-Output "  Details :"
            Write-Output "    Terminal : $terminalType"
            Write-Output "    Separateur de chemin : $([System.IO.Path]::DirectorySeparatorChar)"
            Write-Output "    Separateur de chemin alternatif : $([System.IO.Path]::AltDirectorySeparatorChar)"
        }

        Write-Output ""
    }

    # Afficher le resume
    Write-Output "Resume des tests :"
    Write-Output "  Tests reussis : $passedCount"
    Write-Output "  Tests echoues : $failedCount"
    Write-Output "  Total : $($tests.Count)"

    return $passedCount -eq $tests.Count
}

# Fonction pour tester la compatibilitÃ© des commandes
function Test-CommandCompatibility {
    param (
        [switch]$Verbose
    )

    $tests = @(
        @{
            Name = "Commande PowerShell"
            Command = "Get-ChildItem"
            ExpectedWindows = $true
            ExpectedLinux = $true
            ExpectedMacOS = $true
        },
        @{
            Name = "Commande Windows"
            Command = "cmd.exe"
            ExpectedWindows = $true
            ExpectedLinux = $false
            ExpectedMacOS = $false
        },
        @{
            Name = "Commande Linux"
            Command = "bash"
            ExpectedWindows = $false
            ExpectedLinux = $true
            ExpectedMacOS = $true
        }
    )

    $terminalType = Get-TerminalType
    Write-Output "Type de terminal dÃ©tectÃ© : $terminalType"
    Write-Output ""

    $passedCount = 0
    $failedCount = 0

    foreach ($test in $tests) {
        Write-Output "Test : $($test.Name)"

        # DÃ©terminer le rÃ©sultat attendu selon le terminal
        $expected = switch -Regex ($terminalType) {
            "Windows" { $test.ExpectedWindows }
            "Linux" { $test.ExpectedLinux }
            "macOS" { $test.ExpectedMacOS }
            default { $false }
        }

        # VÃ©rifier si la commande existe
        $exists = $null -ne (Get-Command -Name $test.Command -ErrorAction SilentlyContinue)

        # VÃ©rifier si le rÃ©sultat est correct
        $result = if ($exists -eq $expected) { "Reussi" } else { "Echoue" }
        $color = if ($result -eq "Reussi") { "Green" } else { "Red" }

        Write-Output "  Commande : $($test.Command)"
        Write-Output "  Existe : $exists"
        Write-Output "  Resultat attendu : $expected"
        Write-Output "  Resultat : $result" -ForegroundColor $color

        if ($result -eq "Reussi") {
            $passedCount++
        }
        else {
            $failedCount++
        }

        if ($Verbose) {
            Write-Output "  Details :"
            Write-Output "    Terminal : $terminalType"
            Write-Output "    OS : $([System.Environment]::OSVersion.Platform)"
        }

        Write-Output ""
    }

    # Afficher le rÃ©sumÃ©
    Write-Output "RÃ©sumÃ© des tests :"
    Write-Output "  Tests rÃ©ussis : $passedCount"
    Write-Output "  Tests Ã©chouÃ©s : $failedCount"
    Write-Output "  Total : $($tests.Count)"

    return $passedCount -eq $tests.Count
}

# Fonction principale
function Main {
    Write-Output "Test de compatibilite multi-terminaux"
    Write-Output "==================================="
    Write-Output ""

    # Tester la compatibilite des chemins
    Write-Output "Test de compatibilite des chemins"
    Write-Output "---------------------------"
    $pathCompatibility = Test-PathCompatibility -Verbose:$DetailedOutput

    Write-Output ""

    # Tester la compatibilite des commandes
    Write-Output "Test de compatibilite des commandes"
    Write-Output "-------------------------------"
    $commandCompatibility = Test-CommandCompatibility -Verbose:$DetailedOutput

    Write-Output ""

    # Afficher le resultat global
    Write-Output "Resultat global"
    Write-Output "=============="

    if ($pathCompatibility -and $commandCompatibility) {
        Write-Output "Tous les tests ont reussi." -ForegroundColor Green
    }
    else {
        Write-Output "Certains tests ont echoue." -ForegroundColor Red
    }
}

# ExÃ©cuter la fonction principale
Main
