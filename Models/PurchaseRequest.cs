namespace CarDealer.Api.Models
{
    public enum PurchaseRequestStatus
    {
        Pending = 0,
        Approved = 1,
        Rejected = 2
    }

    public class PurchaseRequest
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int VehicleId { get; set; }
        public PurchaseRequestStatus Status { get; set; } = PurchaseRequestStatus.Pending;
        public DateTime RequestedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAtUtc { get; set; }

        public ApplicationUser? User { get; set; }
        public Vehicle? Vehicle { get; set; }
    }
}


