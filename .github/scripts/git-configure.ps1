# Git Configuration Script for EMAIL_SENDER_1 Project
# This script applies recommended Git configurations for consistent development experience
# Usage: Run this script to automatically configure Git according to project recommendations

# Check if Git is installed
$gitVersion = git --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Git is not installed or not in PATH. Please install Git first." -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Git detected: $gitVersion" -ForegroundColor Cyan
Write-Host "⚙️ Applying recommended Git configurations..." -ForegroundColor Cyan

# Essential configurations
Write-Host "  • Disabling pagination for better terminal compatibility..." -ForegroundColor Yellow
git config --global core.pager ''

Write-Host "  • Setting VS Code as default editor..." -ForegroundColor Yellow
git config --global core.editor "code --wait"

# Configure line endings based on OS
if ($IsWindows -or $env:OS -match "Windows") {
    Write-Host "  • Configuring line endings for Windows..." -ForegroundColor Yellow
    git config --global core.autocrlf true
} else {
    Write-Host "  • Configuring line endings for Unix/macOS..." -ForegroundColor Yellow
    git config --global core.autocrlf input
}

# Configure useful aliases
Write-Host "  • Setting up useful Git aliases..." -ForegroundColor Yellow
git config --global alias.co checkout
git config --global alias.br "for-each-ref --format='%(refname:short)' refs/heads/"
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Configure push behavior
Write-Host "  • Configuring push behavior..." -ForegroundColor Yellow
git config --global push.default current

# Configure pull behavior
Write-Host "  • Configuring pull behavior to use rebase..." -ForegroundColor Yellow
git config --global pull.rebase true

# Project-specific configurations (without --global)
Write-Host "  • Applying project-specific configurations..." -ForegroundColor Yellow

# Check if we're in the project repository
$projectRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -eq 0) {
    $expectedPath = "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1"
    if ($projectRoot -eq $expectedPath) {
        Write-Host "    ✓ Project repository detected at: $projectRoot" -ForegroundColor Green
        
        # Apply project-specific configurations
        if (Test-Path ".github/.gitmessage.txt") {
            git config commit.template .github/.gitmessage.txt
            Write-Host "    ✓ Configured commit template" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️ Commit template not found at .github/.gitmessage.txt" -ForegroundColor Yellow
        }
        
        if (Test-Path ".github/hooks") {
            git config core.hooksPath .github/hooks
            Write-Host "    ✓ Configured Git hooks path" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️ Hooks directory not found at .github/hooks" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    ⚠️ Not in EMAIL_SENDER_1 project repository" -ForegroundColor Yellow
        Write-Host "    ⚠️ Project-specific configurations skipped" -ForegroundColor Yellow
    }
} else {
    Write-Host "    ⚠️ Not in a Git repository" -ForegroundColor Yellow
    Write-Host "    ⚠️ Project-specific configurations skipped" -ForegroundColor Yellow
}

# Verify configurations
Write-Host "`n🔍 Verifying applied Git configurations:" -ForegroundColor Cyan
Write-Host "  • Core pager: $(git config --get core.pager)" -ForegroundColor White
Write-Host "  • Core editor: $(git config --get core.editor)" -ForegroundColor White
Write-Host "  • Core autocrlf: $(git config --get core.autocrlf)" -ForegroundColor White
Write-Host "  • Push default: $(git config --get push.default)" -ForegroundColor White
Write-Host "  • Pull rebase: $(git config --get pull.rebase)" -ForegroundColor White

Write-Host "`n🎉 Git configuration applied successfully!" -ForegroundColor Green
Write-Host "📚 For more information, see documentation at .github/docs/guides/git/" -ForegroundColor Cyan