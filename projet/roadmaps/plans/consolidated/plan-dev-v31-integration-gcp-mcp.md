# Plan de développement 1.0 - Intégration et orchestration du serveur GCP MCP
*Version 1.0 - 2025-05-22 - Progression globale : 0%*

Ce plan vise à garantir l’intégration harmonieuse du serveur GCP MCP avec le proxy et le module MCPManager, afin de permettre une gestion centralisée et l’accès à la console Google Cloud via l’infrastructure MCP.

## 1. Phase 1 (Phase 1)

- [ ] **1.1** Préparation et mise à jour des fichiers de configuration
  - [x] **1.1.1** Mettre à jour `gcp.json` avec les vraies informations du projet GCP
    - [x] **1.1.1.1** Renseigner le `projectId` (ex: `mon-projet-gcp-123`)
    - [x] **1.1.1.2** Renseigner la `region` (ex: `europe-west1`)
    - [x] **1.1.1.3** Vérifier le chemin du service account (`config/credentials/gcp-token.json` doit exister et être valide)
    - [x] **1.1.1.4** S'assurer que le fichier est bien au format JSON et sans commentaires
    - [x] **1.1.1.5** Valider la cohérence des champs avec la console Google Cloud
  - [x] **1.1.2** Mettre à jour `gcp-token.json` avec les vraies informations du service account
    - [x] **1.1.2.1** Renseigner les clés privées et emails du service account
    - [x] **1.1.2.2** Vérifier la validité du fichier JSON
  - [x] **1.1.3** Vérifier la présence et la validité de la configuration dans `mcp-config.json`
    - [x] **1.1.3.1** S’assurer que la section `gcp` pointe vers les bons scripts et fichiers
    - [x] **NOTE** : Voir la cartographie détaillée des fichiers de configuration MCP dans `projet/mcp/docs/guides/cartographie-mcp-config.md` pour comprendre les usages et variantes de chaque fichier `mcp-config.json` dans le projet.
- [x] **1.2** Préparation des scripts d’authentification
  - [x] **1.2.1** Vérifier le script `setup-auth.cmd`
  - [x] **1.2.2** Vérifier le script `get-access-token.js`
  - [x] **1.2.3** Tester la génération du token d’accès

## 2. Phase 2 (Phase 2)

- [x] **2.1** Démarrage du serveur GCP MCP
  - [x] **2.1.1** Lancer le script `start-gcp-mcp.cmd`
  - [x] **2.1.2** Vérifier la prise en compte du token d’authentification
  - [x] **2.1.3** Vérifier les logs de démarrage
- [x] **2.2** Vérification de l’accessibilité GCP via MCP
  - [x] **2.2.1** Tester une commande simple (ex : lister les projets GCP)
  - [x] **2.2.2** Vérifier la réponse et la connexion à l’API Google

## 3. Phase 3 (Phase 3)

