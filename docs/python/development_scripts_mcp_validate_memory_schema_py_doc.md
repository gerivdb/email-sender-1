Help on module validate_memory_schema:

NAME
    validate_memory_schema

DESCRIPTION
    Script pour valider le sch�ma de m�tadonn�es des m�moires.
    Ce script v�rifie que le sch�ma JSON est valide et conforme aux attentes.

FUNCTIONS
    create_sample_memory(schema)
        Cr�e un exemple de m�moire conforme au sch�ma.

        Args:
            schema: Le sch�ma JSON � utiliser.

        Returns:
            Un exemple de m�moire conforme au sch�ma.

    load_schema(schema_path)
        Charge le sch�ma JSON depuis un fichier.

        Args:
            schema_path: Chemin vers le fichier de sch�ma.

        Returns:
            Le sch�ma JSON charg�.

    main()
        Fonction principale.

    validate_memory(memory, schema)
        Valide qu'une m�moire est conforme au sch�ma.

        Args:
            memory: La m�moire � valider.
            schema: Le sch�ma JSON � utiliser.

        Returns:
            True si la m�moire est valide, False sinon.

    validate_schema(schema)
        Valide que le sch�ma JSON est conforme au standard JSON Schema.

        Args:
            schema: Le sch�ma JSON � valider.

        Returns:
            True si le sch�ma est valide, False sinon.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\mcp\validate_memory_schema.py


