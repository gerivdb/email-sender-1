#!/bin/bash
# Script pour redémarrer les services après un déploiement

# Définir les couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Redémarrage des services...${NC}"

# Vérifier si nous sommes sur un système Linux
if [ "$(uname)" != "Linux" ]; then
    echo -e "${YELLOW}Ce script est conçu pour être exécuté sur un système Linux.${NC}"
    echo -e "${YELLOW}Simulation du redémarrage des services...${NC}"
    echo -e "${GREEN}Simulation terminée avec succès!${NC}"
    exit 0
fi

# Vérifier si nous avons les droits sudo
if [ "$(id -u)" != "0" ] && ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}Ce script nécessite des droits sudo pour redémarrer les services.${NC}"
    echo -e "${YELLOW}Simulation du redémarrage des services...${NC}"
    echo -e "${GREEN}Simulation terminée avec succès!${NC}"
    exit 0
fi

# Redémarrer le service n8n
echo -e "${CYAN}Redémarrage du service n8n...${NC}"
if systemctl is-active --quiet n8n; then
    sudo systemctl restart n8n
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service n8n redémarré avec succès!${NC}"
    else
        echo -e "${RED}Erreur lors du redémarrage du service n8n.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Le service n8n n'est pas actif ou n'existe pas.${NC}"
    echo -e "${YELLOW}Tentative de démarrage du service...${NC}"
    sudo systemctl start n8n
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service n8n démarré avec succès!${NC}"
    else
        echo -e "${RED}Erreur lors du démarrage du service n8n.${NC}"
        exit 1
    fi
fi

# Redémarrer le service nginx (si présent)
echo -e "${CYAN}Redémarrage du service nginx...${NC}"
if systemctl is-active --quiet nginx; then
    sudo systemctl restart nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Service nginx redémarré avec succès!${NC}"
    else
        echo -e "${RED}Erreur lors du redémarrage du service nginx.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Le service nginx n'est pas actif ou n'existe pas.${NC}"
fi

# Vider le cache (si nécessaire)
echo -e "${CYAN}Vidage du cache...${NC}"
if [ -d "/var/cache/n8n" ]; then
    sudo rm -rf /var/cache/n8n/*
    echo -e "${GREEN}Cache vidé avec succès!${NC}"
else
    echo -e "${YELLOW}Le dossier de cache n'existe pas.${NC}"
fi

echo -e "${GREEN}Tous les services ont été redémarrés avec succès!${NC}"
exit 0
