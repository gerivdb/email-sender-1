-- Test unitaire : insertion et requête sur managers/documents
BEGIN;
INSERT INTO documentation_analytics.managers (name) VALUES ('ManagerTest') RETURNING id;
-- Supposons que l'id retourné est 1
INSERT INTO documentation_analytics.documents (manager_id, title, content) VALUES (1, 'DocTest', 'Contenu test');
SELECT documentation_analytics.count_documents_by_manager(1);
SELECT * FROM documentation_analytics.latest_document(1);
ROLLBACK;
