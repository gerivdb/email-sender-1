# Sommaire

- [Démarrage rapide](#démarrage-rapide)
- [Déploiement en un clic de MCP Gateway](#déploiement-en-un-clic-de-mcp-gateway)
- [Configuration du stockage](#configuration-du-stockage)
- [Configuration des notifications](#configuration-des-notifications)
- [Configuration de l’API OpenAI](#configuration-de-lapi-openai)
- [Configuration du super administrateur](#configuration-du-super-administrateur)
- [Configuration JWT](#configuration-jwt)
- [Fichier de configuration mcp-gateway.yaml](#mcp-gatewayyaml)
- [Configuration de base](#configuration-de-base)
- [Configuration du stockage](#configuration-du-stockage-1)
- [Configuration du notificateur](#configuration-du-notificateur)
- [Configuration du stockage des sessions](#configuration-du-stockage-des-sessions)
- [Exemple de configuration complète](#exemple-de-configuration)
- [Détails de configuration](#détails-de-configuration)
  - [Configuration du routeur](#configuration-du-routeur)
  - [Configuration CORS](#configuration-cors)
  - [Configuration du serveur](#configuration-du-serveur)
  - [Configuration d’outils](#configuration-doutils)
- [Assemblage des paramètres de requête](#assemblage-des-paramètres-de-requête)
- [Assemblage des paramètres de réponse](#assemblage-des-paramètres-de-réponse)
- [Stockage de configuration](#stockage-de-configuration)
- [Configuration du proxy de service MCP](#configuration-du-proxy-de-service-mcp)
- [Exemple de configuration de proxy de service MCP](#exemple-de-configuration-de-proxy-de-service-mcp)
- [Guide d’utilisation de Go Template](#guide-dutilisation-de-go-template)
- [Guide de configuration de l’environnement de développement local](#guide-de-configuration-de-lenvironnement-de-développement-local)
- [Problèmes courants](#problèmes-courants)
- [Flux de travail pour contribuer au code](#flux-de-travail-pour-contribuer-au-code)

Démarrage rapide
Déploiement en un clic de MCP Gateway
D'abord, configurez les variables d'environnement nécessaires :

export OPENAI_API_KEY="sk-eed837fb0b4a62ee69abc29a983492b7PlsChangeMe"
export OPENAI_MODEL="gpt-4o-mini"
export APISERVER_JWT_SECRET_KEY="fec6d38f73d4211318e7c85617f0e333PlsChangeMe"
export SUPER_ADMIN_USERNAME="admin"
export SUPER_ADMIN_PASSWORD="297df52fbc321ebf7198d497fe1c9206PlsChangeMe"

Déploiement en un clic :

docker run -d \
  --name mcp-gateway \
  -p 8080:80 \
  -p 5234:5234 \
  -p 5235:5235 \
  -p 5335:5335 \
  -p 5236:5236 \
  -e ENV=production \
  -e TZ=Asia/Shanghai \
  -e OPENAI_API_KEY=${OPENAI_API_KEY} \
  -e OPENAI_MODEL=${OPENAI_MODEL} \
  -e APISERVER_JWT_SECRET_KEY=${APISERVER_JWT_SECRET_KEY} \
  -e SUPER_ADMIN_USERNAME=${SUPER_ADMIN_USERNAME} \
  -e SUPER_ADMIN_PASSWORD=${SUPER_ADMIN_PASSWORD} \
  --restart unless-stopped \
  ghcr.io/mcp-ecosystem/mcp-gateway/allinone:latest

Pour les utilisateurs en Chine continentale, vous pouvez utiliser le registre Alibaba Cloud et personnaliser le modèle (exemple avec Qwen) :

export OPENAI_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1/"
export OPENAI_API_KEY="sk-eed837fb0b4a62ee69abc29a983492b7PlsChangeMe"
export OPENAI_MODEL="qwen-turbo"
export APISERVER_JWT_SECRET_KEY="fec6d38f73d4211318e7c85617f0e333PlsChangeMe"
export SUPER_ADMIN_USERNAME="admin"
export SUPER_ADMIN_PASSWORD="297df52fbc321ebf7198d497fe1c9206PlsChangeMe"

Déploiement en un clic :

docker run -d \
  --name mcp-gateway \
  -p 8080:80 \
  -p 5234:5234 \
  -p 5235:5235 \
  -p 5335:5335 \
  -p 5236:5236 \
  -e ENV=production \
  -e TZ=Asia/Shanghai \
  -e OPENAI_BASE_URL=${OPENAI_BASE_URL} \
  -e OPENAI_API_KEY=${OPENAI_API_KEY} \
  -e OPENAI_MODEL=${OPENAI_MODEL} \
  -e APISERVER_JWT_SECRET_KEY=${APISERVER_JWT_SECRET_KEY} \
  -e SUPER_ADMIN_USERNAME=${SUPER_ADMIN_USERNAME} \
  -e SUPER_ADMIN_PASSWORD=${SUPER_ADMIN_PASSWORD} \
  --restart unless-stopped \
  registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-allinone:latest

Accès et Configuration
Accéder à l'interface Web :

Ouvrez http://localhost:8080/ dans votre navigateur
Connectez-vous avec les identifiants administrateur configurés
Ajouter un nouveau serveur MCP :

Copiez le fichier de configuration : https://github.com/mcp-ecosystem/mcp-gateway/blob/main/configs/mock-server.yaml
Cliquez sur "Add MCP Server" dans l'interface Web
Collez la configuration et enregistrez
Exemple d&#39;ajout de serveur MCP

Points de terminaison disponibles
Une fois configuré, les services seront disponibles aux points de terminaison suivants :

MCP SSE : http://localhost:5235/mcp/user/sse
MCP SSE Message : http://localhost:5235/mcp/user/message
MCP Streamable HTTP : http://localhost:5235/mcp/user/mcp
Configurez le client MCP avec une URL se terminant par /sse ou /mcp pour commencer à utiliser le service.

Test
Vous pouvez tester le service de deux manières :

Utiliser la page MCP Chat dans l'interface Web
Utiliser votre propre client MCP (recommandé)
Configuration avancée (Optionnel)
Si vous avez besoin d'un contrôle plus précis de la configuration, vous pouvez démarrer le service en montant les fichiers de configuration :

Créez les répertoires nécessaires et téléchargez les fichiers de configuration :
mkdir -p mcp-gateway/{configs,data}
cd mcp-gateway/
curl -sL https://raw.githubusercontent.com/mcp-ecosystem/mcp-gateway/refs/heads/main/configs/apiserver.yaml -o configs/apiserver.yaml
curl -sL https://raw.githubusercontent.com/mcp-ecosystem/mcp-gateway/refs/heads/main/configs/mcp-gateway.yaml -o configs/mcp-gateway.yaml
curl -sL https://raw.githubusercontent.com/mcp-ecosystem/mcp-gateway/refs/heads/main/.env.example -o .env.allinone


Exécutez MCP Gateway avec Docker :
docker run -d \
           --name mcp-gateway \
           -p 8080:80 \
           -p 5234:5234 \
           -p 5235:5235 \
           -p 5335:5335 \
           -p 5236:5236 \
           -e ENV=production \
           -v $(pwd)/configs:/app/configs \
           -v $(pwd)/data:/app/data \
           -v $(pwd)/.env.allinone:/app/.env \
           --restart unless-stopped \
           ghcr.io/mcp-ecosystem/mcp-gateway/allinone:latest




           Docker
Aperçu des Images
MCP Gateway propose deux méthodes de déploiement :

Déploiement Tout-en-Un : Tous les services sont regroupés dans un seul conteneur, adapté aux déploiements locaux ou à nœud unique.
Déploiement Multi-Conteneurs : Chaque service est déployé séparément, adapté aux environnements de production ou en cluster.
Registres d'Images
Les images sont publiées dans les registres suivants :

Docker Hub : docker.io/ifuryst/mcp-gateway-*
GitHub Container Registry : ghcr.io/mcp-ecosystem/mcp-gateway/*
Alibaba Cloud Container Registry : registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-*
Le GitHub Container Registry prend en charge les répertoires multi-niveaux pour une organisation plus claire, tandis que Docker Hub et les registres Alibaba Cloud utilisent une nomenclature plate avec des tirets.

Tags d'Images
latest : Dernière version
vX.Y.Z : Version spécifique
⚡ Note : MCP Gateway est en développement rapide ! Il est recommandé d'utiliser des tags de version spécifiques pour des déploiements plus fiables.

Images Disponibles
# Version Tout-en-Un
docker pull docker.io/ifuryst/mcp-gateway-allinone:latest
docker pull ghcr.io/mcp-ecosystem/mcp-gateway/allinone:latest
docker pull registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-allinone:latest

# Serveur API
docker pull docker.io/ifuryst/mcp-gateway-apiserver:latest
docker pull ghcr.io/mcp-ecosystem/mcp-gateway/apiserver:latest
docker pull registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-apiserver:latest

# MCP Gateway
docker pull docker.io/ifuryst/mcp-gateway-mcp-gateway:latest
docker pull ghcr.io/mcp-ecosystem/mcp-gateway/mcp-gateway:latest
docker pull registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-mcp-gateway:latest

# Service Utilisateur Mock
docker pull docker.io/ifuryst/mcp-gateway-mock-server:latest
docker pull ghcr.io/mcp-ecosystem/mcp-gateway/mock-server:latest
docker pull registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-mock-server:latest

# Interface Web
docker pull docker.io/ifuryst/mcp-gateway-web:latest
docker pull ghcr.io/mcp-ecosystem/mcp-gateway/web:latest
docker pull registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-web:latest

Déploiement
Déploiement Tout-en-Un
Le déploiement Tout-en-Un regroupe tous les services dans un seul conteneur, idéal pour les déploiements à nœud unique ou locaux. Il comprend les services suivants :

Serveur API : Backend de gestion (Plan de Contrôle)
MCP Gateway : Service principal gérant le trafic de la passerelle (Plan de Données)
Service Utilisateur Mock : Service utilisateur simulé pour les tests (vous pouvez le remplacer par votre service API existant)
Interface Web : Interface de gestion basée sur le web
Nginx : Proxy inverse pour les services internes
Les processus sont gérés à l'aide de Supervisor, et tous les logs sont envoyés vers stdout.

Ports
8080 : Interface Web
5234 : Serveur API
5235 : MCP Gateway
5335 : MCP Gateway Admin (points de terminaison internes comme le rechargement ; NE PAS exposer en production)
5236 : Service Utilisateur Mock
Persistance des Données
Il est recommandé de monter les répertoires suivants :

/app/configs : Fichiers de configuration
/app/data : Stockage des données
/app/.env : Fichier de variables d'environnement
Exemples de Commandes
Créez les répertoires nécessaires et téléchargez les fichiers de configuration :
mkdir -p mcp-gateway/{configs,data}
cd mcp-gateway/
curl -sL https://raw.githubusercontent.com/mcp-ecosystem/mcp-gateway/refs/heads/main/configs/apiserver.yaml -o configs/apiserver.yaml
curl -sL https://raw.githubusercontent.com/mcp-ecosystem/mcp-gateway/refs/heads/main/configs/mcp-gateway.yaml -o configs/mcp-gateway.yaml
curl -sL https://raw.githubusercontent.com/mcp-ecosystem/mcp-gateway/refs/heads/main/.env.example -o .env.allinone


Vous pouvez remplacer le LLM par défaut si nécessaire (doit être compatible avec OpenAI), par exemple, utiliser Qwen :

OPENAI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1/
OPENAI_API_KEY=sk-yourkeyhere
OPENAI_MODEL=qwen-turbo

Exécutez MCP Gateway avec Docker :
# Utilisation du registre Alibaba Cloud (recommandé pour les serveurs/appareils en Chine)
docker run -d \
           --name mcp-gateway \
           -p 8080:80 \
           -p 5234:5234 \
           -p 5235:5235 \
           -p 5335:5335 \
           -p 5236:5236 \
           -e ENV=production \
           -v $(pwd)/configs:/app/configs \
           -v $(pwd)/data:/app/data \
           -v $(pwd)/.env.allinone:/app/.env \
           --restart unless-stopped \
           registry.ap-southeast-1.aliyuncs.com/mcp-ecosystem/mcp-gateway-allinone:latest

# Utilisation du GitHub Container Registry
docker run -d \
           --name mcp-gateway \
           -p 8080:80 \
           -p 5234:5234 \
           -p 5235:5235 \
           -p 5335:5335 \
           -p 5236:5236 \
           -e ENV=production \
           -v $(pwd)/configs:/app/configs \
           -v $(pwd)/data:/app/data \
           -v $(pwd)/.env.allinone:/app/.env \
           --restart unless-stopped \
           ghcr.io/mcp-ecosystem/mcp-gateway/allinone:latest

Notes
Assurez-vous que les fichiers de configuration et le fichier d'environnement sont correctement configurés.
Il est recommandé d'utiliser un tag de version spécifique au lieu de latest.
Définissez des limites de ressources appropriées pour les déploiements en production.
Assurez-vous que les répertoires montés ont les permissions appropriées.


apiserver.yaml
Le fichier de configuration prend en charge l'injection de variables d'environnement en utilisant la syntaxe ${VAR:default}. Si la variable d'environnement n'est pas définie, la valeur par défaut sera utilisée.

La pratique courante est d'injecter des valeurs via différents fichiers .env, .env.development, .env.prod, ou vous pouvez modifier directement la configuration avec des valeurs fixes.

Configuration de la Base de Données des Messages de Chat
Cette configuration est spécifiquement pour le stockage des messages de chat dans le backend (bien qu'elle puisse partager la même base de données avec les configurations de proxy). Elle correspond aux informations montrées dans l'image ci-dessous :

Sessions et Messages de Chat

Actuellement, 3 types de bases de données sont pris en charge :

SQLite3
PostgreSQL
MySQL
Si vous avez besoin d'ajouter la prise en charge de bases de données supplémentaires, vous pouvez le demander dans la section Issues, ou vous pouvez implémenter l'implémentation correspondante et soumettre une PR :)

database:
  type: "${APISERVER_DB_TYPE:sqlite}"               # Type de base de données (sqlite, postgres, mysql)
  host: "${APISERVER_DB_HOST:localhost}"            # Adresse de l'hôte de la base de données
  port: ${APISERVER_DB_PORT:5432}                   # Port de la base de données
  user: "${APISERVER_DB_USER:postgres}"             # Nom d'utilisateur de la base de données
  password: "${APISERVER_DB_PASSWORD:example}"      # Mot de passe de la base de données
  dbname: "${APISERVER_DB_NAME:./mcp-gateway.db}"   # Nom de la base de données ou chemin du fichier
  sslmode: "${APISERVER_DB_SSL_MODE:disable}"       # Mode SSL pour la connexion à la base de données

Configuration du Stockage du Proxy Gateway
Ceci est utilisé pour stocker les configurations du proxy gateway, spécifiquement les mappages de MCP vers API, comme montré dans l'image ci-dessous :

Configuration du Proxy Gateway

Actuellement, 2 types sont pris en charge :

disk : Les configurations sont stockées sous forme de fichiers sur le disque, chaque configuration dans un fichier séparé, similaire au concept de vhost de nginx, par exemple svc-a.yaml, svc-b.yaml
db : Stockage dans la base de données, chaque configuration est un enregistrement. Actuellement, trois types de bases de données sont pris en charge :
SQLite3
PostgreSQL
MySQL
storage:
  type: "${GATEWAY_STORAGE_TYPE:db}"                    # Type de stockage : db, disk
  
  # Configuration de la base de données (utilisé lorsque type est 'db')
  database:
    type: "${GATEWAY_DB_TYPE:sqlite}"                   # Type de base de données (sqlite, postgres, mysql)
    host: "${GATEWAY_DB_HOST:localhost}"                # Adresse de l'hôte de la base de données
    port: ${GATEWAY_DB_PORT:5432}                       # Port de la base de données
    user: "${GATEWAY_DB_USER:postgres}"                 # Nom d'utilisateur de la base de données
    password: "${GATEWAY_DB_PASSWORD:example}"          # Mot de passe de la base de données
    dbname: "${GATEWAY_DB_NAME:./data/mcp-gateway.db}"  # Nom de la base de données ou chemin du fichier
    sslmode: "${GATEWAY_DB_SSL_MODE:disable}"           # Mode SSL pour la connexion à la base de données
  
  # Configuration du disque (utilisé lorsque type est 'disk')
  disk:
    path: "${GATEWAY_STORAGE_DISK_PATH:}"               # Chemin de stockage des fichiers de données

Configuration des Notifications
Le module de notification est principalement utilisé pour notifier mcp-gateway des mises à jour de configuration et déclencher des rechargements à chaud sans nécessiter le redémarrage du service.

Actuellement, 4 méthodes de notification sont prises en charge :

signal : Notification via des signaux du système d'exploitation, similaire à kill -SIGHUP <pid> ou nginx -s reload. Peut être déclenché via la commande mcp-gateway reload, adapté aux déploiements sur machine unique
api : Notification via un appel API. mcp-gateway écoute sur un port indépendant et effectue des rechargements à chaud lorsqu'il reçoit des requêtes. Peut être déclenché via curl http://localhost:5235/_reload, adapté aux déploiements sur machine unique et en cluster
redis : Notification via la fonctionnalité de publication/abonnement de Redis, adaptée aux déploiements sur machine unique et en cluster
composite : Notification combinée, utilisant plusieurs méthodes. Par défaut, signal et api sont toujours activés et peuvent être combinés avec d'autres méthodes. Adapté aux déploiements sur machine unique et en cluster, et c'est la méthode par défaut recommandée
Rôles de notification :

sender : Rôle d'expéditeur, responsable de l'envoi des notifications. apiserver ne peut utiliser que ce mode
receiver : Rôle de récepteur, responsable de la réception des notifications. mcp-gateway sur machine unique devrait utiliser uniquement ce mode
both : À la fois rôle d'expéditeur et de récepteur. mcp-gateway déployé en cluster peut utiliser ce mode
notifier:
  role: "${APISERVER_NOTIFIER_ROLE:sender}"              # Rôle : sender, receiver, ou both
  type: "${APISERVER_NOTIFIER_TYPE:signal}"              # Type : signal, api, redis, ou composite

  # Configuration du signal (utilisé lorsque type est 'signal')
  signal:
    signal: "${APISERVER_NOTIFIER_SIGNAL:SIGHUP}"                       # Signal à envoyer
    pid: "${APISERVER_NOTIFIER_SIGNAL_PID:/var/run/mcp-gateway.pid}"    # Chemin du fichier PID

  # Configuration de l'API (utilisé lorsque type est 'api')
  api:
    port: ${APISERVER_NOTIFIER_API_PORT:5235}                                           # Port de l'API
    target_url: "${APISERVER_NOTIFIER_API_TARGET_URL:http://localhost:5235/_reload}"    # Point de terminaison de rechargement

  # Configuration de Redis (utilisé lorsque type est 'redis')
  redis:
    addr: "${APISERVER_NOTIFIER_REDIS_ADDR:localhost:6379}"                             # Adresse Redis
    password: "${APISERVER_NOTIFIER_REDIS_PASSWORD:UseStrongPasswordIsAGoodPractice}"   # Mot de passe Redis
    db: ${APISERVER_NOTIFIER_REDIS_DB:0}                                                # Numéro de base de données Redis
    topic: "${APISERVER_NOTIFIER_REDIS_TOPIC:mcp-gateway:reload}"                       # Sujet de publication/abonnement Redis


Configuration de l'API OpenAI
Le bloc de configuration OpenAI définit les paramètres pour l'intégration de l'API OpenAI :

openai:
  api_key: "${OPENAI_API_KEY}"                                  # Clé API OpenAI (requise)
  model: "${OPENAI_MODEL:gpt-4.1}"                              # Modèle à utiliser
  base_url: "${OPENAI_BASE_URL:https://api.openai.com/v1/}"     # URL de base de l'API

Actuellement, seuls les appels LLMs compatibles avec l'API OpenAI sont intégrés

Configuration du Super Administrateur
La configuration du super administrateur est utilisée pour configurer le compte administrateur initial du système. Chaque fois que apiserver démarre, il vérifie s'il existe et le crée automatiquement s'il n'existe pas

super_admin:
  username: "${SUPER_ADMIN_USERNAME:admin}"     # Nom d'utilisateur du super administrateur
  password: "${SUPER_ADMIN_PASSWORD:admin}"     # Mot de passe du super administrateur (à changer en production)


Il est fortement recommandé d'utiliser des mots de passe forts dans les environnements de production ou les réseaux publics !

Configuration JWT
La configuration JWT est utilisée pour configurer les paramètres d'authentification web :

jwt:
  secret_key: "${APISERVER_JWT_SECRET_KEY:Pls-Change-Me!}"  # Clé JWT (à changer en production)
  duration: "${APISERVER_JWT_DURATION:24h}"                  # Durée de validité du token

Il est fortement recommandé d'utiliser des mots de passe forts dans les environnements de production ou les réseaux publics !


mcp-gateway.yaml
Les fichiers de configuration prennent en charge l'injection de variables d'environnement en utilisant la syntaxe ${VAR:default}. Si la variable d'environnement n'est pas définie, la valeur par défaut sera utilisée.

La pratique courante consiste à injecter via différents fichiers .env, .env.development, .env.prod, ou vous pouvez modifier directement la configuration avec une valeur fixe.

Configuration de Base
port: ${MCP_GATEWAY_PORT:5235}                      # Port d'écoute du service
pid: "${MCP_GATEWAY_PID:/var/run/mcp-gateway.pid}"  # Chemin du fichier PID

Le PID ici doit être cohérent avec le PID mentionné ci-dessous

Configuration du Stockage
Le module de configuration du stockage est principalement utilisé pour stocker les informations de configuration du proxy de la passerelle. Actuellement, deux méthodes de stockage sont prises en charge :

disk : Les configurations sont stockées sous forme de fichiers sur le disque, chaque configuration dans un fichier séparé, similaire au concept de vhost de nginx, par exemple svc-a.yaml, svc-b.yaml
db : Stockage en base de données, chaque configuration étant un enregistrement. Actuellement, trois bases de données sont prises en charge :
SQLite3
PostgreSQL
MySQL
storage:
  type: "${GATEWAY_STORAGE_TYPE:db}"                    # Type de stockage : db, disk
  
  # Configuration de la base de données (utilisée lorsque le type est 'db')
  database:
    type: "${GATEWAY_DB_TYPE:sqlite}"                   # Type de base de données (sqlite, postgres, mysql)
    host: "${GATEWAY_DB_HOST:localhost}"                # Adresse de l'hôte de la base de données
    port: ${GATEWAY_DB_PORT:5432}                       # Port de la base de données
    user: "${GATEWAY_DB_USER:postgres}"                 # Nom d'utilisateur de la base de données
    password: "${GATEWAY_DB_PASSWORD:example}"          # Mot de passe de la base de données
    dbname: "${GATEWAY_DB_NAME:./data/mcp-gateway.db}"  # Nom de la base de données ou chemin du fichier
    sslmode: "${GATEWAY_DB_SSL_MODE:disable}"           # Mode SSL de la base de données
  
  # Configuration du disque (utilisée lorsque le type est 'disk')
  disk:
    path: "${GATEWAY_STORAGE_DISK_PATH:}"               # Chemin de stockage des fichiers de données

Configuration du Notificateur
Le module de configuration du notificateur est utilisé pour notifier mcp-gateway des mises à jour de configuration et déclencher un rechargement à chaud sans redémarrer le service.

Actuellement, quatre méthodes de notification sont prises en charge :

signal : Notification via des signaux du système d'exploitation, similaire à kill -SIGHUP <pid> ou nginx -s reload, peut être appelée via la commande mcp-gateway reload, adaptée au déploiement sur une seule machine
api : Notification via des appels API, mcp-gateway écoute sur un port séparé et effectue un rechargement à chaud lors de la réception des requêtes, peut être appelée directement via curl http://localhost:5235/_reload, adaptée au déploiement sur une seule machine et en cluster
redis : Notification via la fonctionnalité pub/sub de Redis, adaptée au déploiement sur une seule machine et en cluster
composite : Notification combinée, utilisant plusieurs méthodes, avec signal et api activés par défaut, peut être combinée avec d'autres méthodes. Adaptée au déploiement sur une seule machine et en cluster, recommandée comme méthode par défaut
Rôles de notification :

sender : Expéditeur, responsable de l'envoi des notifications, apiserver ne peut utiliser que ce mode
receiver : Récepteur, responsable de la réception des notifications, il est recommandé que mcp-gateway sur une seule machine n'utilise que ce mode
both : À la fois expéditeur et récepteur, mcp-gateway déployé en cluster peut utiliser ce mode
notifier:
  role: "${NOTIFIER_ROLE:receiver}" # Rôle : 'sender' ou 'receiver'
  type: "${NOTIFIER_TYPE:signal}"   # Type : 'signal', 'api', 'redis', ou 'composite'

  # Configuration du signal (utilisée lorsque le type est 'signal')
  signal:
    signal: "${NOTIFIER_SIGNAL:SIGHUP}"                     # Signal à envoyer
    pid: "${NOTIFIER_SIGNAL_PID:/var/run/mcp-gateway.pid}"  # Chemin du fichier PID

  # Configuration de l'API (utilisée lorsque le type est 'api')
  api:
    port: ${NOTIFIER_API_PORT:5235}                                         # Port de l'API
    target_url: "${NOTIFIER_API_TARGET_URL:http://localhost:5235/_reload}"  # Point de terminaison de rechargement

  # Configuration de Redis (utilisée lorsque le type est 'redis')
  redis:
    addr: "${NOTIFIER_REDIS_ADDR:localhost:6379}"                               # Adresse Redis
    password: "${NOTIFIER_REDIS_PASSWORD:UseStrongPasswordIsAGoodPractice}"     # Mot de passe Redis
    db: ${NOTIFIER_REDIS_DB:0}                                                  # Numéro de la base de données Redis
    topic: "${NOTIFIER_REDIS_TOPIC:mcp-gateway:reload}"                         # Sujet pub/sub Redis


Configuration du Stockage des Sessions
La configuration du stockage des sessions est utilisée pour stocker les informations de session MCP. Actuellement, deux méthodes de stockage sont prises en charge :

memory : Stockage en mémoire, adapté au déploiement sur une seule machine (note : les informations de session seront perdues au redémarrage)
redis : Stockage Redis, adapté au déploiement sur une seule machine et en cluster
session:
  type: "${SESSION_STORAGE_TYPE:memory}"                    # Type de stockage : memory, redis
  redis:
    addr: "${SESSION_REDIS_ADDR:localhost:6379}"            # Adresse Redis
    password: "${SESSION_REDIS_PASSWORD:}"                  # Mot de passe Redis
    db: ${SESSION_REDIS_DB:0}                               # Numéro de la base de données Redis
    topic: "${SESSION_REDIS_TOPIC:mcp-gateway:session}"     # Sujet pub/sub Redis



    Configuration du Service de Passerelle
Exemple de Configuration
Voici un exemple complet de configuration, incluant le routage, CORS, le traitement des réponses et d'autres paramètres :

name: "mock-server"             # Nom du service proxy, unique globalement

# Configuration du Routeur
routers:
  - server: "mock-server"       # Nom du service
    prefix: "/mcp/user"         # Préfixe de route, unique globalement, ne peut pas être répété, recommandé de distinguer par service ou domaine+module

    # Configuration CORS
    cors:
      allowOrigins:             # Pour les environnements de développement et de test, tout peut être ouvert ; pour la production, il est préférable d'ouvrir selon les besoins. (La plupart des Clients MCP n'ont pas besoin de CORS)
        - "*"
      allowMethods:             # Méthodes de requête autorisées, à ouvrir selon les besoins. Pour MCP (SSE et Streamable), généralement seules ces 3 méthodes sont nécessaires
        - "GET"
        - "POST"
        - "OPTIONS"
      allowHeaders:
        - "Content-Type"        # Doit être autorisé
        - "Authorization"       # Besoin de supporter cette clé dans la requête pour les besoins d'authentification
        - "Mcp-Session-Id"      # Pour MCP, il est nécessaire de supporter cette clé dans la requête, sinon Streamable HTTP ne peut pas être utilisé normalement
      exposeHeaders:
        - "Mcp-Session-Id"      # Pour MCP, cette clé doit être exposée lorsque CORS est activé, sinon Streamable HTTP ne peut pas être utilisé normalement
      allowCredentials: true    # Si l'en-tête Access-Control-Allow-Credentials: true doit être ajouté

# Configuration du Serveur
servers:
  - name: "mock-server"               # Nom du service, doit être cohérent avec le serveur dans routers
    namespace: "user-service"         # Espace de noms du service, utilisé pour le regroupement des services
    description: "Mock User Service"  # Description du service
    allowedTools:                     # Liste des outils autorisés (sous-ensemble d'outils)
      - "register_user"
      - "get_user_by_email"
      - "update_user_preferences"
    config:                                           # Configuration au niveau du service, peut être référencée dans les outils via {{.Config}}
      Cookie: 123                                     # Configuration codée en dur
      Authorization: 'Bearer {{ env "AUTH_TOKEN" }}'  # Configuration à partir des variables d'environnement, usage : '{{ env "ENV_VAR_NAME" }}'

# Configuration d'Outils
tools:
  - name: "register_user"                                   # Nom de l'outil
    description: "Register a new user"                      # Description de l'outil
    method: "POST"                                          # Méthode HTTP pour le service cible (amont, backend)
    endpoint: "http://localhost:5236/users"                 # Adresse du service cible
    headers:                                                # Configuration d'en-tête de requête, utilisée pour les en-têtes transportés lors de la demande au service cible
      Content-Type: "application/json"                      # En-tête de requête codé en dur
      Authorization: "{{.Request.Headers.Authorization}}"   # Utilisation de l'en-tête Authorization extrait de la requête client (pour les scénarios de transfert)
      Cookie: "{{.Config.Cookie}}"                          # Utilisation de la valeur de la configuration du service
    args:                         # Configuration des paramètres
      - name: "username"          # Nom du paramètre
        position: "body"          # Position du paramètre : header, query, path, body, form-data
        required: true            # Si le paramètre est requis
        type: "string"            # Type de paramètre
        description: "Username"   # Description du paramètre
        default: ""               # Valeur par défaut
      - name: "email"
        position: "body"
        required: true
        type: "string"
        description: "Email"
        default: ""
    requestBody: |-                       # Modèle de corps de requête, utilisé pour générer dynamiquement le corps de la requête, ex: valeurs extraites des paramètres (arguments de requête MCP)
      {
        "username": "{{.Args.username}}",
        "email": "{{.Args.email}}"
      }
    responseBody: |-                      # Modèle de corps de réponse, utilisé pour générer dynamiquement le corps de la réponse, ex: valeurs extraites de la réponse
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}"
      }

  - name: "get_user_by_email"
    description: "Get user by email"
    method: "GET"
    endpoint: "http://localhost:5236/users/email/{{.Args.email}}"
    args:
      - name: "email"
        position: "path"
        required: true
        type: "string"
        description: "Email"
        default: ""
    responseBody: |-
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}"
      }

  - name: "update_user_preferences"
    description: "Update user preferences"
    method: "PUT"
    endpoint: "http://localhost:5236/users/{{.Args.email}}/preferences"
    headers:
      Content-Type: "application/json"
      Authorization: "{{.Request.Headers.Authorization}}"
      Cookie: "{{.Config.Cookie}}"
    args:
      - name: "email"
        position: "path"
        required: true
        type: "string"
        description: "Email"
        default: ""
      - name: "isPublic"
        position: "body"
        required: true
        type: "boolean"
        description: "Whether the user profile is public"
        default: "false"
      - name: "showEmail"
        position: "body"
        required: true
        type: "boolean"
        description: "Whether to show email in profile"
        default: "true"
      - name: "theme"
        position: "body"
        required: true
        type: "string"
        description: "User interface theme"
        default: "light"
      - name: "tags"
        position: "body"
        required: true
        type: "array"
        items:
           type: "string"
           enum: ["developer", "designer", "manager", "tester"]
        description: "User role tags"
        default: "[]"
    requestBody: |-
      {
        "isPublic": {{.Args.isPublic}},
        "showEmail": {{.Args.showEmail}},
        "theme": "{{.Args.theme}}",
        "tags": {{.Args.tags}}
      }
    responseBody: |-
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}",
        "preferences": {
          "isPublic": {{.Response.Data.preferences.isPublic}},
          "showEmail": {{.Response.Data.preferences.showEmail}},
          "theme": "{{.Response.Data.preferences.theme}}",
          "tags": {{.Response.Data.preferences.tags}}
        }
      }

  - name: "update_user_avatar"
    description: "Update user avatar using a URL via multipart form"
    method: "POST"
    endpoint: "http://localhost:5236/users/{{.Args.email}}/avatar"
    headers:
      Authorization: "{{.Request.Headers.Authorization}}"
      Cookie: "{{.Config.Cookie}}"
    args:
      - name: "email"
        position: "path"
        required: true
        type: "string"
        description: "Email of the user"
        default: ""
      - name: "url"
        position: "form-data"
        required: true
        type: "string"
        description: "The avatar image URL"
        default: ""
    responseBody: |-
      {
        "message": "{{.Response.Data.message}}",
        "avatarUrl": "{{.Response.Data.avatarUrl}}"
      }


Détails de Configuration
1. Configuration de Base
name : Nom du service proxy, unique globalement, utilisé pour identifier différents services proxy
routers : Liste de configuration de routeur, définit les règles de transfert de requêtes
servers : Liste de configuration de serveur, définit les métadonnées de service et les outils autorisés
tools : Liste de configuration d'outils, définit des règles d'appel API spécifiques
Vous pouvez traiter une configuration comme un espace de noms, recommandé pour distinguer par service ou domaine. Un service contient de nombreuses interfaces API, chaque interface API correspond à un outil.

2. Configuration du Routeur
La configuration du routeur est utilisée pour définir les règles de transfert de requêtes :

routers:
  - server: "mock-server"       # Nom du service, doit être cohérent avec le nom dans servers
    prefix: "/mcp/user"         # Préfixe de route, unique globalement, ne peut pas être répété

Par défaut, trois points d'accès sont dérivés du prefix :

SSE : ${prefix}/sse, ex : /mcp/user/sse
SSE : ${prefix}/message, ex : /mcp/user/message
StreamableHTTP : ${prefix}/mcp, ex : /mcp/user/mcp
3. Configuration CORS
La configuration Cross-Origin Resource Sharing (CORS) est utilisée pour contrôler l'accès aux requêtes cross-origin :

cors:
  allowOrigins:             # Pour les environnements de développement et de test, tout peut être ouvert ; pour la production, il est préférable d'ouvrir selon les besoins. (La plupart des Clients MCP n'ont pas besoin de CORS)
    - "*"
  allowMethods:             # Méthodes de requête autorisées, à ouvrir selon les besoins. Pour MCP (SSE et Streamable), généralement seules ces 3 méthodes sont nécessaires
    - "GET"
    - "POST"
    - "OPTIONS"
  allowHeaders:
    - "Content-Type"        # Doit être autorisé
    - "Authorization"       # Besoin de supporter cette clé dans la requête pour les besoins d'authentification
    - "Mcp-Session-Id"      # Pour MCP, il est nécessaire de supporter cette clé dans la requête, sinon Streamable HTTP ne peut pas être utilisé normalement
  exposeHeaders:
    - "Mcp-Session-Id"      # Pour MCP, cette clé doit être exposée lorsque CORS est activé, sinon Streamable HTTP ne peut pas être utilisé normalement
  allowCredentials: true    # Si l'en-tête Access-Control-Allow-Credentials: true doit être ajouté


Dans la plupart des cas, le Client MCP n'a pas besoin de CORS

4. Configuration du Serveur
La configuration du serveur est utilisée pour définir les métadonnées du service, la liste des outils associés et la configuration au niveau du service :

servers:
  - name: "mock-server"               # Nom du service, doit être cohérent avec le serveur dans routers
    namespace: "user-service"         # Espace de noms du service, utilisé pour le regroupement des services
    description: "Mock User Service"  # Description du service
    allowedTools:                     # Liste des outils autorisés (sous-ensemble d'outils)
      - "register_user"
      - "get_user_by_email"
      - "update_user_preferences"
    config:                                           # Configuration au niveau du service, peut être référencée dans les outils via {{.Config}}
      Cookie: 123                                     # Configuration codée en dur
      Authorization: 'Bearer {{ env "AUTH_TOKEN" }}'  # Configuration à partir des variables d'environnement, usage : '{{ env "ENV_VAR_NAME" }}'


La configuration au niveau du service peut être référencée dans les outils via {{.Config}}. Cela peut être codé en dur dans le fichier de configuration ou obtenu à partir de variables d'environnement. Lors de l'injection via des variables d'environnement, il doit être référencé via {{ env "ENV_VAR_NAME" }}.

5. Configuration d'Outils
La configuration d'outils est utilisée pour définir des règles d'appel API spécifiques :

tools:
  - name: "register_user"                                   # Nom de l'outil
    description: "Register a new user"                      # Description de l'outil
    method: "POST"                                          # Méthode HTTP pour le service cible (amont, backend)
    endpoint: "http://localhost:5236/users"                 # Adresse du service cible
    headers:                                                # Configuration d'en-tête de requête, utilisée pour les en-têtes transportés lors de la demande au service cible
      Content-Type: "application/json"                      # En-tête de requête codé en dur
      Authorization: "{{.Request.Headers.Authorization}}"   # Utilisation de l'en-tête Authorization extrait de la requête client (pour les scénarios de transfert)
      Cookie: "{{.Config.Cookie}}"                          # Utilisation de la valeur de la configuration du service
    args:                         # Configuration des paramètres
      - name: "username"          # Nom du paramètre
        position: "body"          # Position du paramètre : header, query, path, body, form-data
        required: true            # Si le paramètre est requis
        type: "string"            # Type de paramètre
        description: "Username"   # Description du paramètre
        default: ""               # Valeur par défaut
      - name: "email"
        position: "body"
        required: true
        type: "string"
        description: "Email"
        default: ""
    requestBody: |-                       # Modèle de corps de requête, utilisé pour générer dynamiquement le corps de la requête, ex: valeurs extraites des paramètres (arguments de requête MCP)
      {
        "username": "{{.Args.username}}",
        "email": "{{.Args.email}}"
      }
    responseBody: |-                      # Modèle de corps de réponse, utilisé pour générer dynamiquement le corps de la réponse, ex: valeurs extraites de la réponse
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}"
      }

  - name: "get_user_by_email"
    description: "Get user by email"
    method: "GET"
    endpoint: "http://localhost:5236/users/email/{{.Args.email}}"
    args:
      - name: "email"
        position: "path"
        required: true
        type: "string"
        description: "Email"
        default: ""
    responseBody: |-
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}"
      }

  - name: "update_user_preferences"
    description: "Update user preferences"
    method: "PUT"
    endpoint: "http://localhost:5236/users/{{.Args.email}}/preferences"
    headers:
      Content-Type: "application/json"
      Authorization: "{{.Request.Headers.Authorization}}"
      Cookie: "{{.Config.Cookie}}"
    args:
      - name: "email"
        position: "path"
        required: true
        type: "string"
        description: "Email"
        default: ""
      - name: "isPublic"
        position: "body"
        required: true
        type: "boolean"
        description: "Whether the user profile is public"
        default: "false"
      - name: "showEmail"
        position: "body"
        required: true
        type: "boolean"
        description: "Whether to show email in profile"
        default: "true"
      - name: "theme"
        position: "body"
        required: true
        type: "string"
        description: "User interface theme"
        default: "light"
      - name: "tags"
        position: "body"
        required: true
        type: "array"
        items:
           type: "string"
           enum: ["developer", "designer", "manager", "tester"]
        description: "User role tags"
        default: "[]"
    requestBody: |-
      {
        "isPublic": {{.Args.isPublic}},
        "showEmail": {{.Args.showEmail}},
        "theme": "{{.Args.theme}}",
        "tags": {{.Args.tags}}
      }
    responseBody: |-
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}",
        "preferences": {
          "isPublic": {{.Response.Data.preferences.isPublic}},
          "showEmail": {{.Response.Data.preferences.showEmail}},
          "theme": "{{.Response.Data.preferences.theme}}",
          "tags": {{.Response.Data.preferences.tags}}
        }
      }

  - name: "update_user_avatar"
    description: "Update user avatar using a URL via multipart form"
    method: "POST"
    endpoint: "http://localhost:5236/users/{{.Args.email}}/avatar"
    headers:
      Authorization: "{{.Request.Headers.Authorization}}"
      Cookie: "{{.Config.Cookie}}"
    args:
      - name: "email"
        position: "path"
        required: true
        type: "string"
        description: "Email of the user"
        default: ""
      - name: "url"
        position: "form-data"
        required: true
        type: "string"
        description: "The avatar image URL"
        default: ""
    responseBody: |-
      {
        "message": "{{.Response.Data.message}}",
        "avatarUrl": "{{.Response.Data.avatarUrl}}"
      }


5.1 Assemblage des Paramètres de Requête
Lors de la demande au service cible, il existe plusieurs sources pour l'assemblage des paramètres :

.Config : Extraire des valeurs de la configuration au niveau du service
.Args : Extraire des valeurs directement à partir des paramètres de requête
.Request : Extraire des valeurs de la requête, y compris les en-têtes de requête .Request.Headers, le corps de la requête .Request.Body, etc.
Les positions de paramètres (position) prennent en charge les types suivants :

header : Le paramètre sera placé dans l'en-tête de la requête
query : Le paramètre sera placé dans la chaîne de requête URL
path : Le paramètre sera placé dans le chemin URL
body : Le paramètre sera placé dans le corps de la requête au format JSON
form-data : Le paramètre sera placé dans le corps de la requête au format multipart/form-data, utilisé pour les téléchargements de fichiers et autres scénarios
Chaque paramètre peut avoir une valeur par défaut. Lorsqu'un paramètre n'est pas fourni dans la requête MCP, la valeur par défaut sera automatiquement utilisée. Même si la valeur par défaut est une chaîne vide (""), elle sera utilisée. Par exemple:

args:
  - name: "theme"
    position: "body"
    required: true
    type: "string"
    description: "User interface theme"
    default: "light"    # Lorsque le paramètre theme n'est pas fourni dans la requête, "light" sera utilisé comme valeur par défaut


Lorsque vous utilisez form-data comme position de paramètre, vous n'avez pas besoin de spécifier requestBody, le système assemblera automatiquement les paramètres au format multipart/form-data. Par exemple:

  - name: "update_user_avatar"
    method: "POST"
    endpoint: "http://localhost:5236/users/{{.Args.email}}/avatar"
    args:
      - name: "url"
        position: "form-data"
        required: true
        type: "string"
        description: "The avatar image URL"

Pour les corps de requête au format JSON, ils doivent être assemblés dans requestBody, par exemple :

    requestBody: |-
      {
        "isPublic": {{.Args.isPublic}},
        "showEmail": {{.Args.showEmail}},
        "theme": "{{.Args.theme}}",
        "tags": {{.Args.tags}}
      }

Le endpoint (adresse cible) peut également utiliser les sources ci-dessus pour extraire des valeurs, par exemple http://localhost:5236/users/{{.Args.email}}/preferences extrait des valeurs des paramètres de requête.

5.2 Assemblage des Paramètres de Réponse
L'assemblage du corps de réponse est similaire à l'assemblage du corps de requête :

.Response.Data : Extraire des valeurs de la réponse, la réponse doit être au format JSON pour extraire
.Response.Body : Transférer directement l'ensemble du corps de réponse, en ignorant le format du contenu de la réponse et en le transmettant directement au client
Les deux utilisent .Response pour extraire des valeurs, par exemple :

    responseBody: |-
      {
        "id": "{{.Response.Data.id}}",
        "username": "{{.Response.Data.username}}",
        "email": "{{.Response.Data.email}}",
        "createdAt": "{{.Response.Data.createdAt}}"
      }

Stockage de Configuration
La configuration du proxy de passerelle peut être stockée de deux manières suivantes :

Stockage en base de données (recommandé) :

Prend en charge SQLite3, PostgreSQL, MySQL
Chaque configuration est stockée comme un enregistrement
Prend en charge les mises à jour dynamiques et le rechargement à chaud
Stockage de fichiers :

Chaque configuration est stockée séparément en tant que fichier YAML
Similaire à la configuration vhost de Nginx
Le nom de fichier est recommandé d'utiliser le nom du service, tel que mock-server.yaml
Configuration du Proxy de Service MCP
En plus de proxifier les services HTTP, MCP Gateway prend également en charge la proxification des services MCP, prenant actuellement en charge trois protocoles de transport : stdio, SSE et streamable-http.

Exemple de Configuration
Voici un exemple complet de configuration de proxy de service MCP :

name: "proxy-mcp-exp"
tenant: "default"

routers:
  - server: "amap-maps"
    prefix: "/mcp/stdio-proxy"
    cors:
      allowOrigins:
        - "*"
      allowMethods:
        - "GET"
        - "POST"
        - "OPTIONS"
      allowHeaders:
        - "Content-Type"
        - "Authorization"
        - "Mcp-Session-Id"
      exposeHeaders:
        - "Mcp-Session-Id"
      allowCredentials: true
  - server: "mock-user-sse"
    prefix: "/mcp/sse-proxy"
    cors:
      allowOrigins:
        - "*"
      allowMethods:
        - "GET"
        - "POST"
        - "OPTIONS"
      allowHeaders:
        - "Content-Type"
        - "Authorization"
        - "Mcp-Session-Id"
      exposeHeaders:
        - "Mcp-Session-Id"
      allowCredentials: true
  - server: "mock-user-mcp"
    prefix: "/mcp/streamable-http-proxy"
    cors:
      allowOrigins:
        - "*"
      allowMethods:
        - "GET"
        - "POST"
        - "OPTIONS"
      allowHeaders:
        - "Content-Type"
        - "Authorization"
        - "Mcp-Session-Id"
      exposeHeaders:
        - "Mcp-Session-Id"
      allowCredentials: true

mcpServers:
  - type: "stdio"
    name: "amap-maps"
    command: "npx"
    args:
      - "-y"
      - "@amap/amap-maps-mcp-server"
    env:
      AMAP_MAPS_API_KEY: "{{.Request.Headers.Apikey}}"

  - type: "sse"
    name: "mock-user-sse"
    url: "http://localhost:3000/mcp/user/sse"

  - type: "streamable-http"
    name: "mock-user-mcp"
    url: "http://localhost:3000/mcp/user/mcp"

Détails de Configuration
1. Types de Services MCP
MCP Gateway prend en charge les trois types suivants de proxys de service MCP :

Type stdio :

Communique avec le processus de service MCP via l'entrée et la sortie standard
Convient aux services MCP qui doivent être démarrés localement, tels que les SDK tiers
Les paramètres de configuration incluent command, args et env
Type SSE :

Transfère les requêtes client MCP vers des services en amont qui prennent en charge SSE
Convient aux services MCP existants qui prennent en charge le protocole SSE
Nécessite uniquement le paramètre url pointant vers l'adresse du service SSE en amont
Type streamable-http :

Transfère les requêtes client MCP vers des services en amont qui prennent en charge HTTP diffusable
Convient aux services en amont existants qui prennent en charge le protocole MCP
Nécessite uniquement le paramètre url pointant vers l'adresse du service MCP en amont
2. Configuration de Type stdio
Exemple de configuration pour le service MCP de type stdio :

mcpServers:
  - type: "stdio"
    name: "amap-maps"                                   # Nom du service
    command: "npx"                                      # Commande à exécuter
    args:                                               # Arguments de commande
      - "-y"
      - "@amap/amap-maps-mcp-server"
    env:                                                # Variables d'environnement
      AMAP_MAPS_API_KEY: "{{.Request.Headers.Apikey}}"  # Extraire la valeur de l'en-tête de requête

Les variables d'environnement peuvent être définies via le champ env, et les valeurs peuvent être extraites de la requête, par exemple {{.Request.Headers.Apikey}} extrait la valeur de Apikey de l'en-tête de requête.

3. Configuration de Type SSE
Exemple de configuration pour le service MCP de type SSE :

mcpServers:
  - type: "sse"
    name: "mock-user-sse"                       # Nom du service
    url: "http://localhost:3000/mcp/user/sse"   # Adresse du service SSE en amont, se terminant généralement par /sse, selon le service en amont


4. Configuration de Type streamable-http
Exemple de configuration pour le service MCP de type streamable-http :

mcpServers:
  - type: "streamable-http"
    name: "mock-user-mcp"                       # Nom du service
    url: "http://localhost:3000/mcp/user/mcp"   # Adresse du service MCP en amont, se terminant généralement par /mcp, selon le service en amont


5. Configuration du Routeur
Pour les proxys de service MCP, la configuration du routeur est similaire aux proxys de service HTTP, avec CORS configuré selon les besoins réels (généralement CORS n'est pas activé dans les environnements de production) :

routers:
  - server: "amap-maps"           # Nom du service, doit être cohérent avec le nom dans mcpServers
    prefix: "/mcp/stdio-proxy"    # Préfixe de route, unique globalement
    cors:
      allowOrigins:
        - "*"
      allowMethods:
        - "GET"
        - "POST"
        - "OPTIONS"
      allowHeaders:
        - "Content-Type"
        - "Authorization"
        - "Mcp-Session-Id"        # Le service MCP doit inclure cet en-tête
      exposeHeaders:
        - "Mcp-Session-Id"        # Le service MCP doit exposer cet en-tête
      allowCredentials: true

Pour les services MCP, Mcp-Session-Id dans les en-têtes de requête et de réponse doit être pris en charge, sinon le client ne peut pas l'utiliser normalement.



Guide d'utilisation de Go Template
Ce document présente comment utiliser Go Template dans MCP Gateway pour gérer les données de requête et de réponse. Go Template offre des capacités de modélisation puissantes qui nous aident à traiter de manière flexible la transformation et le formatage des données.

Syntaxe de base
Go Template utilise {{}} comme délimiteurs, dans lesquels diverses fonctions et variables peuvent être utilisées. Dans MCP Gateway, nous utilisons principalement les variables suivantes :

.Config: Configuration au niveau du service
.Args: Paramètres de requête
.Request: Informations de requête originales
.Response: Informations de réponse du service en amont
Cas d'utilisation courants
1. Obtention de la configuration depuis les variables d'environnement
config:
  Authorization: 'Bearer {{ env "AUTH_TOKEN" }}'  # Obtenir la configuration depuis la variable d'environnement


2. Extraction des valeurs depuis les en-têtes de requête
headers:
  Authorization: "{{.Request.Headers.Authorization}}"   # Transmettre l'en-tête Authorization du client
  Cookie: "{{.Config.Cookie}}"                         # Utiliser la valeur de la configuration du service

3. Construction du corps de la requête
requestBody: |-
  {
    "username": "{{.Args.username}}",
    "email": "{{.Args.email}}"
  }

4. Traitement des données de réponse
responseBody: |-
  {
    "id": "{{.Response.Data.id}}",
    "username": "{{.Response.Data.username}}",
    "email": "{{.Response.Data.email}}",
    "createdAt": "{{.Response.Data.createdAt}}"
  }

5. Traitement des données de réponse imbriquées
responseBody: |-
  {
    "id": "{{.Response.Data.id}}",
    "username": "{{.Response.Data.username}}",
    "email": "{{.Response.Data.email}}",
    "createdAt": "{{.Response.Data.createdAt}}",
    "preferences": {
      "isPublic": {{.Response.Data.preferences.isPublic}},
      "showEmail": {{.Response.Data.preferences.showEmail}},
      "theme": "{{.Response.Data.preferences.theme}}",
      "tags": {{.Response.Data.preferences.tags}}
    }
  }

6. Traitement des données de tableau
Lors du traitement des données de tableau dans les réponses, vous pouvez utiliser la fonctionnalité range de Go Template :

responseBody: |-
  {
    "total": "{{.Response.Data.total}}",
    "rows": [
      {{- $len := len .Response.Data.rows -}}
      {{- $rows := fromJSON .Response.Data.rows }}
      {{- range $i, $e := $rows }}
      {
        "id": {{ $e.id }},
        "detail": "{{ $e.detail }}",
        "deviceName": "{{ $e.deviceName }}"
      }{{ if lt (add $i 1) $len }},{{ end }}
      {{- end }}
    ]
  }

Cet exemple démontre :

L'utilisation de la fonction fromJSON pour convertir une chaîne JSON en objet traversable
L'utilisation de range pour itérer sur le tableau
L'utilisation de la fonction len pour obtenir la longueur du tableau
L'utilisation de la fonction add pour les opérations mathématiques
L'utilisation d'instructions conditionnelles pour contrôler la séparation par virgule entre les éléments du tableau
7. Utilisation des paramètres dans les URLs
endpoint: "http://localhost:5236/users/{{.Args.email}}/preferences"

8. Traitement des données d'objets complexes
Lorsque vous devez convertir des structures complexes comme des objets ou des tableaux dans les requêtes ou les réponses en JSON, vous pouvez utiliser la fonction toJSON :

requestBody: |-
  {
    "isPublic": {{.Args.isPublic}},
    "showEmail": {{.Args.showEmail}},
    "theme": "{{.Args.theme}}",
    "tags": {{.Args.tags}},
    "settings": {{ toJSON .Args.settings }}
  }

Dans ce cas, settings est un objet complexe qui sera automatiquement converti en chaîne JSON à l'aide de la fonction toJSON.

Fonctions intégrées
Fonctions intégrées actuellement supportées :

env: Obtenir la valeur d'une variable d'environnement

Authorization: 'Bearer {{ env "AUTH_TOKEN" }}'

add: Effectuer une addition d'entiers

{{ if lt (add $i 1) $len }},{{ end }}

fromJSON: Convertir une chaîne JSON en objet traversable

{{- $rows := fromJSON .Response.Data.rows }}

toJSON: Convertir un objet en chaîne JSON

"settings": {{ toJSON .Args.settings }}

Pour ajouter de nouvelles fonctions de template :

Décrire le cas d'utilisation spécifique et créer un issue
Les contributions PR sont les bienvenues, mais seules les fonctions à usage général sont actuellement acceptées
Ressources supplémentaires
Documentation officielle de Go Template

Guide Simple pour Configurer MCP dans Cursor
Pour un tutoriel plus détaillé sur la configuration MCP de Cursor, veuillez consulter la documentation officielle :
https://docs.cursor.com/context/model-context-protocol

Je vais vous montrer une méthode de configuration de base. Assurez-vous d'avoir créé les répertoires et fichiers nécessaires :

mkdir -p .cursor
touch .cursor/mcp.json

Ensuite, configurez le Serveur MCP. Ici, nous utiliserons notre service utilisateur simulé pour les tests :

.cursor/mcp.json

{
  "mcpServers": {
    "user": {
      "url": "http://localhost:5235/mcp/user/sse"
    }
  }
}

Ensuite, ouvrez les paramètres de Cursor et activez ce Serveur MCP dans la section MCP. Après l'activation, vous verrez qu'il se transforme en un petit point vert et affichera également les outils disponibles.

.cursor/mcp.json

Enfin, vous pouvez l'essayer dans la fenêtre de Chat. Par exemple, demandez-lui de vous aider à enregistrer un utilisateur puis à interroger les informations de cet utilisateur. Si cela fonctionne, vous êtes prêt.

Vous pouvez essayer de taper :

Aidez-moi à enregistrer un utilisateur Leo ifuryst@gmail.com

Aidez-moi à interroger l'utilisateur ifuryst@gmail.com, si non trouvé, veuillez l'enregistrer avec le nom d'utilisateur Leo


Grâce à des tests réels, nous avons découvert que ce service simulé peut causer des erreurs de modèle dans certains cas en raison du traitement des noms et des e-mails, ce qui peut être ignoré. Vous pouvez utiliser votre API réelle à la place.




Vue d'ensemble de l'architecture de la passerelle MCP
Présente une vue d'ensemble de l'architecture du système MCP Gateway, y compris la passerelle elle-même, le backend de gestion, les API de support, les mécanismes de stockage et les méthodes d'intégration avec les services externes.

Diagramme d'architecture
MCP Gateway Architecture

+----------------+
                                       |   API Server   |
                                       |----------------|
                                       | Notifier(Sndr) | --+
                                       | Store(Writer)  | ----->+
                                       +----------------+       |
                                                                |
  +--------------+                                              |
  | Chat Request |                                              |
  +--------------+                                              |
        |                                                       |
        v                                                       |
  +--------------------------------------+                      |
  | Client Side                          |                      |
  | +-------------+ +------------------+ |                      |
  | | MCP Client  | | Integrated MCP   | |                      |
  | +-------------+ | Client           | |                      |
  +-----------------+------------------+ |                      |
    |        |         |          |     |                      |
    | Notify |         | MCP via  |     |                      |
    |(Signal/|         |(HTTP/SSE|     |                      |
    | API...)|         | Stream)  |     |                      |
    +--------+         +----------+     |                      |
        |                   |           |                      |
        |                   |           v                      v
        |  +----------------+------>+--------------------------------------------------------+   +-------------------------------------+
        |  |                        | MCP Gateway                                            |   | Gateway DB                          |
        +--+----------------------->| +-----------------+  +---------------+---------------+   | +---------------------------------+ |
           |                        | | Notifier(Recv)  |  | Reload Config | Store(Reader) |   | | Config for Routers,Tools,Servers| |
           |                        | +-----------------+  +-------+-------+-----+---------+   | +---------------------------------+ |
           |                        |                              |             |         |   | | SQL Backend (SQLite/Postgres)   | |
           |                        |                              |             +----------->-| | Disk Backend (YAML)             | |
           |                        |                              +--------------------------->-| +---------------------------------+ |
           |                        |  +-----------------+                             |     |   +----------------^------------------+
           |                        |  | Entry Point: /* |                             |     |                    |
           |                        |  +-----------------+                             |     +<-------------------+ (WebDB -> GatewayDB Config)
           |                        |          |                                        |     |   +----------------+
           |                        |          v                                        +------>---| Web DB         |
           |                        |  +-----------------------------------+                     |   | (Users, Chats) |
           |                        |  | Router Layer (Match /sse, /msg)   |                     |   +----------------+
           |                        |  +-----------------------------------+                     |
           |                        |          |                                                 |
           |                        |          v                                                 |
           |                        |  +-----------------------------------+                     |
           |                        |  | Core Protocol Parser (Meth,Params)|                     |
           |                        |  +-----------------------------------+                     |
           |                        |          |                                                 |
           |                        |          v                                                 |
           |                        |  +-----------------------------------+                     |
           |                        |  | Tool Dispatcher (Parse Tool, Asm) |                     |
           |                        |  +-----------------------------------+                     |
           |                        |          |                                                 |
           |                        |          v HTTP                                            |
           |                        |  +-----------------------------------+                     |
           |                        |  | External Tool Caller              |                     |
           |                        |  +-----------------------------------+                     |
           |                        |          |                                                 |
           +------------------------+----------|-------------------------------------------------+
                                              v
                                    +------------------+
                                    | Backend Services |
                                    | +--------------+ |
                                    | | Ext.Services | |
                                    | +--------------+ |
                                    +------------------+

Description des modules
Passerelle MCP (mcp-gateway)
Point d'entrée : /* Écoute unifiée de toutes les requêtes HTTP, routage dynamique basé sur la configuration au niveau de l'application
Couche de routage : Routage basé sur les préfixes et suffixes /sse, /message, /mcp
Analyse de protocole : Analyse du format JSON-RPC, extraction des méthodes et paramètres
Distribution d'outils : Analyse des noms d'outils, construction des paramètres d'appel
Appels aux services externes : Lancement des appels aux services externes et analyse des résultats
Stockage de configuration (lecture) : Chargement des informations de configuration
Backend de gestion (web)
Module de configuration des proxies : Utilisé pour configurer les proxies/outils de la passerelle MCP
Laboratoire de chat : Chat simple pour tester MCP, principalement destiné aux développeurs et aux utilisateurs qui doivent l'intégrer dans des systèmes auto-développés
Module de gestion des utilisateurs : Maintenance des permissions et informations utilisateur
Service backend de gestion (apiserver)
Module de service principal : Fournit des API pour la gestion de la configuration, l'interface utilisateur, la requête d'historique de chat, etc.
Stockage de configuration (écriture) : Écrit les modifications dans la base de données
Notificateur (émetteur) : Notifie la passerelle MCP pour les mises à jour à chaud lors des changements de configuration
Stockage de configuration
Stocke toutes les configurations des services MCP, outils, routes, etc.
Prend en charge plusieurs implémentations : disque (yaml), SQLite, PostgreSQL, MySQL, etc.
Stockage de données Web
Stocke les données utilisateur, les enregistrements de session, etc.
Prend en charge plusieurs implémentations : SQLite, PostgreSQL, MySQL, etc.
Services externes
Systèmes de services backend requis pour les appels d'outils



Guide de Configuration de l'Environnement de Développement Local
Ce document décrit comment configurer et démarrer un environnement de développement complet pour MCP Gateway localement, incluant tous les composants de service nécessaires.

Prérequis
Avant de commencer, assurez-vous que votre système dispose des logiciels suivants installés :

Git
Go 1.24.1 ou supérieur
Node.js v20.18.0 ou supérieur
npm
Aperçu de l'Architecture du Projet
Le projet MCP Gateway est composé des composants principaux suivants :

apiserver - Fournit la gestion de configuration, l'interface utilisateur et d'autres services API
mcp-gateway - Service de passerelle principal, gère la conversion du protocole MCP
mock-server - Simule un service utilisateur pour les tests de développement
web - Frontend de l'interface de gestion
Démarrage de l'Environnement de Développement
1. Cloner le Projet
Visitez le dépôt de code MCP Gateway, cliquez sur le bouton Fork pour forker le projet dans votre compte GitHub.

2. Cloner en Local
Clonez votre dépôt forké localement :

git clone https://github.com/votre-nom-utilisateur-github/mcp-gateway.git

3. Initialiser les Dépendances de l'Environnement
Entrez dans le répertoire du projet :

cd mcp-gateway

Installez les dépendances :

go mod tidy
cd web
npm i

4. Démarrer l'Environnement de Développement
cp .env.example .env
cd web
cp .env.example .env

Remarque : Vous pouvez commencer le développement avec la configuration par défaut sans rien modifier, mais vous pouvez également modifier les fichiers de configuration pour répondre à vos besoins d'environnement ou de développement, comme changer Disk, DB, etc.

Remarque : Vous pourriez avoir besoin de 4 fenêtres de terminal pour exécuter tous les services. Cette approche d'exécution de plusieurs services sur la machine hôte facilite le redémarrage et le débogage pendant le développement.

4.1 Démarrer mcp-gateway
go run cmd/gateway/main.go

mcp-gateway démarrera sur http://localhost:5235 par défaut, traitant les requêtes du protocole MCP.

4.2 Démarrer apiserver
go run cmd/apiserver/main.go

apiserver démarrera sur http://localhost:5234 par défaut.

4.3 Démarrer mock-server
go run cmd/mock-server/main.go

mock-server démarrera sur http://localhost:5235 par défaut.

4.4 Démarrer le frontend web
npm run dev

Le frontend web démarrera sur http://localhost:5236 par défaut.

Vous pouvez maintenant accéder à l'interface de gestion dans votre navigateur à http://localhost:5236. Le nom d'utilisateur et le mot de passe par défaut sont déterminés par vos variables d'environnement (dans le fichier .env du répertoire racine), spécifiquement SUPER_ADMIN_USERNAME et SUPER_ADMIN_PASSWORD. Après vous être connecté, vous pouvez changer le nom d'utilisateur et le mot de passe dans l'interface de gestion.

Problèmes Courants
Paramètres des Variables d'Environnement
Certains services peuvent nécessiter des variables d'environnement spécifiques pour fonctionner correctement. Vous pouvez créer un fichier .env ou définir ces variables avant de démarrer la commande :

# Exemple
export OPENAI_API_KEY="votre_clé_api"
export OPENAI_MODEL="gpt-4o-mini"
export APISERVER_JWT_SECRET_KEY="votre_clé_secrète"

Prochaines Étapes
Après avoir réussi à démarrer l'environnement de développement local, vous pouvez :

Consulter la Documentation d'Architecture pour comprendre les composants du système en profondeur
Lire le Guide de Configuration pour apprendre comment configurer la passerelle
Flux de Travail pour Contribuer au Code
Avant de commencer à développer de nouvelles fonctionnalités ou à corriger des bugs, suivez ces étapes pour configurer votre environnement de développement :

Clonez votre dépôt fork localement :
git clone https://github.com/your-github-username/mcp-gateway.git

Ajoutez le dépôt upstream :
git remote add upstream git@github.com:mcp-ecosystem/mcp-gateway.git

Synchronisez avec le code upstream :
git pull upstream main

Poussez les mises à jour vers votre dépôt fork (optionnel) :
git push origin main

Créez une nouvelle branche de fonctionnalité :
git switch -c feat/your-feature-name

Après le développement, poussez votre branche vers le dépôt fork :
git push origin feat/your-feature-name

Créez une Pull Request sur GitHub pour fusionner votre branche dans la branche main du dépôt principal.
Conseils :

Convention de nommage des branches : utilisez le préfixe feat/ pour les nouvelles fonctionnalités, fix/ pour les corrections de bugs
Assurez-vous que votre code passe tous les tests avant de soumettre une PR
Gardez votre dépôt fork synchronisé avec le dépôt upstream pour éviter les conflits de code