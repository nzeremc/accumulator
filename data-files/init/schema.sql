-- DOCMP Database Schema Initialization Script
-- This is a sample schema for testing purposes

-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Set search path
SET search_path TO app, public;

-- Users table
CREATE TABLE IF NOT EXISTS app.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON app.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON app.users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON app.users(role);

-- Organizations table
CREATE TABLE IF NOT EXISTS app.organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User-Organization relationship
CREATE TABLE IF NOT EXISTS app.user_organizations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    organization_id INTEGER NOT NULL REFERENCES app.organizations(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, organization_id)
);

CREATE INDEX IF NOT EXISTS idx_user_orgs_user ON app.user_organizations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_orgs_org ON app.user_organizations(organization_id);

-- Documents table
CREATE TABLE IF NOT EXISTS app.documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content TEXT,
    document_type VARCHAR(100),
    status VARCHAR(50) DEFAULT 'draft',
    owner_id INTEGER NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES app.organizations(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_owner ON app.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_org ON app.documents(organization_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON app.documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_type ON app.documents(document_type);

-- Audit log table
CREATE TABLE IF NOT EXISTS app.audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app.users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON app.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON app.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON app.audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON app.audit_logs(created_at);

-- Settings table (key-value store)
CREATE TABLE IF NOT EXISTS app.settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) NOT NULL UNIQUE,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_settings_key ON app.settings(key);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION app.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON app.users
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON app.organizations
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON app.documents
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

CREATE TRIGGER update_settings_updated_at
    BEFORE UPDATE ON app.settings
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

-- Grant permissions (adjust as needed)
GRANT USAGE ON SCHEMA app TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO PUBLIC;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO PUBLIC;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'DOCMP database schema created successfully!';
    RAISE NOTICE 'Schema: app';
    RAISE NOTICE 'Tables: users, organizations, user_organizations, documents, audit_logs, settings';
END $$;

-- Made with Bob
