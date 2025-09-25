# CarDealer API Comprehensive Test Script
Write-Host "Testing CarDealer API Endpoints..." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$baseUrl = "http://localhost:5101"
$results = @()

# Test 1: Health Check
Write-Host "`n1. Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    $results += "✅ Health Check: OK - $($response.status)"
    Write-Host "✅ Health Check: OK" -ForegroundColor Green
} catch {
    $results += "❌ Health Check: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Health Check: FAILED" -ForegroundColor Red
}

# Test 2: Browse Vehicles (Public)
Write-Host "`n2. Testing Vehicle Browsing..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles" -Method Get
    $results += "✅ Vehicle Browsing: OK - Found $($response.Count) vehicles"
    Write-Host "✅ Vehicle Browsing: OK - Found $($response.Count) vehicles" -ForegroundColor Green
} catch {
    $results += "❌ Vehicle Browsing: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Vehicle Browsing: FAILED" -ForegroundColor Red
}

# Test 3: Get Vehicle Details (Public)
Write-Host "`n3. Testing Vehicle Details..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles/10" -Method Get
    $results += "✅ Vehicle Details: OK - Vehicle: $($response.make) $($response.model)"
    Write-Host "✅ Vehicle Details: OK - Vehicle: $($response.make) $($response.model)" -ForegroundColor Green
} catch {
    $results += "❌ Vehicle Details: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Vehicle Details: FAILED" -ForegroundColor Red
}

