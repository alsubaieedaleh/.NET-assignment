using CarDealer.Api.Data;
using CarDealer.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace CarDealer.Api.Services
{
    public class DatabaseSeeder
    {
        private readonly IServiceProvider _serviceProvider;

        public DatabaseSeeder(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public async Task SeedAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            
            // Skip migration here since it's handled in Program.cs
            // await context.Database.MigrateAsync();

            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            // Roles
            foreach (var role in new[] { "Admin", "Customer" })
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole(role));
                }
            }

            // Admin user
            const string adminEmail = "admin@dealer.local";
            var admin = await userManager.FindByEmailAsync(adminEmail);
            if (admin == null)
            {
                admin = new ApplicationUser { UserName = adminEmail, Email = adminEmail, FullName = "Admin User", EmailConfirmed = true };
                await userManager.CreateAsync(admin, "Admin#12345");
                await userManager.AddToRoleAsync(admin, "Admin");
            }

            // Seed vehicles
            if (!await context.Vehicles.AnyAsync())
            {
                var vehicles = new List<Vehicle>
                {
                    new Vehicle { Make = "Toyota", Model = "Camry", Year = 2021, Price = 24000, Mileage = 15000, Color = "White" },
                    new Vehicle { Make = "Honda", Model = "Civic", Year = 2020, Price = 20000, Mileage = 20000, Color = "Black" },
                    new Vehicle { Make = "Ford", Model = "F-150", Year = 2019, Price = 30000, Mileage = 30000, Color = "Blue" },
                    new Vehicle { Make = "Tesla", Model = "Model 3", Year = 2022, Price = 38000, Mileage = 5000, Color = "Red" },
                    new Vehicle { Make = "BMW", Model = "3 Series", Year = 2018, Price = 22000, Mileage = 40000, Color = "Silver" },
                    new Vehicle { Make = "Audi", Model = "A4", Year = 2019, Price = 25000, Mileage = 35000, Color = "Gray" },
                    new Vehicle { Make = "Mercedes", Model = "C-Class", Year = 2020, Price = 32000, Mileage = 25000, Color = "White" },
                    new Vehicle { Make = "Hyundai", Model = "Elantra", Year = 2021, Price = 18000, Mileage = 12000, Color = "Blue" },
                    new Vehicle { Make = "Kia", Model = "Sorento", Year = 2020, Price = 26000, Mileage = 22000, Color = "Black" },
                    new Vehicle { Make = "Nissan", Model = "Altima", Year = 2019, Price = 19000, Mileage = 28000, Color = "White" }
                };
                context.Vehicles.AddRange(vehicles);
                await context.SaveChangesAsync();
            }
        }
    }
}


