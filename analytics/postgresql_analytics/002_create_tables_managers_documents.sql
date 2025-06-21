-- 4.4.2.2 Tables managers et documents
CREATE TABLE IF NOT EXISTS documentation_analytics.managers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS documentation_analytics.documents (
    id SERIAL PRIMARY KEY,
    manager_id INTEGER REFERENCES documentation_analytics.managers(id),
    title TEXT NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