# Test 4: Register User (Public)
Write-Host "`n4. Testing User Registration..." -ForegroundColor Yellow
try {
    $registerData = @{
        email = "test@example.com"
        password = "TestPassword123!"
        fullName = "Test User"
        role = "Customer"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/Auth/register/send-otp" -Method Post -Body $registerData -ContentType "application/json"
    $results += "✅ User Registration: OK - OTP ID: $($response.otpId), Code: $($response.code)"
    Write-Host "✅ User Registration: OK - OTP ID: $($response.otpId)" -ForegroundColor Green
    
    # Store OTP for later use
    $otpId = $response.otpId
    $otpCode = $response.code
} catch {
    $results += "❌ User Registration: FAILED - $($_.Exception.Message)"
    Write-Host "❌ User Registration: FAILED" -ForegroundColor Red
}

# Test 5: Login (Public)
Write-Host "`n5. Testing User Login..." -ForegroundColor Yellow
try {
    $loginData = @{
        email = "admin@dealer.local"
        password = "Admin#12345"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/send-otp" -Method Post -Body $loginData -ContentType "application/json"
    $results += "✅ User Login: OK - OTP ID: $($response.otpId), Code: $($response.code)"
    Write-Host "✅ User Login: OK - OTP ID: $($response.otpId)" -ForegroundColor Green
    
    # Store admin OTP for later use
    $adminOtpId = $response.otpId
    $adminOtpCode = $response.code
} catch {
    $results += "❌ User Login: FAILED - $($_.Exception.Message)"
    Write-Host "❌ User Login: FAILED" -ForegroundColor Red
}

# Test 6: Swagger UI
Write-Host "`n6. Testing Swagger UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api-docs" -Method Get
    if ($response.StatusCode -eq 200) {
        $results += "✅ Swagger UI: OK - Accessible at $baseUrl/api-docs"
        Write-Host "✅ Swagger UI: OK - Accessible at $baseUrl/api-docs" -ForegroundColor Green
    } else {
        $results += "❌ Swagger UI: FAILED - Status: $($response.StatusCode)"
        Write-Host "❌ Swagger UI: FAILED" -ForegroundColor Red
    }
} catch {
    $results += "❌ Swagger UI: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Swagger UI: FAILED" -ForegroundColor Red
}

# Test 7: Get JWT Token for Admin (Complete login flow)
Write-Host "`n7. Testing Admin Login Flow..." -ForegroundColor Yellow
try {
    # First get OTP
    $adminLoginData = @{
        email = "admin@dealer.local"
        password = "Admin#12345"
    } | ConvertTo-Json

    $adminOtpResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/send-otp" -Method Post -Body $adminLoginData -ContentType "application/json"
    
    # Then confirm with OTP to get JWT token
    $adminConfirmData = @{
        otpId = $adminOtpResponse.otpId
        code = $adminOtpResponse.code
    } | ConvertTo-Json

    $adminTokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/confirm" -Method Post -Body $adminConfirmData -ContentType "application/json"
    $adminToken = $adminTokenResponse.token
    $results += "✅ Admin Login: OK - JWT Token obtained"
    Write-Host "✅ Admin Login: OK - JWT Token obtained" -ForegroundColor Green
} catch {
    $results += "❌ Admin Login: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Admin Login: FAILED" -ForegroundColor Red
    $adminToken = $null
}

# Test 8: Admin Endpoints with Authentication
if ($adminToken) {
    Write-Host "`n8. Testing Admin Endpoints with Auth..." -ForegroundColor Yellow
    $headers = @{ Authorization = "Bearer $adminToken" }
    
    try {
        $adminCustomers = Invoke-RestMethod -Uri "$baseUrl/api/Admin/customers" -Method Get -Headers $headers
        $results += "✅ Admin Customers: OK - Found $($adminCustomers.Count) customers"
        Write-Host "✅ Admin Customers: OK - Found $($adminCustomers.Count) customers" -ForegroundColor Green
    } catch {
        $results += "❌ Admin Customers: FAILED - $($_.Exception.Message)"
        Write-Host "❌ Admin Customers: FAILED" -ForegroundColor Red
    }
} else {
    $results += "⚠️ Admin Endpoints: Skipped - No admin token"
    Write-Host "⚠️ Admin Endpoints: Skipped - No admin token" -ForegroundColor Yellow
}

# Test 9: Vehicle Creation (Admin only)
if ($adminToken) {
    Write-Host "`n9. Testing Vehicle Creation (Admin)..." -ForegroundColor Yellow
    $headers = @{ Authorization = "Bearer $adminToken" }
    
    try {
        $newVehicleData = @{
            make = "Test"
            model = "Car"
            year = 2024
            price = 25000
            mileage = 0
            color = "Blue"
            description = "Test vehicle for API testing"
        } | ConvertTo-Json

        $newVehicle = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles" -Method Post -Body $newVehicleData -ContentType "application/json" -Headers $headers
        $results += "✅ Vehicle Creation: OK - Created vehicle ID $($newVehicle.id)"
        Write-Host "✅ Vehicle Creation: OK - Created vehicle ID $($newVehicle.id)" -ForegroundColor Green
    } catch {
        $results += "❌ Vehicle Creation: FAILED - $($_.Exception.Message)"
        Write-Host "❌ Vehicle Creation: FAILED" -ForegroundColor Red
    }
} else {
    $results += "⚠️ Vehicle Creation: Skipped - No admin token"
    Write-Host "⚠️ Vehicle Creation: Skipped - No admin token" -ForegroundColor Yellow
}

# Test 10: Vehicle Filtering
Write-Host "`n10. Testing Vehicle Filtering..." -ForegroundColor Yellow
try {
    $filteredVehicles = Invoke-RestMethod -Uri "$baseUrl/api/Vehicles?make=Toyota" -Method Get
    $results += "✅ Vehicle Filtering: OK - Found $($filteredVehicles.Count) Toyota vehicles"
    Write-Host "✅ Vehicle Filtering: OK - Found $($filteredVehicles.Count) Toyota vehicles" -ForegroundColor Green
} catch {
    $results += "❌ Vehicle Filtering: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Vehicle Filtering: FAILED" -ForegroundColor Red
}

# Test 11: Customer Registration and Purchase Flow (with unique email)
Write-Host "`n11. Testing Customer Registration and Purchase..." -ForegroundColor Yellow
try {
    # Register a new customer with timestamp to make email unique
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $customerData = @{
        email = "customer$timestamp@test.com"
        password = "Customer123!"
        fullName = "Test Customer $timestamp"
        role = "Customer"
    } | ConvertTo-Json

    $customerOtpResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/register/send-otp" -Method Post -Body $customerData -ContentType "application/json"
    
    # Confirm registration
    $customerConfirmData = @{
        otpId = $customerOtpResponse.otpId
        code = $customerOtpResponse.code
    } | ConvertTo-Json

    $customerTokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/register/confirm" -Method Post -Body $customerConfirmData -ContentType "application/json"
    $customerToken = $customerTokenResponse.token
    $results += "✅ Customer Registration: OK - Customer registered and logged in"
    Write-Host "✅ Customer Registration: OK - Customer registered and logged in" -ForegroundColor Green
    
    # Test customer purchase history (should be empty)
    $customerHeaders = @{ Authorization = "Bearer $customerToken" }
    $purchaseHistory = Invoke-RestMethod -Uri "$baseUrl/api/Customers/purchases" -Method Get -Headers $customerHeaders
    $results += "✅ Customer Purchase History: OK - Found $($purchaseHistory.Count) purchases"
    Write-Host "✅ Customer Purchase History: OK - Found $($purchaseHistory.Count) purchases" -ForegroundColor Green
    
} catch {
    $results += "❌ Customer Registration/Purchase: FAILED - $($_.Exception.Message)"
    Write-Host "❌ Customer Registration/Purchase: FAILED" -ForegroundColor Red
}

# Test 12: Test Admin Endpoints Without Auth (Should return 401)
Write-Host "`n12. Testing Admin/Customer Endpoints Security..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Admin/customers" -Method Get
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

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Customers/purchases" -Method Get
    $results += "❌ Customer Security: Should have returned 401 but didn't!"
    Write-Host "❌ Customer Security: Should have returned 401 but didn't!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        $results += "✅ Customer Security: Correctly returns 401 Unauthorized"
        Write-Host "✅ Customer Security: Correctly returns 401 Unauthorized" -ForegroundColor Green
    } else {
        $results += "⚠️ Customer Security: Returns $($_.Exception.Response.StatusCode) instead of 401"
        Write-Host "⚠️ Customer Security: Returns $($_.Exception.Response.StatusCode) instead of 401" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`nAPI Testing Complete!" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host "`nResults Summary:" -ForegroundColor Cyan
foreach ($result in $results) {
    Write-Host $result -ForegroundColor White
}

Write-Host "`nQuick Access:" -ForegroundColor Cyan
Write-Host "• API Base URL: $baseUrl" -ForegroundColor White
Write-Host "• Swagger UI: $baseUrl/api-docs" -ForegroundColor White
Write-Host "• Health Check: $baseUrl/health" -ForegroundColor White
Write-Host "• Browse Vehicles: $baseUrl/api/Vehicles" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Open Swagger UI to test endpoints interactively" -ForegroundColor White
Write-Host "2. Use the OTP codes above to complete registration/login" -ForegroundColor White
Write-Host "3. Get JWT tokens to test protected endpoints" -ForegroundColor White
