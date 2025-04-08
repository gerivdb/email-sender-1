@echo off
setlocal

echo ===== Initialisation du système Journal RAG =====

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

echo.
echo Création des répertoires...

REM Créer les répertoires nécessaires
mkdir docs\journal_de_bord\entries 2>nul
mkdir docs\journal_de_bord\analysis 2>nul
mkdir docs\journal_de_bord\embeddings 2>nul
mkdir docs\journal_de_bord\rag 2>nul
mkdir docs\journal_de_bord\notifications 2>nul
mkdir docs\journal_de_bord\github 2>nul
mkdir docs\journal_de_bord\jira 2>nul
mkdir docs\journal_de_bord\notion 2>nul

echo.
echo Installation des dépendances Python...
pip install -r requirements.txt

echo.
echo Installation des dépendances Node.js...
cd frontend
call npm install
cd ..

echo.
echo Construction de l'index RAG...
cd scripts\python\journal
python journal_rag_simple.py --build-index
cd ..\..\..

echo.
echo Initialisation terminée !
echo.
echo Pour démarrer le système, exécutez :
echo run_journal_rag.cmd
echo.
echo Pour plus d'informations, consultez :
echo docs\journal_de_bord\README.md
echo docs\journal_de_bord\QUICKSTART.md
echo.

endlocal
