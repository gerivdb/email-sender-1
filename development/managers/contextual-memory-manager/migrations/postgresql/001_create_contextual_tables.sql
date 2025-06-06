-- Migration 001: Tables de base pour le système de mémoire contextuelle

-- Table des actions contextuelles
CREATE TABLE IF NOT EXISTS contextual_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type VARCHAR(100) NOT NULL,
    action_text TEXT NOT NULL,
    workspace_path TEXT,
    file_path TEXT,
    line_number INTEGER,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table des embeddings (référence aux vecteurs Qdrant)
CREATE TABLE IF NOT EXISTS contextual_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_id UUID NOT NULL REFERENCES contextual_actions(id) ON DELETE CASCADE,
    qdrant_point_id UUID NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    vector_size INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(action_id, model_name)
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_contextual_actions_type_timestamp ON contextual_actions(action_type, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_workspace ON contextual_actions(workspace_path);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_text_gin ON contextual_actions USING gin(to_tsvector('english', action_text));
CREATE INDEX IF NOT EXISTS idx_contextual_embeddings_action ON contextual_embeddings(action_id);
