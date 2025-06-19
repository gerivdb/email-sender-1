-- Action 065 : Analytics avancé sur les workflows N8N
-- Requête SQL pour obtenir taux de succès, erreurs, temps moyen d’exécution par workflow
-- Table attendue : n8n_workflow_executions
-- Colonnes : id, workflow_id, workflow_name, started_at, finished_at, status ('success'/'failed')
SELECT workflow_id,
   workflow_name,
   COUNT(*) AS total_runs,
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
   ) AS failed_count,
   ROUND(
      100.0 * SUM(
         CASE
            WHEN status = 'success' THEN 1
            ELSE 0
         END
      ) / COUNT(*),
      2
   ) AS success_rate_percent,
   ROUND(
      AVG(
         EXTRACT(
            EPOCH
            FROM finished_at - started_at
         )
      ),
      2
   ) AS avg_duration_sec,
   MAX(
      EXTRACT(
         EPOCH
         FROM finished_at - started_at
      )
   ) AS max_duration_sec,
   MIN(
      EXTRACT(
         EPOCH
         FROM finished_at - started_at
      )
   ) AS min_duration_sec
FROM n8n_workflow_executions
WHERE started_at >= NOW() - INTERVAL '30 days'
GROUP BY workflow_id,
   workflow_name
ORDER BY total_runs DESC,
   success_rate_percent DESC;