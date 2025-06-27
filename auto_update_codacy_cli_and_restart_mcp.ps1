# Détecte codacy-cli.exe, met à jour la config MCP et redémarre le service MCP automatiquement
$codacyExe = "codacy-cli.exe"
$installDir = "$env:ProgramFiles\CodacyCLI"
$codacyPath = Get-ChildItem -Path C:\, D:\, E:\ -Filter $codacyExe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if (-not $codacyPath) {
   Write-Host "Codacy CLI introuvable, téléchargement de la dernière version..."
   $latestUrl = "https://api.github.com/repos/codacy/codacy-cli/releases/latest"
   $release = Invoke-RestMethod -Uri $latestUrl -UseBasicParsing
   $asset = $release.assets | Where-Object { $_.name -like "*windows*amd64*.exe" } | Select-Object -First 1
   if (-not $asset) { throw "Aucun binaire Windows trouvé dans la release Codacy CLI." }
   if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }
   $downloadPath = Join-Path $installDir $codacyExe
   Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath
   $codacyPath = $downloadPath
   Write-Host "Codacy CLI téléchargé dans $codacyPath"
   # Ajouter au PATH utilisateur si non présent
   $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
   if ($userPath -notlike "*$installDir*") {
      [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
      Write-Host "Répertoire $installDir ajouté au PATH utilisateur. Redémarrez votre terminal si besoin."
   }
}

if ($codacyPath) {
   Write-Host "Codacy CLI trouvé : $codacyPath"
   $configPath = "src/mcp/servers/unified_proxy/config.json"
   $config = Get-Content $configPath | Out-String | ConvertFrom-Json
   $config.tools[0].command = $codacyPath -replace '\\', '/'
   $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
   Write-Host "Configuration MCP mise à jour avec le chemin : $codacyPath"
   # Redémarrage du service MCP (adapter la commande si besoin)
   Stop-Process -Name "unified_proxy" -Force -ErrorAction SilentlyContinue
   Start-Process -FilePath "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList "-NoExit", "-Command", "cd 'src/mcp/servers/unified_proxy'; ./start.ps1"
   Write-Host "Service MCP redémarré."
}
else {
   Write-Host "codacy-cli.exe introuvable ou installation échouée."
}
