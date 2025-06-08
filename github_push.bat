@echo off
cd "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo === GITHUB PUSH OPERATION ===
echo Target: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization

echo.
echo 1. Setting git credentials...
git config --global credential.helper store

echo.
echo 2. Checking remote configuration...
git remote -v

echo.
echo 3. Checking current branch...
git branch

echo.
echo 4. Pushing to GitHub (with authentication)...
set GITHUB_TOKEN=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
git push -u https://gerivdb:%GITHUB_TOKEN%@github.com/gerivdb/email-sender-1.git manager/powershell-optimization:manager/powershell-optimization --force

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Operation complete!
    echo SUCCESS: Changes pushed to GitHub
    echo VERIFY: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization
    echo SUCCESS > PUSH_RESULT.txt
) else (
    echo.
    echo ERROR: Git push failed with code %ERRORLEVEL%
    echo FAILED > PUSH_RESULT.txt
)

echo.
echo Press any key to continue...
pause > nul
