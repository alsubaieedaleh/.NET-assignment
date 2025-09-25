namespace CarDealer.Api.Models
{
    public enum OtpPurpose
    {
        Register = 0,
        Login = 1,
        PurchaseRequest = 2,
        UpdateVehicle = 3
    }

    public class OtpCode
    {
        public int Id { get; set; }
        public string? UserId { get; set; }
        public OtpPurpose Purpose { get; set; }
        public string Code { get; set; } = string.Empty;
        public DateTime ExpiresAtUtc { get; set; }
        public DateTime? ConsumedAtUtc { get; set; }
        public string? TargetEmail { get; set; }
        public string? PayloadJson { get; set; }

        public ApplicationUser? User { get; set; }
    }
}


