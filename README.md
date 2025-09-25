# CarDealer API

A comprehensive .NET 9 Web API for a car dealership management system with OTP-based authentication, role-based authorization, and OpenAPI documentation.

## 🚀 Features

- **OTP-based Authentication**: Secure registration and login with email verification
- **Role-based Authorization**: Customer and Admin roles with different permissions
- **Vehicle Management**: Browse, create, and manage vehicle inventory
- **Purchase System**: Customers can request and confirm vehicle purchases
- **Admin Dashboard**: Administrative functions for user and vehicle management
- **OpenAPI Documentation**: Complete API documentation with examples
- **SQLite Database**: Lightweight database with Entity Framework Core
- **JWT Authentication**: Secure token-based authentication

## 📋 Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)

## 🛠️ Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd CarDealerApi/CarDealer.Api
   ```

2. **Restore dependencies**
   ```bash
   dotnet restore
   ```

3. **Build the project**
   ```bash
   dotnet build
   ```

4. **Run the application**
   ```bash
   dotnet run
   ```

The API will be available at `http://localhost:5101`

## 📚 API Documentation

### OpenAPI Documentation

The API provides comprehensive OpenAPI documentation in multiple formats:

#### 1. **Interactive Swagger UI**
```
http://localhost:5101/api-docs
```
- Interactive interface to test all endpoints
- Pre-filled examples for all requests
- Authentication support with JWT tokens

#### 2. **OpenAPI JSON Specification**
```
http://localhost:5101/openapi/v1.json
```
- Raw OpenAPI 3.0 specification
- Can be imported into tools like Postman, Insomnia, etc.

#### 3. **Health Check**
```
http://localhost:5101/health
```
- Simple health check endpoint
- Returns `{"status":"ok"}` when the API is running

## 🔐 Authentication Flow

### Registration Process

1. **Send OTP for Registration**
   ```http
   POST /api/Auth/register/send-otp
   Content-Type: application/json

   {
     "email": "user@example.com",
     "password": "MySecure123!",
     "fullName": "John Doe",
     "role": "Customer"
   }
   ```

2. **Confirm Registration with OTP**
   ```http
   POST /api/Auth/register/confirm
   Content-Type: application/json

   {
     "otpId": 123,
     "code": "123456"
   }
   ```

### Login Process

1. **Send OTP for Login**
   ```http
   POST /api/Auth/login/send-otp
   Content-Type: application/json

   {
     "email": "user@example.com",
     "password": "MySecure123!"
   }
   ```

2. **Confirm Login with OTP**
   ```http
   POST /api/Auth/login/confirm
   Content-Type: application/json

   {
     "otpId": 123,
     "code": "123456"
   }
   ```

### Password Requirements

