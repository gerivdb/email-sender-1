@echo on
cd "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo === PUSH DIAGNOSTIC WITH OUTPUT CAPTURE ===
echo Date: %date% %time%

echo.
echo 1. Current branch
git branch > push_debug_log.txt 2>&1

echo.
echo 2. Remote info
git remote -v >> push_debug_log.txt 2>&1

echo.
echo 3. Status
git status >> push_debug_log.txt 2>&1

echo.
echo 4. Basic Push Attempt
git push origin HEAD:manager/powershell-optimization >> push_debug_log.txt 2>&1
echo Exit code: %ERRORLEVEL% >> push_debug_log.txt

echo.
echo 5. Force Push Attempt  
git push origin HEAD:manager/powershell-optimization -f >> push_debug_log.txt 2>&1
echo Exit code: %ERRORLEVEL% >> push_debug_log.txt

echo.
echo 6. Authenticated Push Attempt
set GH_TOKEN=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
git push https://gerivdb:%GH_TOKEN%@github.com/gerivdb/email-sender-1.git HEAD:manager/powershell-optimization -f >> push_debug_log.txt 2>&1
echo Exit code: %ERRORLEVEL% >> push_debug_log.txt

echo.
echo === DEBUG LOG CREATED: push_debug_log.txt ===

echo.
echo Operation complete. Check push_debug_log.txt for details.
pause
