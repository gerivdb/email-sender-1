Help on module adaptive_weighting_system:

NAME
    adaptive_weighting_system

DESCRIPTION
    Module implémentant un système de pondération adaptative selon le contexte pour
    l'évaluation de la conservation des moments statistiques dans les histogrammes de latence.

FUNCTIONS
    calculate_adaptive_weights(data, context=None, objective=None)
        Calcule les poids adaptatifs pour les moments statistiques.

        Args:
            data: Données à analyser
            context: Contexte d'analyse (monitoring, stability, etc.)
            objective: Objectif d'analyse (performance, stability, etc.)

        Returns:
            weights: Vecteur de pondération [w\u2081, w\u2082, w\u2083, w\u2084]
            factors: Facteurs détectés et utilisés

    detect_distribution_type(data)
        Détecte automatiquement le type de distribution.

        Args:
            data: Données à analyser

        Returns:
            distribution_type: Type de distribution détecté
            confidence: Niveau de confiance dans la détection

    detect_latency_region(data)
        Détecte la région de latence.

        Args:
            data: Données de latence à analyser

        Returns:
            latency_region: Région de latence détectée
            confidence: Niveau de confiance dans la détection

    detect_multimodality(data, min_prominence=0.05, min_height=0.02)
        Détecte si une distribution est multimodale.

        Args:
            data: Données à analyser
            min_prominence: Proéminence minimale pour considérer un pic (relatif à la hauteur max)
            min_height: Hauteur minimale pour considérer un pic (relatif à la hauteur max)

        Returns:
            is_multimodal: Booléen indiquant si la distribution est multimodale
            modes: Liste des modes détectés (positions)

    get_weighting_system_config()
        Retourne la configuration complète du système de pondération adaptative.

        Returns:
            config: Dictionnaire de configuration

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\adaptive_weighting_system.py


