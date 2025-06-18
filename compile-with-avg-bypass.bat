@echo off
echo Compilation Go avec protection AVG temporairement desactivee
echo.
echo ATTENTION: Ce script desactive temporairement AVG
echo Appuyez sur une touche pour continuer ou Ctrl+C pour annuler
pause

echo Arret temporaire de la protection AVG...
sc stop AVGSvc 2>nul
timeout /t 3 /nobreak

echo Compilation du projet...
cd /d "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
go build ./...

echo Redemarrage de la protection AVG...
sc start AVGSvc 2>nul

echo.
echo Compilation terminee. Protection AVG reactivee.
pause
