using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace CarDealer.Api.Data
{
    public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
    {
        public ApplicationDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
            // Fallback connection string for design-time
            const string connection = "Data Source=car_dealer.db";
            optionsBuilder.UseSqlite(connection);
            return new ApplicationDbContext(optionsBuilder.Options);
        }
    }
}


