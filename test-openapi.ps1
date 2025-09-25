# Test OpenAPI Implementation
Write-Host "Testing OpenAPI Implementation..." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$baseUrl = "http://localhost:5101"

# Test 1: Health Check
Write-Host "`n1. Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✅ Health Check: OK - $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Check: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: OpenAPI JSON Endpoint
Write-Host "`n2. Testing OpenAPI JSON Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/openapi/v1.json" -Method Get
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ OpenAPI JSON: OK - Available at $baseUrl/openapi/v1.json" -ForegroundColor Green
    } else {
        Write-Host "❌ OpenAPI JSON: FAILED - Status: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ OpenAPI JSON: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: API Documentation UI
Write-Host "`n3. Testing API Documentation UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api-docs" -Method Get
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ API Documentation UI: OK - Available at $baseUrl/api-docs" -ForegroundColor Green
    } else {
        Write-Host "❌ API Documentation UI: FAILED - Status: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ API Documentation UI: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Vehicles Endpoint
Write-Host "`n4. Testing Vehicles Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles" -Method Get
    Write-Host "✅ Vehicles Endpoint: OK - Found $($response.Count) vehicles" -ForegroundColor Green
} catch {
    Write-Host "❌ Vehicles Endpoint: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nOpenAPI Testing Complete!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

Write-Host "`nOpenAPI Endpoints:" -ForegroundColor Cyan
Write-Host "• OpenAPI JSON: $baseUrl/openapi/v1.json" -ForegroundColor White
Write-Host "• API Documentation UI: $baseUrl/api-docs" -ForegroundColor White
Write-Host "• Health Check: $baseUrl/health" -ForegroundColor White
Write-Host "• Vehicles API: $baseUrl/api/Vehicles" -ForegroundColor White

Write-Host "`nKey Features:" -ForegroundColor Cyan
Write-Host "• Pure OpenAPI 3.0 specification" -ForegroundColor White
Write-Host "• JWT Bearer token authentication" -ForegroundColor White
Write-Host "• Interactive API documentation" -ForegroundColor White
Write-Host "• Modern Swagger UI interface" -ForegroundColor White
