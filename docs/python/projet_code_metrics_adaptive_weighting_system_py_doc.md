Help on module adaptive_weighting_system:

NAME
    adaptive_weighting_system

DESCRIPTION
    Module impl�mentant un syst�me de pond�ration adaptative selon le contexte pour
    l'�valuation de la conservation des moments statistiques dans les histogrammes de latence.

FUNCTIONS
    calculate_adaptive_weights(data, context=None, objective=None)
        Calcule les poids adaptatifs pour les moments statistiques.

        Args:
            data: Donn�es � analyser
            context: Contexte d'analyse (monitoring, stability, etc.)
            objective: Objectif d'analyse (performance, stability, etc.)

        Returns:
            weights: Vecteur de pond�ration [w\u2081, w\u2082, w\u2083, w\u2084]
            factors: Facteurs d�tect�s et utilis�s

    detect_distribution_type(data)
        D�tecte automatiquement le type de distribution.

        Args:
            data: Donn�es � analyser

        Returns:
            distribution_type: Type de distribution d�tect�
            confidence: Niveau de confiance dans la d�tection

    detect_latency_region(data)
        D�tecte la r�gion de latence.

        Args:
            data: Donn�es de latence � analyser

        Returns:
            latency_region: R�gion de latence d�tect�e
            confidence: Niveau de confiance dans la d�tection

    detect_multimodality(data, min_prominence=0.05, min_height=0.02)
        D�tecte si une distribution est multimodale.

        Args:
            data: Donn�es � analyser
            min_prominence: Pro�minence minimale pour consid�rer un pic (relatif � la hauteur max)
            min_height: Hauteur minimale pour consid�rer un pic (relatif � la hauteur max)

        Returns:
            is_multimodal: Bool�en indiquant si la distribution est multimodale
            modes: Liste des modes d�tect�s (positions)

    get_weighting_system_config()
        Retourne la configuration compl�te du syst�me de pond�ration adaptative.

        Returns:
            config: Dictionnaire de configuration

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\adaptive_weighting_system.py


