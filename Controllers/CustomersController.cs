using CarDealer.Api.Data;
using CarDealer.Api.Models;
using CarDealer.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace CarDealer.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Customer,Admin")]
    public class CustomersController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IOtpService _otpService;

        public CustomersController(ApplicationDbContext db, IOtpService otpService)
        {
            _db = db;
            _otpService = otpService;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Name) ?? string.Empty;

        public record PurchaseRequestDto(int VehicleId);
        
        public record SendOtpResponse(int OtpId, string Code);
        
        public record ConfirmOtpDto(int OtpId, string Code);

        [HttpPost("purchase/send-otp")]
        public async Task<ActionResult<SendOtpResponse>> SendPurchaseOtp([FromBody] PurchaseRequestDto dto)
        {
            var vehicle = await _db.Vehicles.AsNoTracking().FirstOrDefaultAsync(v => v.Id == dto.VehicleId && v.IsAvailable);
            if (vehicle == null) return BadRequest("Vehicle unavailable");
            var userId = GetUserId();
            var otp = await _otpService.GenerateAsync(userId, OtpPurpose.PurchaseRequest, payload: dto, ttlMinutes: 10);
            return Ok(new SendOtpResponse(otp.Id, otp.Code));
        }

        [HttpPost("purchase/confirm")]
        public async Task<ActionResult<object>> ConfirmPurchase([FromBody] ConfirmOtpDto dto)
        {
            var userId = GetUserId();
            var otp = await _otpService.ValidateAndConsumeAsync(dto.OtpId, dto.Code, OtpPurpose.PurchaseRequest);
            if (otp == null || otp.UserId != userId) return BadRequest("Invalid or expired OTP");
            if (string.IsNullOrEmpty(otp.PayloadJson)) return BadRequest("Missing payload");
            var payload = System.Text.Json.JsonSerializer.Deserialize<PurchaseRequestDto>(otp.PayloadJson);
            if (payload == null) return BadRequest("Invalid payload");

            var vehicle = await _db.Vehicles.FirstOrDefaultAsync(v => v.Id == payload.VehicleId && v.IsAvailable);
            if (vehicle == null) return BadRequest("Vehicle unavailable");

            // Create purchase history entry and mark vehicle unavailable
            var purchase = new Purchase
            {
                UserId = userId,
                VehicleId = vehicle.Id,
                PriceAtPurchase = vehicle.Price,
                PurchasedAtUtc = DateTime.UtcNow
            };
            _db.Purchases.Add(purchase);
            vehicle.IsAvailable = false;
            await _db.SaveChangesAsync();

            return Ok(new { purchase.Id, purchase.PurchasedAtUtc, purchase.PriceAtPurchase, VehicleId = vehicle.Id });
        }

        [HttpGet("purchases")]
        public async Task<ActionResult<IEnumerable<object>>> PurchaseHistory()
        {
            var userId = GetUserId();
            var items = await _db.Purchases.AsNoTracking()
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.PurchasedAtUtc)
                .Select(p => new
                {
                    p.Id,
                    p.PurchasedAtUtc,
                    p.PriceAtPurchase,
                    p.VehicleId
                })
                .ToListAsync();
            return Ok(items);
        }
    }
}
