# RSKitchen Test Suite Runner
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  🧪 RSKITCHEN - SUITE DE PRUEBAS AUTOMATIZADAS" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ejecutando pruebas unitarias, de integración y seguridad..." -ForegroundColor Gray
Write-Host ""

& .\mvnw.cmd test

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host "  [OK] TODAS LAS PRUEBAS PASARON EXITOSAMENTE (0 ERRORES)" -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Red
    Write-Host "  [ERROR] HUBO FALLOS EN LA SUITE DE PRUEBAS" -ForegroundColor Red
    Write-Host "=======================================================" -ForegroundColor Red
}
