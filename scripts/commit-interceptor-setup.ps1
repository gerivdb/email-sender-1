<#
.SYNOPSIS
    Sets up a Git commit interceptor (hook) to automate documentation updates.

.DESCRIPTION
    This script is a placeholder for setting up a Git pre-commit or post-commit hook.
    In a real scenario, this hook would trigger the documentation generation process
    (e.g., by calling docgen.py) to ensure documentation is always up-to-date with code changes.

.NOTES
    Version: 1.0
    Date: 2025-07-03
    Author: Cline (AI Assistant)
    License: MIT

.EXAMPLE
    .\commit-interceptor-setup.ps1
    This will simulate setting up the hook.
#>

function Set-CommitInterceptor {
    [CmdletBinding()]
    param()

    Write-Host "Configuration du hook Git post-commit pour la mise à jour de la documentation..." -ForegroundColor Yellow

    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) {
        Write-Error "Ce n'est pas un dépôt Git. Impossible de configurer le hook."
        return
    }

    $hooksDir = Join-Path $gitDir "hooks"
    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir | Out-Null
    }

    $hookFilePath = Join-Path $hooksDir "post-commit"
    $hookContent = @"
#!/usr/bin/env pwsh
#
# Ce hook est déclenché après un commit.
# Il appelle le script PowerShell pour déclencher la mise à jour de la documentation.

\$currentDir = Split-Path -Parent \$MyInvocation.MyCommand.Definition
\$scriptPath = Join-Path \$currentDir "trigger-doc-update.ps1"

if (Test-Path \$scriptPath) {
    Write-Host "Exécution du hook post-commit: Déclenchement de la mise à jour de la documentation..."
    & \$scriptPath
} else {
    Write-Warning "Le script trigger-doc-update.ps1 n'a pas été trouvé à \$scriptPath. La mise à jour automatique de la documentation ne sera pas déclenchée."
}
"@

    try {
        Set-Content -Path $hookFilePath -Value $hookContent -Encoding UTF8
        # Rendre le script exécutable sur les systèmes Unix-like (important pour WSL/Git Bash)
        if ($IsWindows) {
            # Pour Windows, s'assurer que Git Bash/WSL peut l'exécuter
            # Le mode +x n'est pas directement applicable sur NTFS, mais peut aider Git à le reconnaître comme exécutable
            # Si vous utilisez Git Bash, vous pourriez avoir besoin de 'chmod +x .git/hooks/post-commit' manuellement
            Write-Host "Sur Windows, assurez-vous que le hook est exécutable si vous utilisez Git Bash ou WSL." -ForegroundColor Yellow
        }
        else {
            # Pour les systèmes non-Windows (Linux/macOS via WSL/Git Bash)
            $chmodCmd = "chmod +x `"$hookFilePath`""
            Invoke-Expression $chmodCmd
        }
        Write-Host "Hook Git 'post-commit' configuré avec succès à: $hookFilePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Erreur lors de la configuration du hook Git: $($_.Exception.Message)"
    }
}

# Execute the function when the script is run
Set-CommitInterceptor
