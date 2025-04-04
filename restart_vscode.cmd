@echo off
echo Fermeture de VS Code...
taskkill /f /im code.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo Recherche du chemin de VS Code...
for %%p in (
  "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"
  "%ProgramFiles%\Microsoft VS Code\Code.exe"
  "%ProgramFiles(x86)%\Microsoft VS Code\Code.exe"
  "%APPDATA%\Local\Programs\Microsoft VS Code\Code.exe"
) do (
  if exist %%p (
    echo VS Code trouvé: %%p
    echo Redémarrage de VS Code...
    start "" %%p "%CD%"
    goto :found
  )
)

echo VS Code non trouvé dans les emplacements standards.
echo Tentative de lancement via la commande 'code'...
where code >nul 2>&1
if %ERRORLEVEL% equ 0 (
  start "" code "%CD%"
  goto :found
) else (
  echo La commande 'code' n'est pas disponible dans le PATH.
  echo Veuillez redémarrer VS Code manuellement.
  pause
  exit /b 1
)

:found
echo VS Code a été redémarré avec les nouveaux paramètres.
echo Veuillez tester l'intégration d'Augment avec le terminal.
