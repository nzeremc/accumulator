#!/bin/bash
set -e

echo "Starting database initialization..."

# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --query SecretString --output text)
DB_USERNAME=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_SECRET" | jq -r '.password')
DB_HOST_PRIMARY=$(echo "$DB_SECRET" | jq -r '.host_primary')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')

export PGPASSWORD="$DB_PASSWORD"

# Check if database is accessible
echo "Checking database connectivity..."
if ! psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "ERROR: Cannot connect to database"
    exit 1
fi

# Check if initialization has already been done
INIT_CHECK=$(psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'db_init_status');" | xargs)

if [ "$INIT_CHECK" = "t" ]; then
    INIT_STATUS=$(psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT status FROM db_init_status WHERE id = 1;" | xargs)
    if [ "$INIT_STATUS" = "completed" ]; then
        echo "Database initialization already completed. Skipping..."
        exit 0
    fi
fi

# Create initialization status table
echo "Creating initialization status table..."
psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" <<EOF
CREATE TABLE IF NOT EXISTS db_init_status (
    id INTEGER PRIMARY KEY,
    status VARCHAR(50),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

INSERT INTO db_init_status (id, status, started_at)
VALUES (1, 'in_progress', NOW())
ON CONFLICT (id) DO UPDATE SET status = 'in_progress', started_at = NOW();
EOF

# Download SQL script from S3
echo "Downloading SQL initialization script from S3..."
aws s3 cp "s3://${S3_BUCKET}/${SQL_SCRIPT_KEY}" /tmp/schema.sql

# Execute SQL script
echo "Executing SQL initialization script..."
psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -f /tmp/schema.sql

# Load static data files from S3
echo "Loading static data files from S3..."
aws s3 ls "s3://${S3_BUCKET}/${STATIC_DATA_PREFIX}" | while read -r line; do
    file=$(echo "$line" | awk '{print $4}')
    if [ -n "$file" ]; then
        echo "Processing file: $file"
        aws s3 cp "s3://${S3_BUCKET}/${STATIC_DATA_PREFIX}${file}" /tmp/
        
        # Determine table name from filename (assuming format: tablename.csv)
        table_name=$(basename "$file" .csv)
        
        # Load CSV into database
        psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -c "\COPY ${table_name} FROM '/tmp/${file}' WITH (FORMAT csv, HEADER true);"
        
        rm -f "/tmp/${file}"
    fi
done

# Mark initialization as completed
echo "Marking initialization as completed..."
psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" <<EOF
UPDATE db_init_status
SET status = 'completed', completed_at = NOW()
WHERE id = 1;
EOF

echo "Database initialization completed successfully!"

# Made with Bob
