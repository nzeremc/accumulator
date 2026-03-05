# Database Initialization Scripts

Place your SQL initialization script here.

## Expected File

- `schema.sql` - Database schema creation script

## What to Include

1. Database schemas
2. Tables
3. Indexes
4. Constraints
5. Functions/procedures (if needed)

## Example

```sql
-- schema.sql
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON app.users(email);
```

## How It Works

1. Place your `schema.sql` file in this directory
2. Run `terraform apply`
3. Terraform will automatically upload the file to S3
4. The ECS DB initialization task will:
   - Download the script from S3
   - Connect to the RDS database
   - Execute the script
   - Load static data files

## Notes

- The script will be executed on the PRIMARY RDS instance
- Database name: `docmp` (already created by Terraform)
- Master username: `docmp_admin` (from terraform.tfvars)
- Master password: Auto-generated (stored in AWS Secrets Manager)
- The script runs only once during initial setup