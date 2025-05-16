# Test d'encodage
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Afficher des caractères accentués
Write-Host "Caractères accentués : é è à ç ù"

# Afficher l'encodage actuel
Write-Host "Encodage de sortie : $($OutputEncoding.EncodingName)"
Write-Host "Encodage de la console : $([Console]::OutputEncoding.EncodingName)"
