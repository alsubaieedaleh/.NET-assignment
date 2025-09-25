using CarDealer.Api.Data;
using CarDealer.Api.Models;
using CarDealer.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CarDealer.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VehiclesController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IOtpService _otpService;

        public VehiclesController(ApplicationDbContext db, IOtpService otpService)
        {
            _db = db;
            _otpService = otpService;
        }

        /// <summary>
        /// Vehicle filter parameters
        /// </summary>
        public record VehicleFilter(
            string? Make, 
            string? Model, 
            int? MinYear, 
            int? MaxYear, 
            decimal? MinPrice, 
            decimal? MaxPrice, 
            bool? IsAvailable);
        
        /// <summary>
        /// Create vehicle request
        /// </summary>
        public record CreateVehicleRequest(
            string Make, 
            string Model, 
            int Year, 
            decimal Price, 
            int Mileage, 
            string Color, 
            string? Description);
        
        public record UpdateVehicleRequest(string? Make, string? Model, int? Year, decimal? Price, int? Mileage, string? Color, string? Description, bool? IsAvailable);
        
        public record SendOtpResponse(int OtpId, string Code);
        
        public record ConfirmUpdateRequest(int OtpId, string Code);

        /// <summary>
        /// Browse and filter vehicles
        /// </summary>
        /// <param name="filter">Optional filters for make, model, year range, price range, and availability</param>
        /// <returns>List of vehicles matching the filter criteria</returns>
        /// <response code="200">Returns list of vehicles</response>
        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<Vehicle>>> Browse([FromQuery] VehicleFilter filter)
        {
            var query = _db.Vehicles.AsNoTracking().AsQueryable();
            if (!string.IsNullOrWhiteSpace(filter.Make)) query = query.Where(v => v.Make == filter.Make);
            if (!string.IsNullOrWhiteSpace(filter.Model)) query = query.Where(v => v.Model == filter.Model);
            if (filter.MinYear.HasValue) query = query.Where(v => v.Year >= filter.MinYear.Value);
            if (filter.MaxYear.HasValue) query = query.Where(v => v.Year <= filter.MaxYear.Value);
            if (filter.MinPrice.HasValue) query = query.Where(v => v.Price >= filter.MinPrice.Value);
            if (filter.MaxPrice.HasValue) query = query.Where(v => v.Price <= filter.MaxPrice.Value);
            if (filter.IsAvailable.HasValue) query = query.Where(v => v.IsAvailable == filter.IsAvailable.Value);
            var list = await query.OrderByDescending(v => v.CreatedAtUtc).ToListAsync();
            return Ok(list);
        }

        /// <summary>
        /// Get vehicle details by ID
        /// </summary>
        /// <param name="id">Vehicle ID</param>
        /// <returns>Vehicle details</returns>
        /// <response code="200">Returns vehicle details</response>
        /// <response code="404">Vehicle not found</response>
        [HttpGet("{id:int}")]
        [AllowAnonymous]
        public async Task<ActionResult<Vehicle>> Details([FromRoute] int id)
        {
            var vehicle = await _db.Vehicles.AsNoTracking().FirstOrDefaultAsync(v => v.Id == id);
            if (vehicle == null) return NotFound();
            return Ok(vehicle);
        }

        /// <summary>
        /// Create a new vehicle (Admin only)
        /// </summary>
        /// <param name="request">Vehicle creation details</param>
        /// <returns>Created vehicle</returns>
        /// <response code="201">Vehicle created successfully</response>
        /// <response code="400">Invalid request data</response>
        /// <response code="401">Unauthorized - Admin role required</response>
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Vehicle>> Create([FromBody] CreateVehicleRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Make) || string.IsNullOrWhiteSpace(request.Model))
            {
                return BadRequest("Make and Model are required");
            }
            var vehicle = new Vehicle
            {
                Make = request.Make,
                Model = request.Model,
                Year = request.Year,
                Price = request.Price,
                Mileage = request.Mileage,
                Color = request.Color,
                Description = request.Description,
                IsAvailable = true
            };
            _db.Vehicles.Add(vehicle);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Details), new { id = vehicle.Id }, vehicle);
        }

        [HttpPost("{id:int}/update/send-otp")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<SendOtpResponse>> SendUpdateOtp([FromRoute] int id, [FromBody] UpdateVehicleRequest request)
        {
            var vehicle = await _db.Vehicles.FindAsync(id);
            if (vehicle == null) return NotFound();
            var otp = await _otpService.GenerateAsync(null, OtpPurpose.UpdateVehicle, payload: request, ttlMinutes: 10);
            return Ok(new SendOtpResponse(otp.Id, otp.Code));
        }

        [HttpPost("{id:int}/update/confirm")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Vehicle>> ConfirmUpdate([FromRoute] int id, [FromBody] ConfirmUpdateRequest request)
        {
            var vehicle = await _db.Vehicles.FindAsync(id);
            if (vehicle == null) return NotFound();
            var otp = await _otpService.ValidateAndConsumeAsync(request.OtpId, request.Code, OtpPurpose.UpdateVehicle);
            if (otp == null) return BadRequest("Invalid or expired OTP");
            if (string.IsNullOrEmpty(otp.PayloadJson)) return BadRequest("Missing update payload");
            var update = System.Text.Json.JsonSerializer.Deserialize<UpdateVehicleRequest>(otp.PayloadJson);
            if (update == null) return BadRequest("Invalid update payload");

            if (!string.IsNullOrWhiteSpace(update.Make)) vehicle.Make = update.Make;
            if (!string.IsNullOrWhiteSpace(update.Model)) vehicle.Model = update.Model;
            if (update.Year.HasValue) vehicle.Year = update.Year.Value;
            if (update.Price.HasValue) vehicle.Price = update.Price.Value;
            if (update.Mileage.HasValue) vehicle.Mileage = update.Mileage.Value;
            if (!string.IsNullOrWhiteSpace(update.Color)) vehicle.Color = update.Color;
            if (update.Description != null) vehicle.Description = update.Description;
            if (update.IsAvailable.HasValue) vehicle.IsAvailable = update.IsAvailable.Value;
            vehicle.UpdatedAtUtc = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return Ok(vehicle);
        }
    }
}


