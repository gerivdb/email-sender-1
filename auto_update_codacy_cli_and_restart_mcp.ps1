# Détecte codacy-cli.exe, met à jour la config MCP et redémarre le service MCP automatiquement
$codacyPath = Get-ChildItem -Path C:\, D:\, E:\ -Filter codacy-cli.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

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
   Write-Host "codacy-cli.exe introuvable sur les partitions C:, D:, E:."
}