Passwords must meet the following criteria:
- **Minimum 8 characters**
- **At least one uppercase letter (A-Z)**
- **At least one lowercase letter (a-z)**
- **At least one digit (0-9)**
- **At least one special character (!@#$%^&*)**

**Example valid password**: `MySecure123!`

## 🚗 API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/Auth/register/send-otp` | Send OTP for registration | No |
| POST | `/api/Auth/register/confirm` | Confirm registration with OTP | No |
| POST | `/api/Auth/login/send-otp` | Send OTP for login | No |
| POST | `/api/Auth/login/confirm` | Confirm login with OTP | No |

### Vehicle Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/Vehicles` | Browse vehicles with filters | No |
| GET | `/api/Vehicles/{id}` | Get vehicle details | No |
| POST | `/api/Vehicles` | Create new vehicle | Admin |
| PUT | `/api/Vehicles/{id}` | Update vehicle | Admin |
| DELETE | `/api/Vehicles/{id}` | Delete vehicle | Admin |

### Customer Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/Customers/purchase/request` | Request vehicle purchase | Customer |
| POST | `/api/Customers/purchase/confirm` | Confirm purchase with OTP | Customer |
| GET | `/api/Customers/purchases` | Get purchase history | Customer |

### Admin Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/Admin/customers` | List all customers | Admin |
| GET | `/api/Admin/vehicles` | List all vehicles | Admin |
| GET | `/api/Admin/purchases` | List all purchases | Admin |

## 🧪 Testing the API

### Using PowerShell Scripts

The project includes several PowerShell scripts for testing:

#### 1. **Test Registration Flow**
```powershell
.\test-registration-flow.ps1
```

#### 2. **Test OpenAPI**
```powershell
.\test-openapi.ps1
```

#### 3. **Test All Endpoints**
```powershell
.\test-all-endpoints.ps1
```

### Manual Testing with curl

#### Test Health Endpoint
```bash
curl http://localhost:5101/health
```

#### Test Registration
```bash
# Step 1: Send OTP
curl -X POST http://localhost:5101/api/Auth/register/send-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "MySecure123!",
    "fullName": "Test User",
    "role": "Customer"
  }'

# Step 2: Confirm with OTP (use otpId and code from step 1)
curl -X POST http://localhost:5101/api/Auth/register/confirm \
  -H "Content-Type: application/json" \
  -d '{
    "otpId": 123,
    "code": "123456"
  }'
```

#### Test Vehicle Browsing
```bash
curl http://localhost:5101/api/Vehicles
```

## 🔧 Configuration

### Database

The application uses SQLite database with Entity Framework Core. The database file is automatically created at `car_dealer.db` in the project root.

### JWT Configuration

JWT tokens are configured with:
- **Expiration**: 24 hours
- **Issuer**: CarDealer.Api
- **Audience**: CarDealer.Api
- **Secret Key**: Configured in `appsettings.json`

### OTP Configuration

- **OTP Length**: 6 digits
- **Expiration**: 5 minutes
- **Purpose**: Registration, Login, Purchase Request, Vehicle Update

## 🏗️ Project Structure

```
CarDealer.Api/
├── Controllers/           # API Controllers
│   ├── AuthController.cs     # Authentication endpoints
│   ├── VehiclesController.cs # Vehicle management
│   ├── CustomersController.cs # Customer operations
│   └── AdminController.cs    # Admin operations
├── Data/                 # Database context and models
│   ├── ApplicationDbContext.cs
│   └── DesignTimeDbContextFactory.cs
├── Models/               # Data models
│   ├── ApplicationUser.cs
│   ├── Vehicle.cs
│   ├── Purchase.cs
│   └── OtpCode.cs
├── Services/             # Business logic services
│   ├── JwtTokenService.cs
│   └── OtpService.cs
├── Middleware/           # Custom middleware
│   └── ExceptionHandlingMiddleware.cs
├── Migrations/           # Database migrations
├── Program.cs            # Application startup
├── appsettings.json      # Configuration
└── README.md            # This file
```

## 🚨 Error Handling

The API includes comprehensive error handling:

### Common Error Responses

#### 400 Bad Request
```json
{
  "errors": [
    {
      "code": "PasswordTooShort",
      "description": "Passwords must be at least 8 characters."
    },
    {
      "code": "PasswordRequiresNonAlphanumeric",
      "description": "Passwords must have at least one non alphanumeric character."
    }
  ]
}
```

#### 401 Unauthorized
```json
{
  "error": "Unauthorized access"
}
```

#### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

#### 500 Internal Server Error
```json
{
  "error": "An unexpected error occurred"
}
```

## 🔒 Security Features

- **OTP-based Authentication**: Two-factor authentication for all user operations
- **JWT Tokens**: Secure token-based authentication
- **Role-based Authorization**: Different permissions for Customers and Admins
- **Password Validation**: Strong password requirements
- **Input Validation**: Comprehensive request validation
- **Exception Handling**: Secure error responses without sensitive information

## 🚀 Deployment

### Development
```bash
dotnet run
```

### Production
```bash
dotnet publish -c Release -o ./publish
cd publish
dotnet CarDealer.Api.dll
```

## 📝 Development Notes

### Adding New Endpoints

1. Create controller method with proper XML documentation
2. Add authentication/authorization attributes as needed
3. Update OpenAPI documentation
4. Test with provided PowerShell scripts

### Database Changes

1. Create new migration:
   ```bash
   dotnet ef migrations add MigrationName
   ```

2. Update database:
   ```bash
   dotnet ef database update
   ```

### Testing

- All endpoints include comprehensive XML documentation
- Examples are provided for all request/response models
- PowerShell scripts are available for automated testing
- OpenAPI documentation is automatically generated

 
## 🔑 **Default Admin Account**

For testing purposes, the system comes with a pre-configured admin account:

- **Email**: `admin@dealer.local`
- **Password**: `Admin#12345`
- **Role**: Admin

You can use these credentials to test admin-only endpoints and features.

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
- Check the OpenAPI documentation at `http://localhost:5101/api-docs`
- Review the error responses for troubleshooting
- Use the provided PowerShell test scripts
- Check the application logs for detailed error information

---

**Happy coding! 🚗💨**
