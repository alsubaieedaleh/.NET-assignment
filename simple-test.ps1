# Simple Car Dealer API Test Script
Write-Host "Testing Car Dealer API..." -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

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

# Test 3: Admin Login Flow
Write-Host "`n3. Testing Admin Login..." -ForegroundColor Yellow
try {
    # Get OTP
    $loginData = @{
        email = "admin@dealer.local"
        password = "Admin#12345"
    } | ConvertTo-Json

    $otpResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/send-otp" -Method Post -Body $loginData -ContentType "application/json" -TimeoutSec 10
    
    # Confirm login
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

# Test 4: Admin Endpoints (if login succeeded)
if ($adminToken) {
    Write-Host "`n4. Testing Admin Endpoints..." -ForegroundColor Yellow
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

# Test 5: Security Test (should return 401)
Write-Host "`n5. Testing Security..." -ForegroundColor Yellow
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
Write-Host "`nTest Results Summary:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
foreach ($result in $results) {
    Write-Host $result -ForegroundColor White
}

$successCount = ($results | Where-Object { $_ -like "✅*" }).Count
$totalCount = $results.Count
Write-Host "`nSuccess Rate: $successCount/$totalCount" -ForegroundColor Cyan
