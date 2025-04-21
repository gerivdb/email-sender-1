/**
 * Module d'authentification
 * Gère l'authentification pour l'interface web et l'API
 */

const crypto = require('crypto');
const fs = require('fs-extra');
const path = require('path');
const config = require('./config');
const logger = require('./logger');

// Chemin vers le fichier des utilisateurs
const usersFilePath = path.resolve(__dirname, '../../config/users.json');

// Utilisateurs par défaut
const defaultUsers = {
  admin: {
    passwordHash: hashPassword('admin'),
    role: 'admin'
  },
  user: {
    passwordHash: hashPassword('user'),
    role: 'user'
  }
};

// Utilisateurs chargés
let users = {};

/**
 * Initialise le module d'authentification
 * @returns {Promise<void>}
 */
const init = async () => {
  try {
    // Vérifier si le fichier des utilisateurs existe
    if (!await fs.pathExists(usersFilePath)) {
      // Créer le fichier avec les utilisateurs par défaut
      await fs.writeJson(usersFilePath, defaultUsers, { spaces: 2 });
      logger.info('Fichier des utilisateurs créé avec les utilisateurs par défaut');
    }
    
    // Charger les utilisateurs
    users = await fs.readJson(usersFilePath);
    logger.info(`${Object.keys(users).length} utilisateurs chargés`);
  } catch (error) {
    logger.error(`Erreur lors de l'initialisation du module d'authentification: ${error.message}`);
    // Utiliser les utilisateurs par défaut en cas d'erreur
    users = defaultUsers;
  }
};

/**
 * Hache un mot de passe
 * @param {string} password - Le mot de passe à hacher
 * @returns {string} Le mot de passe haché
 */
function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

/**
 * Vérifie les identifiants d'un utilisateur
 * @param {string} username - Le nom d'utilisateur
 * @param {string} password - Le mot de passe
 * @returns {boolean} true si les identifiants sont valides, false sinon
 */
const verifyCredentials = (username, password) => {
  // Vérifier si l'utilisateur existe
  if (!users[username]) {
    return false;
  }
  
  // Vérifier le mot de passe
  const passwordHash = hashPassword(password);
  return passwordHash === users[username].passwordHash;
};

/**
 * Récupère le rôle d'un utilisateur
 * @param {string} username - Le nom d'utilisateur
 * @returns {string|null} Le rôle de l'utilisateur ou null s'il n'existe pas
 */
const getUserRole = (username) => {
  return users[username]?.role || null;
};

/**
 * Vérifie si un utilisateur a un rôle spécifique
 * @param {string} username - Le nom d'utilisateur
 * @param {string} role - Le rôle à vérifier
 * @returns {boolean} true si l'utilisateur a le rôle, false sinon
 */
const hasRole = (username, role) => {
  return getUserRole(username) === role;
};

/**
 * Ajoute un nouvel utilisateur
 * @param {string} username - Le nom d'utilisateur
 * @param {string} password - Le mot de passe
 * @param {string} role - Le rôle de l'utilisateur
 * @returns {Promise<boolean>} true si l'utilisateur a été ajouté, false sinon
 */
const addUser = async (username, password, role) => {
  try {
    // Vérifier si l'utilisateur existe déjà
    if (users[username]) {
      return false;
    }
    
    // Ajouter l'utilisateur
    users[username] = {
      passwordHash: hashPassword(password),
      role
    };
    
    // Sauvegarder les utilisateurs
    await fs.writeJson(usersFilePath, users, { spaces: 2 });
    logger.info(`Utilisateur ${username} ajouté avec le rôle ${role}`);
    
    return true;
  } catch (error) {
    logger.error(`Erreur lors de l'ajout de l'utilisateur ${username}: ${error.message}`);
    return false;
  }
};

/**
 * Supprime un utilisateur
 * @param {string} username - Le nom d'utilisateur
 * @returns {Promise<boolean>} true si l'utilisateur a été supprimé, false sinon
 */
const removeUser = async (username) => {
  try {
    // Vérifier si l'utilisateur existe
    if (!users[username]) {
      return false;
    }
    
    // Supprimer l'utilisateur
    delete users[username];
    
    // Sauvegarder les utilisateurs
    await fs.writeJson(usersFilePath, users, { spaces: 2 });
    logger.info(`Utilisateur ${username} supprimé`);
    
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la suppression de l'utilisateur ${username}: ${error.message}`);
    return false;
  }
};

/**
 * Change le mot de passe d'un utilisateur
 * @param {string} username - Le nom d'utilisateur
 * @param {string} newPassword - Le nouveau mot de passe
 * @returns {Promise<boolean>} true si le mot de passe a été changé, false sinon
 */
const changePassword = async (username, newPassword) => {
  try {
    // Vérifier si l'utilisateur existe
    if (!users[username]) {
      return false;
    }
    
    // Changer le mot de passe
    users[username].passwordHash = hashPassword(newPassword);
    
    // Sauvegarder les utilisateurs
    await fs.writeJson(usersFilePath, users, { spaces: 2 });
    logger.info(`Mot de passe de l'utilisateur ${username} changé`);
    
    return true;
  } catch (error) {
    logger.error(`Erreur lors du changement de mot de passe de l'utilisateur ${username}: ${error.message}`);
    return false;
  }
};

/**
 * Liste tous les utilisateurs
 * @returns {Object} Un objet avec les noms d'utilisateur et leurs rôles
 */
const listUsers = () => {
  return Object.entries(users).reduce((acc, [username, user]) => {
    acc[username] = { role: user.role };
    return acc;
  }, {});
};

/**
 * Middleware d'authentification pour Express
 * @param {Object} options - Options du middleware
 * @returns {Function} Middleware Express
 */
const authMiddleware = (options = {}) => {
  const { requireAdmin = false, apiAuth = false } = options;
  
  return (req, res, next) => {
    // Vérifier si l'authentification est activée
    if (!config.auth?.enabled) {
      return next();
    }
    
    // Vérifier si l'utilisateur est déjà authentifié
    if (req.session?.user) {
      // Vérifier si l'admin est requis
      if (requireAdmin && !hasRole(req.session.user, 'admin')) {
        return res.status(403).json({ error: 'Accès refusé' });
      }
      
      return next();
    }
    
    // Pour l'API, vérifier l'authentification par token
    if (apiAuth) {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authentification requise' });
      }
      
      const token = authHeader.split(' ')[1];
      
      // Vérifier le token (implémentation simple)
      if (token !== config.auth.apiToken) {
        return res.status(401).json({ error: 'Token invalide' });
      }
      
      return next();
    }
    
    // Rediriger vers la page de connexion pour l'interface web
    return res.redirect('/login');
  };
};

// Initialiser le module
init();

module.exports = {
  verifyCredentials,
  getUserRole,
  hasRole,
  addUser,
  removeUser,
  changePassword,
  listUsers,
  authMiddleware
};
