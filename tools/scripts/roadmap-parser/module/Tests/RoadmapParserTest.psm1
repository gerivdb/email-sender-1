# Module temporaire pour les tests
$modulePath = (Split-Path -Parent $PSScriptRoot)
$functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"

# Charger le contenu du fichier
$content = Get-Content -Path $functionsPath -Raw

# Exécuter le contenu
$scriptBlock = [ScriptBlock]::Create($content)
. $scriptBlock

# Exporter les fonctions
Export-ModuleMember -Function Get-DefaultConfiguration, Get-Configuration, Merge-Configuration, Test-Configuration, Save-Configuration, Set-DefaultConfiguration, Convert-ConfigurationToString
