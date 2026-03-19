#!/bin/bash
set -e

echo "Starting PGActive replication setup..."

# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --query SecretString --output text)
DB_USERNAME=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_SECRET" | jq -r '.password')
DB_HOST_PRIMARY=$(echo "$DB_SECRET" | jq -r '.host_primary')
DB_HOST_SECONDARY=$(echo "$DB_SECRET" | jq -r '.host_secondary')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')

export PGPASSWORD="$DB_PASSWORD"

echo "Checking database connectivity..."

# Check primary database
if ! psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "ERROR: Cannot connect to primary database"
    exit 1
fi

# Check secondary database
if ! psql -h "$DB_HOST_SECONDARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "ERROR: Cannot connect to secondary database"
    exit 1
fi

echo "✅ Both databases are accessible"

# Check if replication is already set up
REPLICATION_CHECK=$(psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = 'pgactive_slot';" | xargs)

if [ "$REPLICATION_CHECK" -gt "0" ]; then
    echo "⚠️  Replication slot already exists. Checking status..."
    SLOT_ACTIVE=$(psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT active FROM pg_replication_slots WHERE slot_name = 'pgactive_slot';" | xargs)
    
    if [ "$SLOT_ACTIVE" = "t" ]; then
        echo "✅ Replication is already active and running"
        exit 0
    else
        echo "⚠️  Replication slot exists but is not active. Recreating..."
        psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -c "SELECT pg_drop_replication_slot('pgactive_slot');"
    fi
fi

echo "Setting up logical replication..."

# Create replication slot on primary
echo "Creating replication slot on primary database..."
psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" <<EOF
-- Create replication slot for logical replication
SELECT pg_create_logical_replication_slot('pgactive_slot', 'pgoutput');
EOF

# Create publication on primary for all tables in docmp schema
echo "Creating publication on primary database..."
psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" <<EOF
-- Drop publication if exists
DROP PUBLICATION IF EXISTS pgactive_pub;

-- Create publication for all tables in docmp schema
CREATE PUBLICATION pgactive_pub FOR ALL TABLES;

-- Verify publication
SELECT * FROM pg_publication WHERE pubname = 'pgactive_pub';
EOF

# Create subscription on secondary
echo "Creating subscription on secondary database..."
psql -h "$DB_HOST_SECONDARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" <<EOF
-- Drop subscription if exists
DROP SUBSCRIPTION IF EXISTS pgactive_sub;

-- Create subscription
CREATE SUBSCRIPTION pgactive_sub
CONNECTION 'host=${DB_HOST_PRIMARY} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USERNAME} password=${DB_PASSWORD}'
PUBLICATION pgactive_pub
WITH (copy_data = true, create_slot = false, slot_name = 'pgactive_slot');

-- Verify subscription
SELECT * FROM pg_subscription WHERE subname = 'pgactive_sub';
EOF

# Verify replication status
echo "Verifying replication status..."

# Check replication slot on primary
SLOT_STATUS=$(psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT slot_name, active, restart_lsn FROM pg_replication_slots WHERE slot_name = 'pgactive_slot';")
echo "Primary replication slot status:"
echo "$SLOT_STATUS"

# Check subscription on secondary
SUB_STATUS=$(psql -h "$DB_HOST_SECONDARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT subname, subenabled, subslotname FROM pg_subscription WHERE subname = 'pgactive_sub';")
echo "Secondary subscription status:"
echo "$SUB_STATUS"

# Check replication lag
echo "Checking replication lag..."
LAG_CHECK=$(psql -h "$DB_HOST_SECONDARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;")
echo "Replication lag: $LAG_CHECK"

# Test replication with a simple insert
echo "Testing replication..."
TEST_TABLE="docmp.replication_test"

# Create test table on primary
psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" <<EOF
CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
    id SERIAL PRIMARY KEY,
    test_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO ${TEST_TABLE} (test_data) VALUES ('Replication test at ' || CURRENT_TIMESTAMP);
EOF

# Wait for replication
sleep 5

# Check if data replicated to secondary
REPLICATED_COUNT=$(psql -h "$DB_HOST_SECONDARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -t -c "SELECT COUNT(*) FROM ${TEST_TABLE};" | xargs)

if [ "$REPLICATED_COUNT" -gt "0" ]; then
    echo "✅ Replication test successful! Data replicated to secondary."
    
    # Clean up test table
    psql -h "$DB_HOST_PRIMARY" -U "$DB_USERNAME" -d "$DB_NAME" -p "$DB_PORT" -c "DROP TABLE IF EXISTS ${TEST_TABLE};"
else
    echo "❌ Replication test failed! Data not found on secondary."
    exit 1
fi

echo "✅ PGActive replication setup completed successfully!"
echo ""
echo "Summary:"
echo "- Primary Database: $DB_HOST_PRIMARY"
echo "- Secondary Database: $DB_HOST_SECONDARY"
echo "- Replication Slot: pgactive_slot"
echo "- Publication: pgactive_pub"
echo "- Subscription: pgactive_sub"
echo "- Status: Active"

