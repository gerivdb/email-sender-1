# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionWrapper.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script CollectionWrapper.ps1 n'existe pas à l'emplacement spécifié: $scriptPath"
}

# Afficher le chemin pour le débogage
Write-Host "Importation du script: $scriptPath"

# Importer le script
. $scriptPath

Describe "CollectionWrapper Tests" {
    It "Should create a new wrapper for a List" {
        $wrapper = New-CollectionWrapper -CollectionType List
        $wrapper | Should -Not -BeNullOrEmpty
    }
}
