-- 4.4.2.3 Fonctions PL/pgSQL avancées
CREATE OR REPLACE FUNCTION documentation_analytics.count_documents_by_manager(manager_id INT)
RETURNS INTEGER AS $$
DECLARE
    doc_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO doc_count FROM documentation_analytics.documents WHERE manager_id = $1;
    RETURN doc_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION documentation_analytics.latest_document(manager_id INT)
RETURNS TABLE(id INT, title TEXT, created_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT id, title, created_at FROM documentation_analytics.documents
    WHERE manager_id = $1
    ORDER BY created_at DESC LIMIT 1;
END;
$$ LANGUAGE plpgsql;
