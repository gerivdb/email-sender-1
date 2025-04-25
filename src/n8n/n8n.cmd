@echo off
echo n8n - Interface principale
echo.
echo Options disponibles:
echo 1. Demarrer n8n
echo 2. Arreter n8n
echo 3. Redemarrer n8n
echo 4. Verifier le statut
echo 5. Tableau de bord
echo 6. Maintenance
echo 7. Tests
echo 8. Gestion des workflows
echo 9. Reinitialiser n8n
echo 0. Quitter
echo.

set /p choix=Votre choix: 

if "%choix%"=="1" goto start
if "%choix%"=="2" goto stop
if "%choix%"=="3" goto restart
if "%choix%"=="4" goto status
if "%choix%"=="5" goto dashboard
if "%choix%"=="6" goto maintenance
if "%choix%"=="7" goto tests
if "%choix%"=="8" goto workflows
if "%choix%"=="9" goto reset
if "%choix%"=="0" goto end

echo Choix invalide
goto end

:start
call %~dp0scripts\deployment\n8n-start.cmd
goto end

:stop
call %~dp0scripts\deployment\n8n-stop.cmd
goto end

:restart
call %~dp0scripts\deployment\n8n-restart.cmd
goto end

:status
call %~dp0scripts\monitoring\n8n-status.cmd
goto end

:dashboard
call %~dp0scripts\dashboard\n8n-dashboard.cmd
goto end

:maintenance
call %~dp0scripts\maintenance\n8n-maintenance.cmd
goto end

:tests
call %~dp0scripts\tests\n8n-test.cmd
goto end

:workflows
call %~dp0scripts\workflows\n8n-import.cmd
goto end

:reset
call %~dp0scripts\deployment\reset-n8n.cmd
goto end

:end
