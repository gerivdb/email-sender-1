-- Migration: Rollback contextual_sessions table creation
-- Description: Drops the contextual_sessions table and related objects
-- Version: 002
-- Author: Contextual Memory Manager
-- Date: 2024

BEGIN;

-- Drop trigger
DROP TRIGGER IF EXISTS update_contextual_sessions_updated_at ON contextual_sessions;

-- Drop indexes
DROP INDEX IF EXISTS idx_contextual_sessions_user_start;
DROP INDEX IF EXISTS idx_contextual_sessions_user_active;
DROP INDEX IF EXISTS idx_contextual_sessions_data;
DROP INDEX IF EXISTS idx_contextual_sessions_end_time;
DROP INDEX IF EXISTS idx_contextual_sessions_start_time;
DROP INDEX IF EXISTS idx_contextual_sessions_is_active;
DROP INDEX IF EXISTS idx_contextual_sessions_user_id;

-- Drop table
DROP TABLE IF EXISTS contextual_sessions;

COMMIT;
