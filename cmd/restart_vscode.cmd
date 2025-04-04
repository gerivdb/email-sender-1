@echo off
echo Fermeture de VS Code...
taskkill /f /im code.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo Redémarrage de VS Code...
start "" "code" "%CD%"
echo VS Code a été redémarré avec les nouveaux paramètres.
echo Veuillez tester l'intégration d'Augment avec le terminal.
