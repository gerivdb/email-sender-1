@echo off
REM Commande ultra-minimale pour push vers GitHub
REM Modifiez USERNAME et TOKEN avant d'exécuter

cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

REM MODIFIEZ LES VALEURS CI-DESSOUS AVEC VOS INFORMATIONS GITHUB
set GH_USER=VOTRE_USERNAME
set GH_TOKEN=VOTRE_TOKEN

git push https://%GH_USER%:%GH_TOKEN%@github.com/gerivdb/email-sender-1.git manager/powershell-optimization

pause
