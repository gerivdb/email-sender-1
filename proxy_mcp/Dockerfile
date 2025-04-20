# Utiliser une image Node.js officielle comme base
FROM node:18-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install --omit=dev

# Copier le reste des fichiers de l'application
COPY . .

# Créer les répertoires nécessaires
RUN mkdir -p logs config

# Exposer le port sur lequel l'application s'exécute
EXPOSE 4000

# Définir les variables d'environnement
ENV NODE_ENV=production

# Commande pour démarrer l'application en mode débogage
CMD ["node", "src/debug.js"]
