Help on module validate_memory_schema:

NAME
    validate_memory_schema

DESCRIPTION
    Script pour valider le schéma de métadonnées des mémoires.
    Ce script vérifie que le schéma JSON est valide et conforme aux attentes.

FUNCTIONS
    create_sample_memory(schema)
        Crée un exemple de mémoire conforme au schéma.

        Args:
            schema: Le schéma JSON à utiliser.

        Returns:
            Un exemple de mémoire conforme au schéma.

    load_schema(schema_path)
        Charge le schéma JSON depuis un fichier.

        Args:
            schema_path: Chemin vers le fichier de schéma.

        Returns:
            Le schéma JSON chargé.

    main()
        Fonction principale.

    validate_memory(memory, schema)
        Valide qu'une mémoire est conforme au schéma.

        Args:
            memory: La mémoire à valider.
            schema: Le schéma JSON à utiliser.

        Returns:
            True si la mémoire est valide, False sinon.

    validate_schema(schema)
        Valide que le schéma JSON est conforme au standard JSON Schema.

        Args:
            schema: Le schéma JSON à valider.

        Returns:
            True si le schéma est valide, False sinon.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\mcp\validate_memory_schema.py


