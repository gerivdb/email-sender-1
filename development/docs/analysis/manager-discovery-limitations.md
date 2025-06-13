# Limitations techniques du mécanisme de découverte des gestionnaires

## Introduction

Ce document identifie les limitations techniques du mécanisme de découverte automatique des gestionnaires dans le Process Manager. Ces limitations peuvent affecter la capacité du Process Manager à découvrir et à enregistrer correctement les gestionnaires disponibles dans le système.

## Rappel du mécanisme de découverte actuel

Le mécanisme de découverte automatique des gestionnaires est implémenté dans la fonction `Discover-Managers` du Process Manager. Cette fonction recherche les répertoires dont le nom correspond au modèle `*-manager`, puis recherche les scripts et les manifestes des gestionnaires dans ces répertoires.

```powershell
function Discover-Managers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipDependencyCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipValidation,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipSecurityCheck,
        
        [Parameter(Mandatory = $false)]
        [string[]]$SearchPaths = @("development\managers")
    )

    # Code de la fonction...

}
```plaintext
## Limitations techniques identifiées

### 1. Recherche non récursive

#### Description

Le mécanisme de découverte actuel ne recherche pas récursivement dans les sous-répertoires. Il recherche uniquement les répertoires de premier niveau dans les chemins de recherche spécifiés.

#### Impact

Cette limitation empêche la découverte de gestionnaires qui pourraient être organisés dans des sous-répertoires plus profonds. Par exemple, si un gestionnaire est organisé dans un répertoire `development\managers\custom\mode-manager`, il ne sera pas découvert par le mécanisme actuel.

#### Code concerné

```powershell
$managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
```plaintext
### 2. Recherche basée uniquement sur les répertoires

#### Description

Le mécanisme de découverte actuel recherche uniquement les répertoires dont le nom correspond au modèle `*-manager`. Il ne recherche pas les fichiers qui pourraient contenir des gestionnaires.

#### Impact

Cette limitation empêche la découverte de gestionnaires qui pourraient être implémentés dans des fichiers sans être organisés dans des répertoires spécifiques. Par exemple, si un gestionnaire est implémenté dans un fichier `development\managers\ModeManager.ps1`, il ne sera pas découvert par le mécanisme actuel.

#### Code concerné

```powershell
$managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
```plaintext
### 3. Convention de nommage rigide pour les répertoires

#### Description

Le mécanisme de découverte actuel recherche uniquement les répertoires dont le nom correspond au modèle `*-manager`. Il ne prend pas en compte d'autres conventions de nommage qui pourraient être utilisées pour les gestionnaires.

#### Impact

Cette limitation empêche la découverte de gestionnaires qui pourraient utiliser d'autres conventions de nommage. Par exemple, si un gestionnaire est organisé dans un répertoire `development\managers\ModeController`, il ne sera pas découvert par le mécanisme actuel.

#### Code concerné

```powershell
$managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
```plaintext
### 4. Structure de dossiers rigide

#### Description

Le mécanisme de découverte actuel suppose que le script principal du gestionnaire est situé dans un sous-répertoire `scripts` et a le même nom que le répertoire du gestionnaire. Il ne prend pas en compte d'autres structures de dossiers qui pourraient être utilisées.

#### Impact

Cette limitation empêche la découverte de gestionnaires qui pourraient utiliser d'autres structures de dossiers. Par exemple, si un gestionnaire a son script principal directement dans le répertoire racine du gestionnaire, ou dans un sous-répertoire différent de `scripts`, il ne sera pas découvert par le mécanisme actuel.

#### Code concerné

```powershell
$managerScriptPath = Join-Path -Path $managerDir.FullName -ChildPath "scripts\$($managerDir.Name).ps1"
```plaintext
### 5. Convention de nommage rigide pour les scripts

#### Description

Le mécanisme de découverte actuel suppose que le script principal du gestionnaire a le même nom que le répertoire du gestionnaire. Il ne prend pas en compte d'autres conventions de nommage qui pourraient être utilisées pour les scripts.

#### Impact

Cette limitation empêche la découverte de gestionnaires dont le script principal pourrait avoir un nom différent du répertoire. Par exemple, si un gestionnaire est organisé dans un répertoire `mode-manager` mais que son script principal est nommé `ModeController.ps1`, il ne sera pas découvert par le mécanisme actuel.

#### Code concerné

```powershell
$managerScriptPath = Join-Path -Path $managerDir.FullName -ChildPath "scripts\$($managerDir.Name).ps1"
```plaintext
### 6. Emplacement rigide pour les manifestes

#### Description

Le mécanisme de découverte actuel suppose que le manifeste du gestionnaire est situé dans le même répertoire que le script principal et a le même nom que le répertoire du gestionnaire avec l'extension `.manifest.json`. Il ne prend pas en compte d'autres emplacements ou conventions de nommage qui pourraient être utilisés pour les manifestes.

#### Impact

