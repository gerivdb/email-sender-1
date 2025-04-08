from abc import ABC, abstractmethod
from pathlib import Path
import os
import json
import logging

class IntegrationBase(ABC):
    """Classe de base pour toutes les intégrations."""
    
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.integration_dir = self.journal_dir / self.integration_name
        self.integration_dir.mkdir(exist_ok=True, parents=True)
        
        # Configuration du logging
        self.logger = logging.getLogger(f"journal.integration.{self.integration_name}")
        self.logger.setLevel(logging.INFO)
        
        # Charger la configuration
        self.config = self._load_config()
    
    @property
    @abstractmethod
    def integration_name(self):
        """Nom de l'intégration (à implémenter dans les sous-classes)."""
        pass
    
    def _load_config(self):
        """Charge la configuration de l'intégration."""
        config_file = self.integration_dir / "config.json"
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                self.logger.error(f"Erreur lors du chargement de la configuration: {e}")
                return {}
        return {}
    
    def save_config(self):
        """Sauvegarde la configuration de l'intégration."""
        config_file = self.integration_dir / "config.json"
        try:
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=2)
            self.logger.info(f"Configuration sauvegardée dans {config_file}")
        except Exception as e:
            self.logger.error(f"Erreur lors de la sauvegarde de la configuration: {e}")
    
    @abstractmethod
    def authenticate(self):
        """Authentifie l'intégration (à implémenter dans les sous-classes)."""
        pass
    
    @abstractmethod
    def sync_to_journal(self):
        """Synchronise les données de l'intégration vers le journal."""
        pass
    
    @abstractmethod
    def sync_from_journal(self):
        """Synchronise les données du journal vers l'intégration."""
        pass
    
    def save_associations(self, associations, filename):
        """Sauvegarde les associations dans un fichier JSON."""
        file_path = self.integration_dir / filename
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(associations, f, ensure_ascii=False, indent=2)
            self.logger.info(f"Associations sauvegardées dans {file_path}")
        except Exception as e:
            self.logger.error(f"Erreur lors de la sauvegarde des associations: {e}")
    
    def load_associations(self, filename):
        """Charge les associations depuis un fichier JSON."""
        file_path = self.integration_dir / filename
        if not file_path.exists():
            return {}
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            self.logger.error(f"Erreur lors du chargement des associations: {e}")
            return {}