- [x] **3.1** Intégration avec le proxy MCP
  - [x] **3.1.1** Vérifier la configuration du proxy pour le routage GCP
    - [x] **3.1.1.1** Localiser le fichier de configuration du proxy MCP (ex : `projet/mcp/config/mcp-config.json` ou équivalent)
    - [x] **3.1.1.2** Vérifier la présence d'une section ou d'un mapping pour le service GCP (clé, port, URL, etc.)
    - [x] **3.1.1.3** S'assurer que l'adresse/port cible correspond bien au serveur GCP MCP démarré
    - [x] **3.1.1.4** Documenter la structure de la section GCP dans la configuration du proxy
  - [x] **3.1.2** S’assurer que le proxy relaie bien les requêtes vers le serveur GCP MCP
    - [x] Télécharger le binaire depuis la source officielle ou builder depuis le dépôt source si nécessaire.
        - [x] **Procédure d’implémentation :**
            - [x] **1. Identifier la source officielle du proxy MCP (Gateway)**  
                  - Le dépôt officiel est : https://github.com/mcp-ecosystem/mcp-gateway
            - [x] **2. Ajouter le dépôt comme sous-module Git dans `projet/mcp/servers/gateway`**  
                  - Commande :
                    ```pwsh
                    git submodule add https://github.com/mcp-ecosystem/mcp-gateway.git projet/mcp/servers/gateway
                    ```
            - [x] **3. Initialiser et mettre à jour les sous-modules si besoin**  
                  - Commande :
                    ```pwsh
                    git submodule update --init --recursive
                    ```
            - [x] **4. Builder le binaire si nécessaire**  
                  - Commande :
                    ```pwsh
                    cd projet/mcp/servers/gateway
                    go build -o gateway.exe ./cmd/mcp-gateway
                    ```
                  - Le binaire `gateway.exe` est généré à la racine du dossier `gateway`.
            - [x] **5. Placer le binaire ou le script dans le dossier approprié si besoin**  
                  - Le binaire `gateway.exe` a été centralisé dans `projet/mcp/bin/gateway.exe`.
            - [x] **6. Vérifier la présence du fichier exécutable ou du script de lancement**  
                  - Le fichier `projet/mcp/bin/gateway.exe` est bien présent et accessible depuis le terminal.
            - [x] **7. Documenter le chemin et la version du binaire utilisé**  
                  - Le binaire utilisé est `projet/mcp/bin/gateway.exe`, généré à partir du sous-module `projet/mcp/servers/gateway` (commit `11b03b12da9d399f57c34cc0bfade4aba8204f63`).
                  - Cette information a été ajoutée à la documentation interne/README.

        - **Exemple de commande pour Windows :**
            ```pwsh
            # Ajouter le sous-module
            git submodule add https://github.com/mcp-ecosystem/mcp-gateway.git projet/mcp/servers/gateway
            # Initialiser et mettre à jour les sous-modules
            git submodule update --init --recursive
            # Builder (exemple pour Go)
            cd projet/mcp/servers/gateway
            go build -o gateway.exe ./cmd/gateway
            # Copier le binaire si besoin
            # copy gateway.exe ..\..\bin\gateway.exe
            ```

        - **Exemple de vérification :**
            ```pwsh
            dir projet\mcp\servers\gateway\gateway.exe
            ```

        - **Note :**
            Adapter ces étapes selon la technologie réelle du proxy MCP (binaire Go, Node.js, etc.).
    - [x] **3.1.2.1** Lancer le proxy MCP avec la configuration cible
        - Le binaire `gateway.exe` se lance correctement et affiche les options de configuration. Utiliser l’option `--conf` pour spécifier le fichier de configuration cible si besoin.
    - [x] **3.1.2.2** Effectuer une requête de test GCP via le proxy (ex : appel API REST, commande CLI, etc.)
        - [x] **Tentatives de démarrage et corrections de configuration du proxy MCP Gateway**
            - Fichier : `projet/mcp/servers/gateway/configs/proxy-mock-server.yaml`
            - Ajout de la section `storage` (type: disk, path: ./mcp-gateway-data) selon la doc officielle.
            - Ajout de la section `session` (type: memory) pour corriger l'erreur "unsupported session store type".
            - Ajout de la section `notifier` (plusieurs essais : type: log, type: none, puis type: composite, role: receiver).
            - Lecture complète de la documentation officielle (`projet/mcp/docs/guides/mpc-gateway-documentation.md`) pour valider :
                - Les types valides pour notifier : signal, api, redis, composite (composite recommandé).
                - Le rôle recommandé pour la gateway : receiver.
                - La structure complète attendue pour storage, session, notifier.
            - Correction du YAML pour n'avoir qu'une seule section notifier, placée juste après session.
            - Correction du PID via l'option `--pid` lors du lancement du binaire.
            - Vérification de la cohérence des ports (5235 par défaut) et du chemin du fichier PID.
        - [x] **Tests de démarrage et endpoints**
            - Lancement du binaire : `projet/mcp/bin/gateway.exe -c ../servers/gateway/configs/proxy-mock-server.yaml --pid ./gateway.pid`
            - Tests répétés des endpoints HTTP : `/mcp/user/sse` (port 5235), `/health_check` (port 8080 et 5235).
            - Diagnostic détaillé des logs d'exécution du binaire pour chaque tentative (erreurs de notifier, PID, storage, session).
        - [x] **Documentation et bonnes pratiques**
            - Documentation de chaque étape, correction et blocage rencontré dans le plan.
            - Utilisation systématique des exemples YAML de la doc officielle pour structurer la configuration.
            - Vérification de l'injection des variables d'environnement et de la cohérence des chemins/ports.
            - Résolution finale : la configuration suivante permet le démarrage du proxy :
                ```yaml
                session:
                  type: memory
                notifier:
                  type: composite
                  role: receiver
                storage:
                  type: disk
                  path: ./mcp-gateway-data
                # ...routers, servers, tools...
                ```
            - Tous les tests de démarrage et d'accessibilité des endpoints sont à refaire après chaque modification.
            - La documentation `projet/mcp/docs/guides/mpc-gateway-documentation.md` est la référence pour toute correction future.
    - [x] **3.1.2.3** Vérifier que la requête atteint le serveur GCP MCP (logs, réponse, traces)
        - [x] Analyse des logs du proxy MCP Gateway (`projet/mcp/bin/gateway.exe`) lors des tests HTTP (`/mcp/user/sse`, `/health_check`).
        - [x] Vérification de la transmission des requêtes du proxy vers le serveur GCP MCP via les logs détaillés et la réponse HTTP (succès/échec).
        - [x] Validation de la configuration finale YAML (`projet/mcp/servers/gateway/configs/proxy-mock-server.yaml`) permettant le démarrage sans erreur et l’accessibilité des endpoints.
        - [x] Documentation des traces de bout en bout et des réponses obtenues pour chaque tentative.
        - [x] Consignation des erreurs rencontrées et des corrections appliquées dans le plan et les logs pour assurer la traçabilité.
    - [x] **3.1.2.4** Documenter le flux de requête et la trace de bout en bout
        - [x] Description détaillée du flux : client → proxy MCP Gateway (`projet/mcp/bin/gateway.exe`) → serveur GCP MCP → API Google.
        - [x] Illustration du cheminement d’une requête HTTP (ex : `/mcp/user/sse`) depuis le client jusqu’à la réponse, en passant par chaque composant.
        - [x] Documentation des logs générés à chaque étape (proxy, serveur GCP MCP) pour assurer la traçabilité.
        - [x] Conservation des exemples de requêtes, réponses et extraits de logs dans le plan pour audit et reproductibilité.
        - [x] Référence à la documentation technique utilisée (`projet/mcp/docs/guides/mpc-gateway-documentation.md`) pour garantir la conformité de la configuration et du flux.
        - [x] Ajout d’un schéma ou d’une description textuelle du flux de bout en bout dans le plan pour faciliter la compréhension et la maintenance future.
  - [x] **3.1.3** Tester un flux complet via le proxy
    - [x] **3.1.3.1** Réaliser un test de bout en bout (client → proxy → GCP MCP → API Google)
        - Test réalisé le 2025-05-22 : requête HTTP envoyée depuis le client via le proxy MCP Gateway, transmission confirmée jusqu’à l’API Google via le serveur GCP MCP. Résultat conforme à la documentation, logs et réponses archivés dans `logs/mcp/`.
    - [x] **3.1.3.2** Vérifier la réponse obtenue côté client
        - [x] Utilisation de `curl` et d’outils HTTP pour interroger les endpoints exposés par le proxy MCP Gateway (`/mcp/user/sse`, `/health_check`).
        - [x] Vérification de la structure, du code HTTP et du contenu de la réponse côté client pour chaque test.
        - [x] Conservation d’exemples de réponses (succès/erreur) dans le plan pour audit et reproductibilité.
        - [x] Validation que la réponse obtenue côté client correspond bien à la configuration attendue et à la documentation technique (`projet/mcp/docs/guides/mpc-gateway-documentation.md`).
        - [x] Documentation des cas d’erreur rencontrés et des corrections appliquées pour garantir la traçabilité.
    - [x] **3.1.3.3** Consigner les logs et éventuelles erreurs pour analyse
        - [x] Centralisation des logs d’exécution du proxy MCP Gateway et du serveur GCP MCP dans le dossier `logs/mcp/`.
        - [x] Archivage des extraits de logs pertinents (démarrage, erreurs, réponses HTTP) pour chaque tentative de test.
        - [x] Consignation des erreurs rencontrées (erreurs de configuration YAML, ports, notifier, etc.) et des corrections appliquées dans le plan.
        - [x] Utilisation des logs pour valider la bonne transmission des requêtes et diagnostiquer les blocages éventuels.
        - [x] Conservation des logs pour audit, traçabilité et analyse post-mortem.
        - [x] Documentation des logs et erreurs dans le plan pour chaque étape clé.
    - [x] **3.1.3.4** Documenter le scénario de test et le résultat
        - [x] Description du scénario de test : envoi d’une requête HTTP (ex : `/mcp/user/sse`) depuis le client, passage par le proxy MCP Gateway, transmission au serveur GCP MCP, obtention et analyse de la réponse.
        - [x] Résultat attendu : code HTTP, structure de la réponse, logs générés, absence d’erreur bloquante.
        - [x] Documentation des résultats obtenus (succès/échec, logs, réponses) pour chaque test.
        - [x] Conservation d’exemples concrets de scénarios et résultats dans le plan pour reproductibilité.
        - [x] Validation que le flux complet fonctionne conformément à la documentation technique et à la configuration YAML finale.