Cette limitation empêche la découverte des manifestes qui pourraient être situés dans d'autres emplacements ou qui pourraient utiliser d'autres conventions de nommage. Par exemple, si un gestionnaire a son manifeste directement dans le répertoire racine du gestionnaire, ou dans un sous-répertoire différent de `scripts`, ou si le manifeste a un nom différent, il ne sera pas découvert par le mécanisme actuel.

#### Code concerné

```powershell
$manifestPath = Join-Path -Path $managerDir.FullName -ChildPath "scripts\$($managerDir.Name).manifest.json"
```plaintext
### 7. Format rigide pour les manifestes

#### Description

Le mécanisme de découverte actuel suppose que le manifeste du gestionnaire est au format JSON. Il ne prend pas en compte d'autres formats qui pourraient être utilisés pour les manifestes, comme PSD1 (PowerShell Data File) ou XML.

#### Impact

Cette limitation empêche l'extraction des informations des manifestes qui pourraient être dans d'autres formats. Par exemple, si un gestionnaire a son manifeste au format PSD1, les informations du manifeste ne seront pas extraites par le mécanisme actuel.

#### Code concerné

```powershell
$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
```plaintext
### 8. Pas de gestion des dépendances circulaires

#### Description

Le mécanisme de découverte actuel ne gère pas correctement les dépendances circulaires entre les gestionnaires. Si un gestionnaire A dépend du gestionnaire B, qui dépend du gestionnaire C, qui dépend du gestionnaire A, le mécanisme actuel pourrait entrer dans une boucle infinie ou échouer à résoudre les dépendances.

#### Impact

Cette limitation peut empêcher l'enregistrement correct des gestionnaires qui ont des dépendances circulaires. Dans le pire des cas, aucun des gestionnaires impliqués dans la dépendance circulaire ne sera enregistré.

#### Code concerné

Le code de résolution des dépendances n'est pas directement visible dans la fonction `Discover-Managers`, mais il est probablement implémenté dans le module `DependencyResolver`.

### 9. Pas de filtrage des résultats

#### Description

Le mécanisme de découverte actuel ne filtre pas les résultats pour exclure les fichiers de sauvegarde, de test, temporaires, etc. Tous les répertoires dont le nom correspond au modèle `*-manager` sont considérés comme des gestionnaires potentiels.

#### Impact

Cette limitation peut entraîner la découverte et l'enregistrement de gestionnaires qui ne sont pas destinés à être utilisés, comme des sauvegardes ou des tests. Cela peut polluer la liste des gestionnaires enregistrés et potentiellement causer des conflits.

#### Code concerné

```powershell
$managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
```plaintext
### 10. Pas de gestion des conflits de noms

#### Description

Le mécanisme de découverte actuel ne gère pas explicitement les conflits de noms entre les gestionnaires découverts. Si deux gestionnaires ont le même nom (après transformation du nom du répertoire), le comportement n'est pas clairement défini.

#### Impact

Cette limitation peut entraîner des comportements imprévisibles si deux gestionnaires ont le même nom. Le dernier gestionnaire découvert pourrait écraser le premier, ou l'enregistrement pourrait échouer, selon l'implémentation de la fonction `Register-Manager`.

#### Code concerné

```powershell
$managerName = $managerDir.Name -replace "-manager", "Manager" -replace "^.", { $args[0].ToString().ToUpper() }
```plaintext
### 11. Calcul rigide du chemin complet

#### Description

Le mécanisme de découverte actuel calcule le chemin complet en remontant de trois niveaux à partir du répertoire du script `process-manager.ps1`, puis en ajoutant le chemin de recherche spécifié. Cette approche est rigide et peut ne pas fonctionner dans toutes les configurations.

#### Impact

Cette limitation peut empêcher la découverte de gestionnaires si le Process Manager est installé dans un emplacement différent de celui attendu, ou si les gestionnaires sont organisés différemment dans le système de fichiers.

#### Code concerné

```powershell
$fullSearchPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $searchPath
```plaintext
### 12. Pas de recherche de fichiers de configuration

#### Description

Le mécanisme de découverte actuel ne recherche pas les fichiers de configuration des gestionnaires. Il se concentre uniquement sur les scripts et les manifestes.

#### Impact

Cette limitation peut empêcher la découverte et l'enregistrement complets des gestionnaires qui pourraient avoir des configurations spécifiques. Les gestionnaires seront enregistrés sans leurs configurations, ce qui pourrait les empêcher de fonctionner correctement.

#### Code concerné

Le code de recherche des fichiers de configuration n'est pas présent dans la fonction `Discover-Managers`.

## Conclusion

Le mécanisme de découverte automatique des gestionnaires du Process Manager présente plusieurs limitations techniques qui peuvent affecter sa capacité à découvrir et à enregistrer correctement les gestionnaires disponibles dans le système. Ces limitations sont principalement liées à la rigidité du mécanisme, qui suppose une organisation et une convention de nommage spécifiques pour les gestionnaires.

Pour améliorer la robustesse et la flexibilité du mécanisme de découverte, il serait nécessaire d'adresser ces limitations en rendant le mécanisme plus adaptable aux différentes organisations et conventions de nommage qui pourraient être utilisées pour les gestionnaires.
