# Exemples d'utilisation du système RAG
# Guide pratique pour utiliser les scripts RAG

Write-Host "=== EXEMPLES SYSTÈME RAG ===" -ForegroundColor Green

Write-Host "`n1. TESTER LE SYSTÈME" -ForegroundColor Yellow
Write-Host "   .\Test-RAG.ps1" -ForegroundColor Cyan

Write-Host "`n2. INDEXER DES DOCUMENTS" -ForegroundColor Yellow  
Write-Host "   .\RAG-Manager.ps1 -Action index -DocumentPath 'C:\docs\'" -ForegroundColor Cyan

Write-Host "`n3. RECHERCHER" -ForegroundColor Yellow
Write-Host "   .\RAG-Manager.ps1 -Action search -Query 'Comment utiliser QDrant?'" -ForegroundColor Cyan

Write-Host "`n4. VÉRIFIER LE STATUT" -ForegroundColor Yellow
Write-Host "   .\RAG-Manager.ps1 -Action status" -ForegroundColor Cyan

Write-Host "`n5. RECHERCHE DIRECTE" -ForegroundColor Yellow
Write-Host "   .\RAG-Search.ps1 -Query 'bases de données vectorielles'" -ForegroundColor Cyan

Write-Host "`n6. VECTORISER UN FICHIER" -ForegroundColor Yellow
Write-Host "   .\Vectoriser-Documents-QDrant.ps1 -DocumentPath 'document.txt'" -ForegroundColor Cyan

Write-Host "`n=== FLUX TYPIQUE ===" -ForegroundColor Green
Write-Host "1. Tester la connexion: .\Test-RAG.ps1" -ForegroundColor White
Write-Host "2. Indexer vos documents: .\RAG-Manager.ps1 -Action index -DocumentPath 'vos_docs/'" -ForegroundColor White  
Write-Host "3. Rechercher: .\RAG-Manager.ps1 -Action search -Query 'votre question'" -ForegroundColor White

Write-Host "`n✓ Système RAG prêt!" -ForegroundColor Green