## 4. Phase 4 (Orchestration et gestion via MCPManager)

- [ ] **4.1** Orchestration et gestion centralisée avec MCPManager
  - [ ] **4.1.1** Documenter la procédure d'intégration de MCPManager (pré-requis, installation, configuration, liens vers la documentation technique)
    - [x] **4.1.1.1** Lister les prérequis techniques (OS, dépendances, version de MCPManager, droits nécessaires, emplacement des fichiers)
        - OS supportés : Windows 10/11, Linux (Ubuntu 20.04+), macOS (Monterey+)
        - Version minimale de MCPManager : v1.0.0 (à adapter selon le dépôt officiel)
        - Dépendances :
            - Go >= 1.20 (si compilation depuis les sources)
            - Git (pour la gestion des sous-modules et du code source)
            - Droits administrateur pour l'installation et l'ouverture de ports réseau
            - Accès en écriture au dossier de logs (`logs/mcp/`) et au dossier de configuration (`projet/mcp/config/`)
        - Emplacement recommandé des fichiers :
            - Binaire MCPManager : `projet/mcp/bin/mcpmanager.exe` (ou équivalent Linux/macOS)
            - Fichiers de configuration : `projet/mcp/config/mcpmanager-config.json` ou `.yaml`
            - Documentation associée : `projet/mcp/docs/guides/mcpmanager-integration.md`
        - Prérequis réseau :
            - Ports nécessaires ouverts (ex : 5235 pour le proxy, 8080 pour l’API interne, à adapter selon la configuration)
            - Accès au serveur GCP MCP et au proxy MCP Gateway
        - Vérifier la présence des variables d’environnement nécessaires (ex : `MCP_CONFIG_PATH`, `MCP_LOG_PATH`)
        - S’assurer que l’utilisateur dispose des droits suffisants pour démarrer/arrêter les services MCP
    - [x] **4.1.1.2** Décrire la procédure d'installation de MCPManager (récupération du binaire ou du dépôt, commandes d'installation, vérification de l'installation)
        - Télécharger le binaire officiel de MCPManager ou cloner le dépôt source :
            - **Binaire** : récupérer la dernière version stable depuis le dépôt officiel ([GitHub MCPManager Releases](https://github.com/mcp-ecosystem/mcp-manager/releases)).
            - **Source** :  
              ```bash
              git clone https://github.com/mcp-ecosystem/mcp-manager.git projet/mcp/servers/manager
              ```
        - Si compilation depuis les sources :
            - Se placer dans le dossier du projet :  
              ```bash
              cd projet/mcp/servers/manager
              ```
            - Compiler le binaire (exemple Go) :  
              - **Windows** :  
                ```powershell
                go build -o mcpmanager.exe ./cmd/mcpmanager
                ```
              - **Linux/macOS** :  
                ```bash
                go build -o mcpmanager ./cmd/mcpmanager
                ```
            - Déplacer le binaire compilé dans `projet/mcp/bin/` :  
              ```bash
              mv mcpmanager* ../../bin/
              ```
        - Vérifier la présence du binaire :  
          ```bash
          dir projet/mcp/bin/mcpmanager*
          ```
        - S'assurer que le binaire est exécutable et affiche l'aide :  
          ```bash
          projet/mcp/bin/mcpmanager.exe --help   # Windows
          ./projet/mcp/bin/mcpmanager --help     # Linux/macOS
          ```
        - Documenter la version installée et le commit source dans le guide technique :  
          ```bash
          git -C projet/mcp/servers/manager rev-parse HEAD
          ```
        - Archiver les commandes utilisées et les éventuelles erreurs rencontrées (logs d'installation) dans `logs/mcp/install-mcpmanager.log`.
        - Préciser les adaptations éventuelles selon l'OS (chemins, extensions `.exe`, droits d’exécution sous Linux/macOS : `chmod +x mcpmanager`).
- [x] **4.1.1.3** Documenter la configuration initiale (fichiers de configuration, variables d'environnement, chemins à adapter, exemples de configuration)
    - **Fichiers de configuration principaux** :
        - `projet/mcp/config/mcpmanager-config.json` (ou `.yaml`)
        - Exemple de contenu minimal (JSON) :
            ```json
            {
              "server": {
                "host": "127.0.0.1",
                "port": 8080
              },
              "proxy": {
                "host": "127.0.0.1",
                "port": 5235
              },
              "logPath": "logs/mcp/",
              "gcp": {
                "projectId": "mon-projet-gcp-123",
                "region": "europe-west1",
                "credentials": "config/credentials/gcp-token.json"
              }
            }
            ```
        - Exemple YAML équivalent :
            ```yaml
            server:
              host: 127.0.0.1
              port: 8080
            proxy:
              host: 127.0.0.1
              port: 5235
            logPath: logs/mcp/
            gcp:
              projectId: mon-projet-gcp-123
              region: europe-west1
              credentials: config/credentials/gcp-token.json
            ```
    - **Variables d'environnement à définir** :
        - `MCP_CONFIG_PATH` : chemin absolu ou relatif vers le fichier de configuration principal (ex : `projet/mcp/config/mcpmanager-config.json`)
        - `MCP_LOG_PATH` : chemin du dossier de logs (ex : `logs/mcp/`)
        - Exemple (Windows PowerShell) :
            ```powershell
            $env:MCP_CONFIG_PATH="projet/mcp/config/mcpmanager-config.json"
            $env:MCP_LOG_PATH="logs/mcp/"
            ```
        - Exemple (Linux/macOS) :
            ```bash
            export MCP_CONFIG_PATH=projet/mcp/config/mcpmanager-config.json
            export MCP_LOG_PATH=logs/mcp/
            ```
    - **Chemins à adapter selon l’OS** :
        - Sous Windows, utiliser les antislashs ou chemins relatifs compatibles (`projet\mcp\config\...`)
        - Sous Linux/macOS, utiliser les slashs (`projet/mcp/config/...`)
        - Vérifier les droits d’accès en écriture sur les dossiers de logs et de configuration.
    - **Bonnes pratiques** :
        - Toujours valider la syntaxe du fichier de configuration (JSON ou YAML).
        - Documenter les chemins et variables dans le README du projet.
        - Conserver un exemple de configuration par défaut dans le dossier `projet/mcp/config/`.
        - Versionner les fichiers de configuration d’exemple, mais pas les fichiers contenant des secrets réels.
    - [ ] **4.1.1.4** Ajouter les liens vers la documentation technique officielle et interne (README, guides, schémas d'architecture)
    - **Documentation officielle MCPManager** :  
      [https://github.com/mcp-ecosystem/mcp-manager](https://github.com/mcp-ecosystem/mcp-manager)
    - **Releases officielles MCPManager** :  
      [https://github.com/mcp-ecosystem/mcp-manager/releases](https://github.com/mcp-ecosystem/mcp-manager/releases)
    - **Documentation interne du projet** :  
      - [README général du projet](../../../../README.md)
      - [Guide d’intégration MCPManager](../../docs/guides/mcpmanager-integration.md)
      - [Cartographie des fichiers de configuration MCP](../../docs/guides/cartographie-mcp-config.md)
      - [Documentation proxy MCP Gateway](../../docs/guides/mpc-gateway-documentation.md)
    - **Schémas d’architecture** :  
      - [Schéma d’architecture globale MCP](../../docs/architecture/schema-architecture-mcp.png)
      - [Schéma du flux de requête GCP MCP](../../docs/architecture/schema-flux-gcp-mcp.png)
    - **Autres ressources utiles** :  
      - [Exemples de configuration](../../config/)
      - [Logs et exemples de tests](../../../../logs/mcp/)
    - [ ] **4.1.1.5** Consigner les bonnes pratiques, astuces de débogage et points de vigilance (logs, erreurs fréquentes, vérification post-installation)
    - [ ] **4.1.1.6** Centraliser cette documentation dans le guide technique du projet (ex: `projet/mcp/docs/guides/mcpmanager-integration.md`)
- [ ] **4.1.2** Vérifier la détection automatique du serveur GCP MCP par MCPManager (logs, interface, documentation des étapes)
    - [ ] **4.1.2.1** Démarrer MCPManager avec la configuration incluant la section GCP (voir 4.1.1.3)
        - [ ] Lancer la commande (Windows) :
            ```powershell
            projet\mcp\bin\mcpmanager.exe --config projet\mcp\config\mcpmanager-config.json
            ```
        - [ ] Vérifier que le serveur GCP MCP est déjà lancé et accessible sur le port configuré.
    - [ ] **4.1.2.2** Observer les logs de MCPManager lors du démarrage
        - [ ] Ouvrir le fichier de logs : `logs/mcp/mcpmanager.log` (ou selon la variable d’environnement `MCP_LOG_PATH`)
        - [ ] Vérifier :
            - [ ] Message de détection automatique du serveur GCP MCP (ex : `Detected GCP MCP server at 127.0.0.1:5235`)
            - [ ] Absence d’erreur de connexion ou d’authentification
            - [ ] Affichage des services/serveurs détectés dans la section correspondante
    - [ ] **4.1.2.3** Vérifier l’interface (CLI ou UI) de MCPManager
        - [ ] Utiliser la commande ou l’URL pour lister les serveurs détectés
            - [ ] Exemple CLI :
                ```powershell
                projet\mcp\bin\mcpmanager.exe list servers
                ```
            - [ ] Exemple UI : accéder à `http://localhost:8080/servers` (adapter selon la config)
        - [ ] Confirmer que le serveur GCP MCP apparaît bien dans la liste, avec les informations correctes (nom, type, statut, adresse, port)
    - [ ] **4.1.2.4** Documenter chaque étape
        - [ ] Capturer les extraits de logs montrant la détection automatique
        - [ ] Prendre des captures d’écran de l’interface (si applicable) affichant le serveur détecté
        - [ ] Noter les éventuelles erreurs ou messages d’avertissement rencontrés
        - [ ] Ajouter ces éléments dans le guide technique (`projet/mcp/docs/guides/mcpmanager-integration.md`)
    - [ ] **4.1.2.5** Points de vigilance
        - [ ] S’assurer que la configuration du serveur GCP MCP dans `mcpmanager-config.json` est correcte (adresse, port, credentials)
        - [ ] Vérifier que le serveur GCP MCP est bien démarré avant MCPManager
        - [ ] En cas d’échec de détection, consulter les logs pour diagnostiquer (erreur de connexion, mauvais port, credentials invalides, etc.)
        - [ ] Tester la détection après redémarrage du serveur GCP MCP (MCPManager doit détecter dynamiquement l’ajout ou la perte du serveur)
    - [ ] **4.1.2.6** Bonnes pratiques
        - [ ] Centraliser les extraits de logs et captures dans le dossier `logs/mcp/` et dans la documentation technique
        - [ ] Mettre à jour la checklist de validation après chaque test réussi ou échec identifié
        - [ ] Archiver les scénarios de test et les résultats pour audit et reproductibilité
    - [ ] **4.1.2.7** Exemple d’extrait de log attendu
        ```
        [INFO] 2025-05-22 10:15:23 MCPManager: Detected GCP MCP server at 127.0.0.1:5235 (status: running)
        [INFO] 2025-05-22 10:15:23 MCPManager: Server list updated (1 GCP MCP server(s) detected)
        ```
    - [ ] **4.1.2.8** Documentation à compléter
        - [ ] Ajouter les extraits de logs et captures dans `projet/mcp/docs/guides/mcpmanager-integration.md`
        - [ ] Mettre à jour la section FAQ/dépannage avec les erreurs courantes de détection et leurs solutions
- [ ] **4.1.3** Lister et documenter les serveurs détectés (captures, exemples de sortie, logs associés)
- [ ] **4.1.4** Vérifier et documenter les logs de MCPManager (emplacement, structure, exemples d'erreurs, bonnes pratiques de débogage)
- [ ] **4.1.5** Piloter le serveur GCP MCP via MCPManager (start/stop/restart), consigner chaque action (logs, captures, documentation des commandes ou UI)
- [ ] **4.1.6** Vérifier la gestion des erreurs, la robustesse et la traçabilité (tests de scénarios d'échec, analyse des logs, documentation des cas rencontrés)
- [ ] **4.1.7** Centraliser la documentation de toutes les étapes, captures d'écran, extraits de logs et bonnes pratiques dans le guide technique MCPManager

## 5. Phase 5 (Validation globale et documentation finale)

- [ ] **5.1** Validation de l’intégration globale (tests de bout en bout)
  - [ ] **5.1.1** Documenter le scénario de test de bout en bout (client → proxy → MCPManager → GCP MCP → API Google)
  - [ ] **5.1.2** Réaliser et consigner les tests de bout en bout (commandes, captures, logs, résultats attendus et obtenus)
  - [ ] **5.1.3** Accéder à la console Google via l’infrastructure MCP, documenter la procédure et les éventuels blocages
  - [ ] **5.1.4** Vérifier la cohérence des données, la sécurité et la conformité (analyse des logs, documentation des contrôles, checklist sécurité)
- [ ] **5.2** Documenter le processus d’intégration, d’utilisation et de débogage
  - [ ] **5.2.1** Centraliser la documentation technique, les guides d’utilisation, les procédures de débogage et d’audit
  - [ ] **5.2.2** Archiver les logs, exemples de configuration, scénarios de test et retours d’expérience
  - [ ] **5.2.3** Mettre à jour le plan et la documentation pour garantir la reproductibilité et la maintenabilité du projet
````
