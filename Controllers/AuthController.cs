using CarDealer.Api.Models;
using CarDealer.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace CarDealer.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly IOtpService _otpService;
        private readonly IJwtTokenService _jwtService;

        public AuthController(UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager, IOtpService otpService, IJwtTokenService jwtService)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _otpService = otpService;
            _jwtService = jwtService;
        }

        /// <summary>
        /// Registration request with user details
        /// </summary>
        /// <param name="Email">User's email address (must be unique)</param>
        /// <param name="Password">User's password (minimum 8 characters, must contain uppercase, lowercase, digit, and special character)</param>
        /// <param name="FullName">User's full name</param>
        /// <param name="Role">User's role (Customer or Admin)</param>
        public record RegisterRequest(
            string Email, 
            string Password, 
            string FullName, 
            string Role);
        
        /// <summary>
        /// OTP response with ID and code
        /// </summary>
        /// <param name="OtpId">OTP ID for verification</param>
        /// <param name="Code">6-digit OTP code</param>
        public record SendOtpResponse(int OtpId, string Code);
        
        /// <summary>
        /// OTP verification request
        /// </summary>
        /// <param name="OtpId">OTP ID from previous response</param>
        /// <param name="Code">6-digit OTP code</param>
        public record VerifyOtpRequest(int OtpId, string Code);
        
        /// <summary>
        /// Login request with credentials
        /// </summary>
        /// <param name="Email">User's email address</param>
        /// <param name="Password">User's password</param>
        public record LoginRequest(string Email, string Password);
        
        /// <summary>
        /// JWT token response
        /// </summary>
        /// <param name="Token">JWT Bearer token for API authentication</param>
        public record TokenResponse(string Token);

        /// <summary>
        /// Send OTP for user registration
        /// </summary>
        /// <param name="request">Registration details including email, password, full name, and role</param>
        /// <returns>OTP ID and code for verification</returns>
        /// <response code="200">OTP sent successfully</response>
        /// <response code="400">Invalid request data or password doesn't meet requirements</response>
        /// <response code="409">Email already exists</response>
        /// <remarks>
        /// Password requirements:
        /// - Minimum 8 characters
        /// - At least one uppercase letter (A-Z)
        /// - At least one lowercase letter (a-z)
        /// - At least one digit (0-9)
        /// - At least one special character (!@#$%^&amp;*)
        /// 
        /// Example valid password: MySecure123!
        /// </remarks>
        [HttpPost("register/send-otp")]
        [AllowAnonymous]
        public async Task<ActionResult<SendOtpResponse>> RegisterSendOtp([FromBody] RegisterRequest request)
        {
            var otp = await _otpService.GenerateAsync(null, OtpPurpose.Register, request.Email, request);
            // Simulate delivery: return the code in response for testing; in real systems, send via email/SMS
            return Ok(new SendOtpResponse(otp.Id, otp.Code));
        }

        /// <summary>
        /// Verify OTP and complete user registration
        /// </summary>
        /// <param name="request">OTP ID and code for verification</param>
        /// <returns>JWT token for authenticated access</returns>
        /// <response code="200">Registration successful, returns JWT token</response>
        /// <response code="400">Invalid OTP, request data, or password validation failed</response>
        /// <response code="404">OTP not found or expired</response>
        /// <response code="409">User already exists</response>
        /// <remarks>
        /// This endpoint completes the registration process by verifying the OTP code.
        /// If password validation fails, you'll receive detailed error messages about password requirements.
        /// </remarks>
        [HttpPost("register/confirm")]
        [AllowAnonymous]
        public async Task<ActionResult<TokenResponse>> RegisterConfirm([FromBody] VerifyOtpRequest request)
        {
            var otp = await _otpService.GetByIdAsync(request.OtpId);
            if (otp == null || otp.Purpose != OtpPurpose.Register)
            {
                return BadRequest("Invalid OTP");
            }
            var consumed = await _otpService.ValidateAndConsumeAsync(request.OtpId, request.Code, OtpPurpose.Register);
            if (consumed == null)
            {
                return BadRequest("Invalid or expired OTP");
            }

            if (string.IsNullOrEmpty(otp.PayloadJson))
            {
                return BadRequest("Missing registration payload");
            }

            var payload = System.Text.Json.JsonSerializer.Deserialize<RegisterRequest>(otp.PayloadJson);
            if (payload == null)
            {
                return BadRequest("Invalid registration data");
            }

            var existing = await _userManager.FindByEmailAsync(payload.Email);
            if (existing != null)
            {
                return Conflict("User already exists");
            }

            var user = new ApplicationUser { UserName = payload.Email, Email = payload.Email, FullName = payload.FullName, EmailConfirmed = true };
            var create = await _userManager.CreateAsync(user, payload.Password);
            if (!create.Succeeded)
            {
                return BadRequest(create.Errors);
            }

            var role = string.IsNullOrWhiteSpace(payload.Role) ? "Customer" : payload.Role;
            await _userManager.AddToRoleAsync(user, role);

            var token = await _jwtService.CreateTokenAsync(user);
            return Ok(new TokenResponse(token));
        }

        /// <summary>
        /// Send OTP for user login
        /// </summary>
        /// <param name="request">Login credentials (email and password)</param>
        /// <returns>OTP ID and code for verification</returns>
        /// <response code="200">OTP sent successfully</response>
        /// <response code="401">Invalid email or password</response>
        [HttpPost("login/send-otp")]
        [AllowAnonymous]
        public async Task<ActionResult<SendOtpResponse>> LoginSendOtp([FromBody] LoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null)
            {
                return Unauthorized();
            }
            var pwd = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
            if (!pwd.Succeeded)
            {
                return Unauthorized();
            }
            var otp = await _otpService.GenerateAsync(user.Id, OtpPurpose.Login, user.Email);
            return Ok(new SendOtpResponse(otp.Id, otp.Code));
        }

        /// <summary>
        /// Verify OTP and complete user login
        /// </summary>
        /// <param name="request">OTP ID and code for verification</param>
        /// <returns>JWT token for authenticated access</returns>
        /// <response code="200">Login successful, returns JWT token</response>
        /// <response code="400">Invalid OTP or request data</response>
        /// <response code="401">Invalid user or OTP</response>
        [HttpPost("login/confirm")]
        [AllowAnonymous]
        public async Task<ActionResult<TokenResponse>> LoginConfirm([FromBody] VerifyOtpRequest request)
        {
            var otp = await _otpService.GetByIdAsync(request.OtpId);
            if (otp == null || otp.Purpose != OtpPurpose.Login || string.IsNullOrEmpty(otp.UserId))
            {
                return BadRequest("Invalid OTP");
            }
            var consumed = await _otpService.ValidateAndConsumeAsync(request.OtpId, request.Code, OtpPurpose.Login);
            if (consumed == null)
            {
                return BadRequest("Invalid or expired OTP");
            }

            var user = await _userManager.FindByIdAsync(otp.UserId);
            if (user == null)
            {
                return Unauthorized();
            }
            var token = await _jwtService.CreateTokenAsync(user);
            return Ok(new TokenResponse(token));
        }
    }
}


