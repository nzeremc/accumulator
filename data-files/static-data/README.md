# Static Data Files

Place your static data files here for database loading.

## Supported Formats

- CSV files (`.csv`)
- JSON files (`.json`)
- SQL files with INSERT statements (`.sql`)

## Example Files

### users.csv
```csv
id,username,email,role
1,admin,admin@example.com,admin
2,user1,user1@example.com,user
3,user2,user2@example.com,user
```

### config.json
```json
{
  "settings": {
    "max_connections": 100,
    "timeout": 30,
    "retry_attempts": 3
  }
}
```

### seed_data.sql
```sql
INSERT INTO app.categories (name, description) VALUES
('Category 1', 'Description 1'),
('Category 2', 'Description 2'),
('Category 3', 'Description 3');
```

## How It Works

1. Place your data files in this directory
2. Run `terraform apply`
3. Terraform will automatically upload all files to S3
4. The ECS DB initialization task will:
   - Download all files from S3
   - Process each file based on its type
   - Load data into the database

## File Organization

You can organize files in subdirectories:

```
static-data/
├── users/
│   ├── admins.csv
│   └── regular_users.csv
├── config/
│   └── settings.json
└── seed/
    └── initial_data.sql
```

All files and subdirectories will be uploaded to S3 and processed during initialization.

## Notes

- Files are uploaded to S3 automatically by Terraform
- DB init task processes files in alphabetical order
- Large files are supported
- Files are only uploaded when they change