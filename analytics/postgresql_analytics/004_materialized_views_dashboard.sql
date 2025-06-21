-- 4.4.2.4 Vues matérialisées pour dashboard
CREATE MATERIALIZED VIEW IF NOT EXISTS documentation_analytics.dashboard_manager_stats AS
SELECT 
    m.id AS manager_id,
    m.name AS manager_name,
    COUNT(d.id) AS document_count,
    MAX(d.created_at) AS last_document_created
FROM documentation_analytics.managers m
LEFT JOIN documentation_analytics.documents d ON m.id = d.manager_id
GROUP BY m.id, m.name;
