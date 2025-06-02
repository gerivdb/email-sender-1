# Script to refresh VS Code Go language server
Write-Host "Cleaning Go workspace..."

# Clean all Go caches (ignore file locking errors on Windows)
Write-Host "Cleaning Go build cache..."
try { go clean -cache } catch { Write-Host "Cache cleanup partially completed (some files may be locked)" }

Write-Host "Cleaning Go module cache..."
try { go clean -modcache } catch { Write-Host "Module cache cleanup partially completed (some files may be locked)" }

# Re-download dependencies
Write-Host "Re-downloading dependencies..."
go mod tidy
go mod download

# Force rebuild of the panels package
$originalLocation = Get-Location
try {
   Set-Location "cmd\roadmap-cli\tui\panels"
   go build .
   Write-Host "Panels package built successfully"
}
catch {
   Write-Host "Error building panels package: $_"
}
finally {
   Set-Location $originalLocation
}

Write-Host "Done! Please restart VS Code Go language server:"
Write-Host "1. Press Ctrl+Shift+P"
Write-Host "2. Type Go: Restart Language Server"
Write-Host "3. Press Enter"