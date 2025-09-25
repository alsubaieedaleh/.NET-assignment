namespace CarDealer.Api.Models
{
    public class Purchase
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int VehicleId { get; set; }
        public decimal PriceAtPurchase { get; set; }
        public DateTime PurchasedAtUtc { get; set; } = DateTime.UtcNow;

        public ApplicationUser? User { get; set; }
        public Vehicle? Vehicle { get; set; }
    }
}


