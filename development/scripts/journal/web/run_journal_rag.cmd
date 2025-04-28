@echo off
setlocal

echo ===== Journal RAG - Système de journal de bord avec RAG =====

REM Vérifier si Python est installé
where python >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Python n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer Python 3.8+ et réessayer.
    exit /b 1
)

REM Vérifier si Node.js est installé
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Node.js n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer Node.js 14+ et réessayer.
    exit /b 1
)

REM Vérifier si npm est installé
where npm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo npm n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer npm et réessayer.
    exit /b 1
)

echo Vérification des dépendances Python...
pip install -r requirements.txt

echo Vérification des dépendances Node.js...
cd frontend
call npm install
cd ..

echo.
echo Démarrage du backend...
start cmd /k "cd scripts\python\journal && python run_app.py"

echo Démarrage du frontend...
start cmd /k "cd frontend && npm run serve"

echo.
echo Journal RAG démarré !
echo.
echo Backend : http://localhost:8000
echo Frontend : http://localhost:8080
echo API Documentation : http://localhost:8000/docs
echo.
echo Appuyez sur Ctrl+C pour arrêter les serveurs.

endlocal
