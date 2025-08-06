@echo off
REM === Test batch Roo universal CLI ===
echo [Roo-Test] Batch CLI universel > roo_test_cmd.log
echo [Roo-Test] Date : %DATE% %TIME% >> roo_test_cmd.log
REM Test d’exécution d’une commande simple
echo [Roo-Test] Test echo OK >> roo_test_cmd.log
echo OK
REM Test d’écriture dans le log
echo [Roo-Test] Fin du test batch >> roo_test_cmd.log
exit /b 0