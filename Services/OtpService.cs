using System.Security.Cryptography;
using System.Text.Json;
using CarDealer.Api.Data;
using CarDealer.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace CarDealer.Api.Services
{
    public interface IOtpService
    {
        Task<OtpCode> GenerateAsync(string? userId, OtpPurpose purpose, string? targetEmail = null, object? payload = null, int ttlMinutes = 5);
        Task<bool> ValidateAsync(string code, OtpPurpose purpose, string? userId = null, string? targetEmail = null);
        Task ConsumeAsync(int id);
        Task<OtpCode?> GetByIdAsync(int id);
        Task<OtpCode?> ValidateAndConsumeAsync(int id, string code, OtpPurpose purpose);
    }

    public class OtpService : IOtpService
    {
        private readonly ApplicationDbContext _db;

        public OtpService(ApplicationDbContext db)
        {
            _db = db;
        }

        public async Task<OtpCode> GenerateAsync(string? userId, OtpPurpose purpose, string? targetEmail = null, object? payload = null, int ttlMinutes = 5)
        {
            var code = RandomNumberGenerator.GetInt32(100000, 999999).ToString();
            var otp = new OtpCode
            {
                UserId = userId,
                Purpose = purpose,
                Code = code,
                ExpiresAtUtc = DateTime.UtcNow.AddMinutes(ttlMinutes),
                TargetEmail = targetEmail,
                PayloadJson = payload != null ? JsonSerializer.Serialize(payload) : null
            };
            _db.OtpCodes.Add(otp);
            await _db.SaveChangesAsync();
            return otp;
        }

        public async Task<bool> ValidateAsync(string code, OtpPurpose purpose, string? userId = null, string? targetEmail = null)
        {
            var now = DateTime.UtcNow;
            var query = _db.OtpCodes.Where(o => o.Code == code && o.Purpose == purpose && o.ConsumedAtUtc == null && o.ExpiresAtUtc > now);
            if (!string.IsNullOrEmpty(userId))
            {
                query = query.Where(o => o.UserId == userId);
            }
            if (!string.IsNullOrEmpty(targetEmail))
            {
                query = query.Where(o => o.TargetEmail == targetEmail);
            }
            var otp = await query.OrderByDescending(o => o.Id).FirstOrDefaultAsync();
            return otp != null;
        }

        public async Task ConsumeAsync(int id)
        {
            var otp = await _db.OtpCodes.FindAsync(id);
            if (otp != null && otp.ConsumedAtUtc == null)
            {
                otp.ConsumedAtUtc = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }
        }

        public Task<OtpCode?> GetByIdAsync(int id)
        {
            return _db.OtpCodes.AsNoTracking().FirstOrDefaultAsync(o => o.Id == id);
        }

        public async Task<OtpCode?> ValidateAndConsumeAsync(int id, string code, OtpPurpose purpose)
        {
            var now = DateTime.UtcNow;
            var otp = await _db.OtpCodes.FirstOrDefaultAsync(o => o.Id == id && o.Code == code && o.Purpose == purpose && o.ConsumedAtUtc == null && o.ExpiresAtUtc > now);
            if (otp == null)
            {
                return null;
            }
            otp.ConsumedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return otp;
        }
    }
}


