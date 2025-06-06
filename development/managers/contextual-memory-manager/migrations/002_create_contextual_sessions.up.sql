-- Migration: Create contextual_sessions table
-- Description: Creates table for tracking user sessions and context
-- Version: 002
-- Author: Contextual Memory Manager
-- Date: 2024

BEGIN;

-- Create contextual_sessions table
CREATE TABLE IF NOT EXISTS contextual_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    session_data JSONB NOT NULL DEFAULT '{}',
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_user_id ON contextual_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_is_active ON contextual_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_start_time ON contextual_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_end_time ON contextual_sessions(end_time);

-- Create GIN index for session_data
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_data ON contextual_sessions USING GIN(session_data);

-- Create composite indexes
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_user_active ON contextual_sessions(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_user_start ON contextual_sessions(user_id, start_time);

-- Create trigger for automatic updated_at updates
CREATE TRIGGER update_contextual_sessions_updated_at 
    BEFORE UPDATE ON contextual_sessions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

COMMIT;
