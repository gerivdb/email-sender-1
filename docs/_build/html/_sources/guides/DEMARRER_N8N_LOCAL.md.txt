# Guide pour démarrer n8n en local

Ce guide vous explique comment démarrer n8n en local et accéder à l'interface web pour configurer les MCP.

## Méthode 1 : Démarrer n8n avec npx

1. Ouvrez une invite de commande ou PowerShell
2. Naviguez vers votre répertoire de projet
3. Exécutez la commande suivante :
   ```
   npx n8n start
   ```
4. Attendez que n8n démarre (cela peut prendre quelques instants)
5. Une fois démarré, vous verrez un message indiquant l'URL à laquelle vous pouvez accéder à l'interface web
6. Par défaut, l'URL est : http://localhost:5678
7. Ouvrez cette URL dans votre navigateur web

## Méthode 2 : Utiliser n8n Desktop

Si vous avez installé n8n Desktop, vous pouvez simplement :

1. Recherchez "n8n Desktop" dans le menu Démarrer de Windows
2. Cliquez sur l'application pour la lancer
3. n8n Desktop ouvrira automatiquement l'interface web dans votre navigateur par défaut

## Méthode 3 : Utiliser un script de démarrage

Vous pouvez créer un script batch pour démarrer n8n facilement :

1. Créez un fichier `start-n8n.cmd` avec le contenu suivant :
   ```batch
   @echo off
   echo Démarrage de n8n...
   npx n8n start
   ```
2. Double-cliquez sur ce fichier pour démarrer n8n

## Vérifier que n8n est en cours d'exécution

Pour vérifier que n8n est en cours d'exécution :

1. Ouvrez votre navigateur web
2. Accédez à http://localhost:5678
3. Vous devriez voir l'interface web de n8n

## Configurer les identifiants MCP dans n8n

Une fois n8n démarré et l'interface web ouverte :

1. Cliquez sur l'icône d'engrenage (⚙️) dans le coin supérieur droit
2. Sélectionnez "Credentials" dans le menu déroulant
3. Cliquez sur "Create New" pour créer un nouvel identifiant
4. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
5. Configurez l'identifiant selon les instructions du guide CONFIGURATION_MCP_MISE_A_JOUR.md

## Dépannage

Si vous rencontrez des problèmes pour démarrer n8n :

1. Vérifiez que Node.js est correctement installé :
   ```
   node --version
   ```

2. Vérifiez que n8n est accessible via npx :
   ```
   npx n8n --version
   ```

3. Si vous avez des erreurs de port, essayez de spécifier un port différent :
   ```
   npx n8n start --port 5679
   ```

4. Vérifiez si un autre processus n8n est déjà en cours d'exécution :
   ```
   tasklist | findstr node
   ```

5. Si nécessaire, terminez les processus n8n existants :
   ```
   taskkill /F /IM node.exe
   ```
   (Attention : cela terminera tous les processus Node.js en cours d'exécution)
