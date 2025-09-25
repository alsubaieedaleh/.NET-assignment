# Test Registration Flow with Proper Password Examples
Write-Host "Testing Car Dealer API Registration Flow" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$baseUrl = "http://localhost:5101"

# Test 1: Registration with proper password
Write-Host "`n1. Testing Registration with Valid Password..." -ForegroundColor Yellow
$registrationData = @{
    email = "newuser@example.com"
    password = "MySecure123!"  # Meets all requirements: 8+ chars, upper, lower, digit, special
    fullName = "New User"
    role = "Customer"
} | ConvertTo-Json

try {
    $otpResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/register/send-otp" -Method Post -Body $registrationData -ContentType "application/json"
    Write-Host "✅ Registration OTP sent successfully!" -ForegroundColor Green
    Write-Host "   OTP ID: $($otpResponse.otpId)" -ForegroundColor Cyan
    Write-Host "   OTP Code: $($otpResponse.code)" -ForegroundColor Cyan
    
    # Test 2: Confirm registration with OTP
    Write-Host "`n2. Testing OTP Confirmation..." -ForegroundColor Yellow
    $confirmData = @{
        otpId = $otpResponse.otpId
        code = $otpResponse.code
    } | ConvertTo-Json
    
    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/register/confirm" -Method Post -Body $confirmData -ContentType "application/json"
    Write-Host "✅ Registration confirmed successfully!" -ForegroundColor Green
    Write-Host "   JWT Token: $($tokenResponse.token.Substring(0, 50))..." -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorContent = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorContent)
        $errorText = $reader.ReadToEnd()
        Write-Host "   Error details: $errorText" -ForegroundColor Red
    }
}

# Test 3: Login flow
Write-Host "`n3. Testing Login Flow..." -ForegroundColor Yellow
$loginData = @{
    email = "admin@dealer.local"
    password = "Admin#12345"
} | ConvertTo-Json

try {
    $loginOtpResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/send-otp" -Method Post -Body $loginData -ContentType "application/json"
    Write-Host "✅ Login OTP sent successfully!" -ForegroundColor Green
    Write-Host "   OTP ID: $($loginOtpResponse.otpId)" -ForegroundColor Cyan
    Write-Host "   OTP Code: $($loginOtpResponse.code)" -ForegroundColor Cyan
    
    # Confirm login
    $loginConfirmData = @{
        otpId = $loginOtpResponse.otpId
        code = $loginOtpResponse.code
    } | ConvertTo-Json
    
    $loginTokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login/confirm" -Method Post -Body $loginConfirmData -ContentType "application/json"
    Write-Host "✅ Login confirmed successfully!" -ForegroundColor Green
    Write-Host "   JWT Token: $($loginTokenResponse.token.Substring(0, 50))..." -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test with invalid password
Write-Host "`n4. Testing with Invalid Password (should fail)..." -ForegroundColor Yellow
$invalidPasswordData = @{
    email = "test@example.com"
    password = "weak"  # Too short, no uppercase, no digit, no special char
    fullName = "Test User"
    role = "Customer"
} | ConvertTo-Json

try {
    $invalidResponse = Invoke-RestMethod -Uri "$baseUrl/api/Auth/register/send-otp" -Method Post -Body $invalidPasswordData -ContentType "application/json"
    Write-Host "❌ This should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Correctly rejected invalid password" -ForegroundColor Green
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`nRegistration Flow Testing Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

Write-Host "`nPassword Requirements Summary:" -ForegroundColor Cyan
Write-Host "• Minimum 8 characters" -ForegroundColor White
Write-Host "• At least one uppercase letter (A-Z)" -ForegroundColor White
Write-Host "• At least one lowercase letter (a-z)" -ForegroundColor White
Write-Host "• At least one digit (0-9)" -ForegroundColor White
Write-Host "• At least one special character" -ForegroundColor White
Write-Host "• Example valid password: MySecure123!" -ForegroundColor Green