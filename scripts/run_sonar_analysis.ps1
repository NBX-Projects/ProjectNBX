<#
.SYNOPSIS
    Gera relatórios de cobertura de testes (Flutter e Go) e executa o SonarScanner localmente via Docker.
.DESCRIPTION
    1. Executa `flutter test --coverage` (gera coverage/lcov.info)
    2. Executa `go test -coverprofile=backend/coverage.out ./...`
    3. Roda o container sonarsource/sonar-scanner-cli apontando para o sonar-project.properties
#>

param (
    [string]$SonarHostUrl = "http://localhost:9000",
    [string]$SonarToken = ""
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 [1/3] Executando testes e gerando cobertura do Flutter..." -ForegroundColor Cyan
flutter test --coverage

Write-Host "🐹 [2/3] Executando testes e gerando cobertura do Backend Go..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\backend"
try {
    go test -v "-coverprofile=coverage.out" ./...
} catch {
    Write-Warning "Aviso: alguns testes em Go podem precisar de mocks adicionais."
} finally {
    Pop-Location
}

Write-Host "📊 [3/3] Executando SonarScanner via Docker..." -ForegroundColor Cyan
$projectDir = (Get-Item "$PSScriptRoot\..").FullName

$dockerArgs = @(
    "run", "--rm", "--network", "host",
    "-v", "${projectDir}:/usr/src",
    "sonarsource/sonar-scanner-cli",
    "-Dsonar.host.url=$SonarHostUrl"
)

if ($SonarToken -ne "") {
    $dockerArgs += "-Dsonar.token=$SonarToken"
}

docker @dockerArgs

Write-Host "✅ Análise de qualidade do Sonar concluída!" -ForegroundColor Green
