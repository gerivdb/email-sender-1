# Script pour creer de nouveaux fichiers dans les bons dossiers
# Usage: .\scripts\maintenance\new-file.ps1 -Type workflow -Name mon-workflow

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("workflow", "script", "doc", "config", "mcp", "test")]
    [string]$Type,
    
    [Parameter(Mandatory=$true)]
    [string]$Name
)

function Create-File {
    param (
        [string]$Path,
        [string]$Content
    )
    
    if (Test-Path $Path) {
        Write-Host "[ATTENTION] Le fichier $Path existe deja" -ForegroundColor Yellow
        Write-Host "Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
        $confirmation = Read-Host
        
        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            Set-Content -Path $Path -Value $Content
            Write-Host "[OK] Fichier $Path cree (remplace)" -ForegroundColor Green
        } else {
            Write-Host "[NON] Operation annulee" -ForegroundColor Red
        }
    } else {
        # Creer le dossier parent s'il n'existe pas
        $folder = Split-Path $Path -Parent
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder | Out-Null
            Write-Host "[OK] Dossier $folder cree" -ForegroundColor Green
        }
        
        Set-Content -Path $Path -Value $Content
        Write-Host "[OK] Fichier $Path cree" -ForegroundColor Green
    }
}

switch ($Type) {
    "workflow" {
        $path = ".\src\workflows\$Name.json"
        $content = @"
{
  "name": "$Name",
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [
        240,
        300
      ]
    }
  ],
  "connections": {}
}
"@
        Create-File -Path $path -Content $content
    }
    "script" {
        $path = ".\scripts\$Name.ps1"
        $content = @"
# Script $Name
# Description: [Ajoutez une description ici]

Write-Host "=== $Name ===" -ForegroundColor Cyan

# Votre code ici

Write-Host "`n=== Termine ===" -ForegroundColor Cyan
"@
        Create-File -Path $path -Content $content
    }
    "doc" {
        $path = ".\docs\$Name.md"
        $content = @"
# $Name

## Introduction

[Ajoutez une introduction ici]

## Contenu

[Ajoutez le contenu ici]

## Utilisation

[Ajoutez des instructions d'utilisation ici]
"@
        Create-File -Path $path -Content $content
    }
    "config" {
        $path = ".\config\$Name.json"
        $content = @"
{
  "name": "$Name",
  "version": "1.0.0",
  "description": "[Ajoutez une description ici]",
  "config": {
    
  }
}
"@
        Create-File -Path $path -Content $content
    }
    "mcp" {
        $path = ".\src\mcp\batch\mcp-$Name.cmd"
        $content = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
REM Ajoutez vos commandes ici
"@
        Create-File -Path $path -Content $content
    }
    "test" {
        $path = ".\tests\$Name.ps1"
        $content = @"
# Test $Name
# Description: [Ajoutez une description ici]

Write-Host "=== Test $Name ===" -ForegroundColor Cyan

# Votre code de test ici

Write-Host "`n=== Test termine ===" -ForegroundColor Cyan
"@
        Create-File -Path $path -Content $content
    }
}
