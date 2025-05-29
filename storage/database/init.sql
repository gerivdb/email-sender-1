-- Initialize SQLite database with schema for default values optimization

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

-- Core table for storing default values
CREATE TABLE IF NOT EXISTS default_values (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    value_type TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT 1
);

-- Metadata for each default value
CREATE TABLE IF NOT EXISTS value_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value_id INTEGER NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (value_id) REFERENCES default_values(id) ON DELETE CASCADE
);

-- Track usage patterns
CREATE TABLE IF NOT EXISTS usage_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value_id INTEGER NOT NULL,
    access_count INTEGER NOT NULL DEFAULT 0,
    last_accessed TIMESTAMP,
    access_pattern TEXT,  -- JSON string containing pattern data
    FOREIGN KEY (value_id) REFERENCES default_values(id) ON DELETE CASCADE
);

-- Track relationships between values
CREATE TABLE IF NOT EXISTS value_relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id INTEGER NOT NULL,
    target_id INTEGER NOT NULL,
    relationship_type TEXT NOT NULL,
    strength REAL DEFAULT 0.0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (source_id) REFERENCES default_values(id) ON DELETE CASCADE,
    FOREIGN KEY (target_id) REFERENCES default_values(id) ON DELETE CASCADE
);

-- Historical record of value changes
CREATE TABLE IF NOT EXISTS value_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value_id INTEGER NOT NULL,
    old_value TEXT NOT NULL,
    new_value TEXT NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_reason TEXT,
    FOREIGN KEY (value_id) REFERENCES default_values(id) ON DELETE CASCADE
);

-- Validation rules for values
CREATE TABLE IF NOT EXISTS value_validations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value_id INTEGER NOT NULL,
    validation_type TEXT NOT NULL,
    validation_rule TEXT NOT NULL,  -- JSON string containing validation rules
    is_active BOOLEAN NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (value_id) REFERENCES default_values(id) ON DELETE CASCADE
);

-- Create optimized indexes
CREATE INDEX idx_default_values_key ON default_values(key) WHERE is_active = 1;
CREATE INDEX idx_default_values_type ON default_values(value_type) WHERE is_active = 1;
CREATE INDEX idx_value_metadata_value_id ON value_metadata(value_id);
CREATE INDEX idx_value_metadata_key ON value_metadata(key);
CREATE INDEX idx_usage_patterns_value_id ON usage_patterns(value_id);
CREATE INDEX idx_value_relationships_source ON value_relationships(source_id);
CREATE INDEX idx_value_relationships_target ON value_relationships(target_id);
CREATE INDEX idx_value_history_value_id ON value_history(value_id);
CREATE INDEX idx_value_validations_value_id ON value_validations(value_id) WHERE is_active = 1;

-- Create trigger for updating timestamps
CREATE TRIGGER update_default_values_timestamp
AFTER UPDATE ON default_values
BEGIN
    UPDATE default_values 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.id;
END;

-- Create trigger for tracking value history
CREATE TRIGGER track_value_changes
AFTER UPDATE OF value ON default_values
WHEN OLD.value != NEW.value
BEGIN
    INSERT INTO value_history (value_id, old_value, new_value)
    VALUES (NEW.id, OLD.value, NEW.value);
END;

-- Create trigger for initializing usage pattern record
CREATE TRIGGER init_usage_pattern
AFTER INSERT ON default_values
BEGIN
    INSERT INTO usage_patterns (value_id, access_count)
    VALUES (NEW.id, 0);
END;