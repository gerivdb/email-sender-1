# Détecte codacy-cli.exe sur toutes les partitions et met à jour la config MCP automatiquement
$codacyPath = Get-ChildItem -Path C:\, D:\, E:\ -Filter codacy-cli.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if ($codacyPath) {
   Write-Host "Codacy CLI trouvé : $codacyPath"
   $configPath = "src/mcp/servers/unified_proxy/config.json"
   $config = Get-Content $configPath | Out-String | ConvertFrom-Json
   $config.tools[0].command = $codacyPath -replace '\\', '/'
   $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
   Write-Host "Configuration MCP mise à jour avec le chemin : $codacyPath"
}
else {
   Write-Host "codacy-cli.exe introuvable sur les partitions C:, D:, E:."
}
