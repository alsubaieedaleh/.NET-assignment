using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CarDealer.Api.Migrations
{
    /// <inheritdoc />
    public partial class OtpAdjustments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "OtpCodes",
                type: "TEXT",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "TEXT");

            migrationBuilder.AddColumn<string>(
                name: "PayloadJson",
                table: "OtpCodes",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TargetEmail",
                table: "OtpCodes",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PayloadJson",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "TargetEmail",
                table: "OtpCodes");

            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "OtpCodes",
                type: "TEXT",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldNullable: true);
        }
    }
}
