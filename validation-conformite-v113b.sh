#!/bin/bash
# validation-conformite-v113b.sh

echo "🔍 VALIDATION CONFORMITÉ v113 vs v113b"

PATTERNS_REQUIRED=("Session" "Pipeline" "Batch" "Fallback" "Monitoring" "Audit" "Rollback" "UXMetrics" "ProgressiveSync" "Pooling" "ReportingUI")
SECTIONS_REQUIRED=("Objectif" "Livrables" "Dépendances" "Risques" "Outils/Agents mobilisés" "Tâches actionnables" "Scripts/Commandes" "Fichiers attendus" "Critères de validation" "Rollback" "Orchestration & CI/CD" "Documentation & traçabilité" "Questions ouvertes" "Auto-critique")
ERRORS=0

TARGET_FILE="projet/roadmaps/plans/consolidated/plan-dev-v113b-autmatisation-doc-roo.md"

echo "📋 Vérification des patterns obligatoires..."
for pattern in "${PATTERNS_REQUIRED[@]}"; do
    if ! grep -q "### Pattern.*$pattern" "$TARGET_FILE"; then
        echo "❌ ERREUR: Pattern $pattern manquant dans v113b"
        ((ERRORS++))
    fi
done

echo "📋 Vérification des sections obligatoires par pattern..."
for pattern in "${PATTERNS_REQUIRED[@]}"; do
    for section in "${SECTIONS_REQUIRED[@]}"; do
        if ! grep -A 200 "### Pattern.*$pattern" "$TARGET_FILE" | grep -q "$section"; then
            echo "❌ ERREUR: Section '$section' manquante pour pattern $pattern"
            ((ERRORS++))
        fi
    done
done

echo "📋 Vérification de la granularité (minimum 2000 lignes)..."
LINES=$(wc -l < "$TARGET_FILE")
if [ $LINES -lt 2000 ]; then
    echo "❌ ERREUR: v113b trop court ($LINES lignes). Minimum requis: 2000 lignes"
    ((ERRORS++))
fi

if [ $ERRORS -eq 0 ]; then
    echo "✅ CONFORMITÉ VALIDÉE: v113b conforme à v113"
    exit 0
else
    echo "❌ CONFORMITÉ ÉCHOUÉE: $ERRORS erreurs détectées"
    echo "🚫 BLOCAGE CI/CD ACTIVÉ"
    exit 1
fi
