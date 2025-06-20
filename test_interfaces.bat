@echo off
cd pkg\docmanager
go test -v -run "TestManagerType"
echo.
echo Running Repository tests...
go test -v -run "TestRepository_Enhanced"
echo.
echo All interface enhancement tests completed.
pause
