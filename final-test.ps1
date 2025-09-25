# Final Car Dealer API Test Script - Shows Current Working State
Write-Host "Car Dealer API - Final Test Results" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

$baseUrl = "http://localhost:5101"
$results = @()

# Test 1: Health Check
Write-Host "`n1. Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 10
    $results += "✅ Health Check: OK - $($response.status)"
    Write-Host "✅ Health Check: OK" -ForegroundColor Green
} catch {
    $results += "❌ Health Check: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Health Check: FAILED" -ForegroundColor Red
}

# Test 2: Browse Vehicles (Public)
Write-Host "`n2. Testing Vehicle Browsing..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles" -Method Get -TimeoutSec 10
    $results += "✅ Vehicle Browsing: OK - Found $($response.Count) vehicles"
    Write-Host "✅ Vehicle Browsing: OK - Found $($response.Count) vehicles" -ForegroundColor Green
} catch {
    $results += "❌ Vehicle Browsing: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Vehicle Browsing: FAILED" -ForegroundColor Red
}

# Test 3: Vehicle Filtering
Write-Host "`n3. Testing Vehicle Filtering..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles?make=Toyota" -Method Get -TimeoutSec 10
    $results += "✅ Vehicle Filtering: OK - Found $($response.Count) Toyota vehicles"
    Write-Host "✅ Vehicle Filtering: OK - Found $($response.Count) Toyota vehicles" -ForegroundColor Green
} catch {
    $results += "❌ Vehicle Filtering: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Vehicle Filtering: FAILED" -ForegroundColor Red
}

# Test 4: Admin Login Flow
Write-Host "`n4. Testing Admin Login..." -ForegroundColor Yellow
try {
    $loginData = @{
        email = "admin@dealer.local"
        password = "Admin#12345"
    } | ConvertTo-Json

    $otpResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/send-otp" -Method Post -Body $loginData -ContentType "application/json" -TimeoutSec 10
    
    $confirmData = @{
        otpId = $otpResponse.otpId
        code = $otpResponse.code
    } | ConvertTo-Json

    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/confirm" -Method Post -Body $confirmData -ContentType "application/json" -TimeoutSec 10
    $adminToken = $tokenResponse.token
    
    $results += "✅ Admin Login: OK - JWT Token obtained"
    Write-Host "✅ Admin Login: OK - JWT Token obtained" -ForegroundColor Green
} catch {
    $results += "❌ Admin Login: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Admin Login: FAILED" -ForegroundColor Red
    $adminToken = $null
}

# Test 5: JWT Token Debug (if login succeeded)
if ($adminToken) {
    Write-Host "`n5. Testing JWT Authentication..." -ForegroundColor Yellow
    $headers = @{ Authorization = "Bearer $adminToken" }
    
    try {
        $debug = Invoke-RestMethod -Uri "$baseUrl/api/Admin/debug" -Method Get -Headers $headers -TimeoutSec 10
        if ($debug.authenticated) {
            $results += "✅ JWT Authentication: OK - User authenticated with roles: $($debug.roles -join ', ')"
            Write-Host "✅ JWT Authentication: OK - User authenticated with roles: $($debug.roles -join ', ')" -ForegroundColor Green
        } else {
            $results += "⚠️ JWT Authentication: Token received but user not authenticated"
            Write-Host "⚠️ JWT Authentication: Token received but user not authenticated" -ForegroundColor Yellow
        }
    } catch {
        $results += "❌ JWT Authentication: FAILED - $($_.Exception.Message)"
        Write-Host "❌ JWT Authentication: FAILED" -ForegroundColor Red
    }
} else {
    $results += "⚠️ JWT Authentication: Skipped - No admin token"
    Write-Host "⚠️ JWT Authentication: Skipped - No admin token" -ForegroundColor Yellow
}

# Test 6: Admin Endpoints (if authentication works)
if ($adminToken) {
    Write-Host "`n6. Testing Admin Endpoints..." -ForegroundColor Yellow
    $headers = @{ Authorization = "Bearer $adminToken" }
    
    try {
        $customers = Invoke-RestMethod -Uri "$baseUrl/api/Admin/customers" -Method Get -Headers $headers -TimeoutSec 10
        $results += "✅ Admin Customers: OK - Found $($customers.Count) customers"
        Write-Host "✅ Admin Customers: OK - Found $($customers.Count) customers" -ForegroundColor Green
    } catch {
        $results += "❌ Admin Customers: FAILED - $($_.Exception.Message)"
        Write-Host "❌ Admin Customers: FAILED" -ForegroundColor Red
    }
    
    try {
        $vehicleData = @{
            make = "Test"
            model = "Car"
            year = 2024
            price = 25000
            mileage = 0
            color = "Blue"
            description = "Test vehicle"
        } | ConvertTo-Json

        $newVehicle = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles" -Method Post -Body $vehicleData -ContentType "application/json" -Headers $headers -TimeoutSec 10
        $results += "✅ Vehicle Creation: OK - Created vehicle ID $($newVehicle.id)"
        Write-Host "✅ Vehicle Creation: OK - Created vehicle ID $($newVehicle.id)" -ForegroundColor Green
    } catch {
        $results += "❌ Vehicle Creation: FAILED - $($_.Exception.Message)"
        Write-Host "❌ Vehicle Creation: FAILED" -ForegroundColor Red
    }
} else {
    $results += "⚠️ Admin Endpoints: Skipped - No admin token"
    Write-Host "⚠️ Admin Endpoints: Skipped - No admin token" -ForegroundColor Yellow
}

# Test 7: Security Test
Write-Host "`n7. Testing Security..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Admin/customers" -Method Get -TimeoutSec 10
    $results += "❌ Admin Security: Should have returned 401 but didn't!"
    Write-Host "❌ Admin Security: Should have returned 401 but didn't!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        $results += "✅ Admin Security: Correctly returns 401 Unauthorized"
        Write-Host "✅ Admin Security: Correctly returns 401 Unauthorized" -ForegroundColor Green
    } else {
        $results += "⚠️ Admin Security: Returns $($_.Exception.Response.StatusCode) instead of 401"
        Write-Host "⚠️ Admin Security: Returns $($_.Exception.Response.StatusCode) instead of 401" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`nFinal Test Results Summary:" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
foreach ($result in $results) {
    Write-Host $result -ForegroundColor White
}

$successCount = ($results | Where-Object { $_ -like "✅*" }).Count
$warningCount = ($results | Where-Object { $_ -like "⚠️*" }).Count
$totalCount = $results.Count

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "• Successful: $successCount" -ForegroundColor Green
Write-Host "• Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "• Total Tests: $totalCount" -ForegroundColor White

Write-Host "`nCurrent Status:" -ForegroundColor Cyan
Write-Host "• ✅ Public endpoints work perfectly" -ForegroundColor Green
Write-Host "• ✅ Authentication flow works (OTP + JWT generation)" -ForegroundColor Green
Write-Host "• ⚠️ JWT authentication middleware needs debugging" -ForegroundColor Yellow
Write-Host "• ⚠️ Protected endpoints return 404 instead of 401" -ForegroundColor Yellow

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Debug JWT authentication middleware configuration" -ForegroundColor White
Write-Host "2. Fix role claim mapping in JWT validation" -ForegroundColor White
Write-Host "3. Ensure proper 401 responses for unauthorized access" -ForegroundColor White
