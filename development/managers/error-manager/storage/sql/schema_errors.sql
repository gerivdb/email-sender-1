-- SQL schema for project_errors table
CREATE TABLE IF NOT EXISTS project_errors (
    id UUID PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT,
    module VARCHAR(255) NOT NULL,
    error_code VARCHAR(100) NOT NULL,
    manager_context JSONB,
    severity VARCHAR(50) NOT NULL
);
