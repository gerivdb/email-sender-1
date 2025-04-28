#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de traduction de fichiers texte de l'anglais vers le français
avec préservation des éléments techniques comme les noms de fichiers.
"""

import argparse
import re
import time
import logging
from typing import List, Dict, Tuple, Set, Optional
from googletrans import Translator

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class TraducteurFichier:
    """Classe pour traduire des fichiers texte avec préservation d'éléments techniques."""
    
    def __init__(self, src='en', dest='fr', max_retries=3, delay_between_retries=2):
        """
        Initialise le traducteur.
        
        Args:
            src: Langue source (défaut: 'en')
            dest: Langue cible (défaut: 'fr')
            max_retries: Nombre maximum de tentatives en cas d'échec (défaut: 3)
            delay_between_retries: Délai entre les tentatives en secondes (défaut: 2)
        """
        self.traducteur = Translator()
        self.src = src
        self.dest = dest
        self.max_retries = max_retries
        self.delay = delay_between_retries
        
        # Motifs par défaut à ne pas traduire (noms de fichiers, chemins, commandes, etc.)
        self.motifs_a_preserver = [
            r'`[^`]+`',                          # Texte entre backticks
            r'"[^"]*\.(py|txt|md|json|html)"',   # Noms de fichiers entre guillemets
            r"'[^']*\.(py|txt|md|json|html)'",   # Noms de fichiers entre apostrophes
            r'[a-zA-Z0-9_\-\.]+\.(py|txt|md|json|html|js|css)',  # Noms de fichiers
            r'[\/\\][a-zA-Z0-9_\-\.\/\\]+',      # Chemins de fichiers
            r'pip install .+',                   # Commandes pip
            r'import [a-zA-Z0-9_\.]+',           # Instructions import
            r'from [a-zA-Z0-9_\.]+ import',      # Instructions from import
            r'def [a-zA-Z0-9_]+\(',              # Définitions de fonctions
            r'class [a-zA-Z0-9_]+',              # Définitions de classes
            r'[a-zA-Z0-9_]+\([^\)]*\)',          # Appels de fonctions
            r'http[s]?://[^\s]+',                # URLs
        ]
        
    def ajouter_motif(self, motif: str) -> None:
        """
        Ajoute un motif regex à préserver lors de la traduction.
        
        Args:
            motif: Expression régulière définissant le motif à préserver
        """
        self.motifs_a_preserver.append(motif)
        
    def _extraire_elements_a_preserver(self, texte: str) -> Tuple[str, Dict[str, str]]:
        """
        Extrait les éléments à préserver et les remplace par des marqueurs.
        
        Args:
            texte: Texte à traiter
            
        Returns:
            Tuple contenant le texte modifié et un dictionnaire de correspondance
        """
        elements_preserves = {}
        texte_modifie = texte
        
        # Identifier et remplacer les éléments à préserver
        for i, motif in enumerate(self.motifs_a_preserver):
            matches = re.finditer(motif, texte_modifie)
            for j, match in enumerate(matches):
                element = match.group(0)
                marqueur = f"__PRESERVE_{i}_{j}__"
                elements_preserves[marqueur] = element
                texte_modifie = texte_modifie.replace(element, marqueur, 1)
                
        return texte_modifie, elements_preserves
    
    def _restaurer_elements_preserves(self, texte: str, elements_preserves: Dict[str, str]) -> str:
        """
        Restaure les éléments préservés dans le texte traduit.
        
        Args:
            texte: Texte traduit avec marqueurs
            elements_preserves: Dictionnaire de correspondance entre marqueurs et éléments originaux
            
        Returns:
            Texte avec les éléments originaux restaurés
        """
        texte_restaure = texte
        for marqueur, element in elements_preserves.items():
            texte_restaure = texte_restaure.replace(marqueur, element)
            
        return texte_restaure
    
    def _diviser_en_blocs(self, texte: str, taille_max: int = 4000) -> List[str]:
        """
        Divise le texte en blocs pour éviter les limitations de l'API.
        
        Args:
            texte: Texte à diviser
            taille_max: Taille maximale de chaque bloc (défaut: 4000 caractères)
            
        Returns:
            Liste des blocs de texte
        """
        # Si le texte est plus court que la taille maximale, le retourner tel quel
        if len(texte) <= taille_max:
            return [texte]
        
        blocs = []
        lignes = texte.split('\n')
        bloc_courant = ""
        
        for ligne in lignes:
            # Si l'ajout de la ligne dépasse la taille maximale, commencer un nouveau bloc
            if len(bloc_courant) + len(ligne) + 1 > taille_max and bloc_courant:
                blocs.append(bloc_courant)
                bloc_courant = ligne
            else:
                # Ajouter la ligne au bloc courant
                if bloc_courant:
                    bloc_courant += '\n' + ligne
                else:
                    bloc_courant = ligne
        
        # Ajouter le dernier bloc s'il n'est pas vide
        if bloc_courant:
            blocs.append(bloc_courant)
            
        return blocs
    
    def _traduire_avec_retries(self, texte: str) -> str:
        """
        Traduit un texte avec mécanisme de réessai en cas d'échec.
        
        Args:
            texte: Texte à traduire
            
        Returns:
            Texte traduit
            
        Raises:
            Exception: Si la traduction échoue après le nombre maximum de tentatives
        """
        for tentative in range(self.max_retries):
            try:
                resultat = self.traducteur.translate(texte, src=self.src, dest=self.dest)
                return resultat.text
            except Exception as e:
                logger.warning(f"Tentative {tentative+1}/{self.max_retries} échouée: {str(e)}")
                if tentative < self.max_retries - 1:
                    logger.info(f"Nouvelle tentative dans {self.delay} secondes...")
                    time.sleep(self.delay)
                else:
                    raise Exception(f"Échec de la traduction après {self.max_retries} tentatives: {str(e)}")
    
    def traduire_texte(self, texte: str) -> str:
        """
        Traduit un texte en préservant les éléments techniques.
        
        Args:
            texte: Texte à traduire
            
        Returns:
            Texte traduit
        """
        # Extraire les éléments à préserver
        texte_modifie, elements_preserves = self._extraire_elements_a_preserver(texte)
        
        # Diviser le texte en blocs
        blocs = self._diviser_en_blocs(texte_modifie)
        
        # Traduire chaque bloc
        blocs_traduits = []
        for i, bloc in enumerate(blocs):
            logger.info(f"Traduction du bloc {i+1}/{len(blocs)} ({len(bloc)} caractères)")
            bloc_traduit = self._traduire_avec_retries(bloc)
            blocs_traduits.append(bloc_traduit)
            
        # Reconstituer le texte
        texte_traduit = '\n'.join(blocs_traduits)
        
        # Restaurer les éléments préservés
        texte_final = self._restaurer_elements_preserves(texte_traduit, elements_preserves)
        
        return texte_final
    
    def traduire_fichier(self, chemin_entree: str, chemin_sortie: str) -> None:
        """
        Traduit un fichier texte.
        
        Args:
            chemin_entree: Chemin du fichier source
            chemin_sortie: Chemin du fichier de destination
        """
        try:
            logger.info(f"Lecture du fichier {chemin_entree}")
            with open(chemin_entree, 'r', encoding='utf-8') as fichier_entree:
                texte_anglais = fichier_entree.read()
                
            logger.info(f"Début de la traduction du fichier ({len(texte_anglais)} caractères)")
            texte_francais = self.traduire_texte(texte_anglais)
            
            logger.info(f"Écriture du résultat dans {chemin_sortie}")
            with open(chemin_sortie, 'w', encoding='utf-8') as fichier_sortie:
                fichier_sortie.write(texte_francais)
                
            logger.info(f"Traduction terminée ! Le résultat est dans {chemin_sortie}")
            
        except FileNotFoundError:
            logger.error(f"Erreur : Le fichier d'entrée '{chemin_entree}' n'a pas été trouvé.")
        except Exception as e:
            logger.error(f"Une erreur s'est produite : {str(e)}")


def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    parser = argparse.ArgumentParser(description='Traduit un fichier texte de l\'anglais vers le français.')
    parser.add_argument('fichier_entree', help='Chemin du fichier à traduire')
    parser.add_argument('fichier_sortie', help='Chemin du fichier de sortie')
    parser.add_argument('--source', default='en', help='Langue source (défaut: en)')
    parser.add_argument('--dest', default='fr', help='Langue cible (défaut: fr)')
    parser.add_argument('--preserve', action='append', help='Motifs regex supplémentaires à préserver')
    parser.add_argument('--verbose', action='store_true', help='Afficher les messages de débogage')
    
    args = parser.parse_args()
    
    # Configurer le niveau de logging
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Créer et configurer le traducteur
    traducteur = TraducteurFichier(src=args.source, dest=args.dest)
    
    # Ajouter des motifs supplémentaires à préserver
    if args.preserve:
        for motif in args.preserve:
            traducteur.ajouter_motif(motif)
    
    # Traduire le fichier
    traducteur.traduire_fichier(args.fichier_entree, args.fichier_sortie)


if __name__ == "__main__":
    main()
