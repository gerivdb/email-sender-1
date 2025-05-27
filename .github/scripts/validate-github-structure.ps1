# Validate .github structure
$requiredDirs = @(
    "docs",
    "hooks",
    "ISSUE_TEMPLATE",
    "PULL_REQUEST_TEMPLATE",
    "prompts",
    "workflows"
)

$requiredFiles = @(
    "README.md",
    "docs/copilot-instructions.md",
    "docs/personnaliser-copilot.md",
    "PULL_REQUEST_TEMPLATE/pull_request_template.md"
)

# Check directories
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path ".github/$dir")) {
        Write-Error "Missing required directory: $dir"
    }
}

# Check files
foreach ($file in $requiredFiles) {
    if (-not (Test-Path ".github/$file")) {
        Write-Error "Missing required file: $file"
    }
}

# Validate prompts structure
$promptDirs = @("modes", "analysis", "planning")
foreach ($dir in $promptDirs) {
    if (-not (Test-Path ".github/prompts/$dir")) {
        Write-Error "Missing prompts directory: $dir"
    }
}

Write-Host "Structure validation complete!"