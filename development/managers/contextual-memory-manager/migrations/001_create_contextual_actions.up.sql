-- Migration: Create contextual_actions table
-- Description: Creates the main table for storing contextual actions and their metadata
-- Version: 001
-- Author: Contextual Memory Manager
-- Date: 2024

BEGIN;

-- Create contextual_actions table
CREATE TABLE IF NOT EXISTS contextual_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type VARCHAR(100) NOT NULL,
    context_data JSONB NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}',
    session_id UUID,
    user_id VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_contextual_actions_action_type ON contextual_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_session_id ON contextual_actions(session_id);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_user_id ON contextual_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_timestamp ON contextual_actions(timestamp);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_created_at ON contextual_actions(created_at);

-- Create GIN index for JSONB context_data for efficient querying
CREATE INDEX IF NOT EXISTS idx_contextual_actions_context_data ON contextual_actions USING GIN(context_data);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_metadata ON contextual_actions USING GIN(metadata);

-- Create composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_contextual_actions_user_type_time ON contextual_actions(user_id, action_type, timestamp);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_session_time ON contextual_actions(session_id, timestamp);

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for automatic updated_at updates
CREATE TRIGGER update_contextual_actions_updated_at 
    BEFORE UPDATE ON contextual_actions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

COMMIT;
