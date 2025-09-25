using CarDealer.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace CarDealer.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public AdminController(ApplicationDbContext db)
        {
            _db = db;
        }

        [HttpGet("debug")]
        [AllowAnonymous]
        public ActionResult Debug()
        {
            return Ok(new { 
                authenticated = User.Identity?.IsAuthenticated,
                name = User.Identity?.Name,
                roles = User.Claims.Where(c => c.Type == "role").Select(c => c.Value).ToArray(),
                allClaims = User.Claims.Select(c => new { c.Type, c.Value }).ToArray()
            });
        }

        [HttpGet("customers")]
        public async Task<ActionResult<IEnumerable<object>>> GetCustomers()
        {
            var customers = await _db.Users.AsNoTracking()
                .Select(u => new { u.Id, u.Email, u.FullName, u.CreatedAtUtc })
                .ToListAsync();
            return Ok(customers);
        }

        [HttpPost("sales/process/{purchaseId:int}")]
        public async Task<ActionResult> ProcessSale([FromRoute] int purchaseId)
        {
            var purchase = await _db.Purchases.Include(p => p.Vehicle).FirstOrDefaultAsync(p => p.Id == purchaseId);
            if (purchase == null) return NotFound();
            // Processing could include additional logic; here we simply confirm it exists
            return Ok(new { message = "Sale processed", purchase.Id });
        }
    }
}


