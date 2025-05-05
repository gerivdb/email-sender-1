# Test d'importation de modules
using module PSScriptAnalyzer

# Import-Module simple
Import-Module Pester

# Import-Module avec chemin relatif
Import-Module .\ModuleDependencyDetector.psm1
