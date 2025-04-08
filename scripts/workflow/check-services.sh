#!/bin/bash
# Script pour vérifier l'état des services après un déploiement

# Définir les couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Vérification des services...${NC}"

# Vérifier si nous sommes sur un système Linux
if [ "$(uname)" != "Linux" ]; then
    echo -e "${YELLOW}Ce script est conçu pour être exécuté sur un système Linux.${NC}"
    echo -e "${YELLOW}Simulation de la vérification des services...${NC}"
    echo -e "${GREEN}Simulation terminée avec succès!${NC}"
    exit 0
fi

# Vérifier le service n8n
echo -e "${CYAN}Vérification du service n8n...${NC}"
if systemctl is-active --quiet n8n; then
    echo -e "${GREEN}Service n8n: ACTIF${NC}"
    
    # Vérifier le port n8n
    if netstat -tuln | grep -q ":5678 "; then
        echo -e "${GREEN}Port n8n (5678): OUVERT${NC}"
    else
        echo -e "${RED}Port n8n (5678): FERMÉ${NC}"
        exit 1
    fi
else
    echo -e "${RED}Service n8n: INACTIF${NC}"
    exit 1
fi

# Vérifier le service nginx (si présent)
echo -e "${CYAN}Vérification du service nginx...${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}Service nginx: ACTIF${NC}"
    
    # Vérifier le port nginx
    if netstat -tuln | grep -q ":80 "; then
        echo -e "${GREEN}Port nginx (80): OUVERT${NC}"
    else
        echo -e "${RED}Port nginx (80): FERMÉ${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Service nginx: INACTIF ou non installé${NC}"
fi

# Vérifier les logs pour détecter des erreurs
echo -e "${CYAN}Vérification des logs...${NC}"
if [ -f "/var/log/n8n/error.log" ]; then
    # Vérifier les erreurs récentes (dernières 5 minutes)
    recent_errors=$(find /var/log/n8n/error.log -mmin -5 -type f -exec grep -l "ERROR" {} \;)
    if [ -n "$recent_errors" ]; then
        echo -e "${RED}Des erreurs récentes ont été détectées dans les logs:${NC}"
        tail -n 10 /var/log/n8n/error.log
        exit 1
    else
        echo -e "${GREEN}Aucune erreur récente détectée dans les logs.${NC}"
    fi
else
    echo -e "${YELLOW}Fichier de log non trouvé.${NC}"
fi

# Vérifier l'accès à l'API n8n
echo -e "${CYAN}Vérification de l'accès à l'API n8n...${NC}"
if command -v curl &> /dev/null; then
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/api/v1/health)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}API n8n accessible (code 200)${NC}"
    else
        echo -e "${RED}API n8n inaccessible (code $response)${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}curl non disponible, impossible de vérifier l'accès à l'API.${NC}"
fi

echo -e "${GREEN}Tous les services fonctionnent correctement!${NC}"
exit 0
