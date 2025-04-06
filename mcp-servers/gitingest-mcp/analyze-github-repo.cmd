@echo off
echo Analyse d'un depot GitHub...
echo.
echo Ce script va analyser un depot GitHub et generer un resume de son contenu.
echo.
echo Usage: analyze-github-repo.cmd <repo-url>
echo Exemple: analyze-github-repo.cmd https://github.com/username/repo
echo.

:: Verifier si l'URL du depot est fournie
if "%~1"=="" (
  echo Erreur: URL du depot GitHub manquante.
  echo Usage: analyze-github-repo.cmd ^<repo-url^>
  echo Exemple: analyze-github-repo.cmd https://github.com/username/repo
  exit /b 1
)

:: Executer le script
node "%~dp0analyze-github-repo.js" %1

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
