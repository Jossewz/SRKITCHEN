@echo off
chcp 65001 > nul
echo =======================================================
echo   🧪 RSKITCHEN - SUITE DE PRUEBAS AUTOMATIZADAS
echo =======================================================
echo.
echo Ejecutando pruebas unitarias, de integración y seguridad...
echo.

call mvnw.cmd test

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =======================================================
    echo   ✅ TODAS LAS PRUEBAS PASARON EXITOSAMENTE (0 ERRORES)
    echo =======================================================
) else (
    echo.
    echo =======================================================
    echo   ❌ HUBO FALLOS EN LA SUITE DE PRUEBAS
    echo =======================================================
)

echo.
pause
