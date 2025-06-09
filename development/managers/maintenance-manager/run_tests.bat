@echo off
echo Starting FMOUA Integration Tests...
cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\maintenance-manager"
echo Running: go test -v ./tests/
go test -v ./tests/
echo Test execution completed.
pause
