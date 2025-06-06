-- Migration: Rollback contextual_actions table creation
-- Description: Drops the contextual_actions table and related objects
-- Version: 001
-- Author: Contextual Memory Manager
-- Date: 2024

BEGIN;

-- Drop trigger
DROP TRIGGER IF EXISTS update_contextual_actions_updated_at ON contextual_actions;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS idx_contextual_actions_session_time;
DROP INDEX IF EXISTS idx_contextual_actions_user_type_time;
DROP INDEX IF EXISTS idx_contextual_actions_metadata;
DROP INDEX IF EXISTS idx_contextual_actions_context_data;
DROP INDEX IF EXISTS idx_contextual_actions_created_at;
DROP INDEX IF EXISTS idx_contextual_actions_timestamp;
DROP INDEX IF EXISTS idx_contextual_actions_user_id;
DROP INDEX IF EXISTS idx_contextual_actions_session_id;
DROP INDEX IF EXISTS idx_contextual_actions_action_type;

-- Drop table
DROP TABLE IF EXISTS contextual_actions;

COMMIT;
