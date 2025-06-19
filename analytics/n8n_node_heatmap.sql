-- Action 064 : Heatmap d’utilisation des nodes N8N
-- Requête SQL pour générer une heatmap d’utilisation des nodes par heure et par type
-- Table attendue : n8n_node_executions
-- Colonnes : id, node_type, node_name, workflow_id, executed_at (timestamp), status
SELECT node_type,
   EXTRACT(
      HOUR
      FROM executed_at
   ) AS hour,
   COUNT(*) AS executions,
   SUM(
      CASE
         WHEN status = 'success' THEN 1
         ELSE 0
      END
   ) AS success_count,
   SUM(
      CASE
         WHEN status = 'failed' THEN 1
         ELSE 0
      END
   ) AS failed_count
FROM n8n_node_executions
WHERE executed_at >= NOW() - INTERVAL '7 days'
GROUP BY node_type,
   hour
ORDER BY node_type,
   hour;