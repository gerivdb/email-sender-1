Help on module run_testomnibus:

NAME
    run_testomnibus - TestOmnibus - Outil d'exécution et d'analyse rapide des tests Python

DESCRIPTION
    Ce script permet d'exécuter les tests Python, d'analyser les erreurs,
    et de générer des rapports détaillés pour faciliter le débogage.

FUNCTIONS
    analyze_error_trends(error_patterns)
        Analyse les tendances des erreurs.

    analyze_test_results(results)
        Analyse les résultats des tests pour identifier les patterns d'erreur.

    extract_error_details(stderr_output)
        Extrait les détails des erreurs à partir de la sortie stderr.

    find_test_files(directory, pattern)
        Trouve tous les fichiers de test correspondant au pattern.

    generate_html_report(results, analysis, report_dir)
        Génère un rapport HTML des résultats de test.

    main()
        Fonction principale.

    parse_arguments()
        Parse les arguments de ligne de commande.

    run_test_file(test_file, verbose=False, pdb=False, testmon=False, cov=False, cov_report='html', tb='auto', allure=False, allure_dir='allure-results', jenkins=False, jenkins_dir='jenkins-results')
        Exécute un fichier de test et retourne les résultats.

    run_tests_parallel(test_files, jobs, verbose=False, pdb=False, testmon=False, cov=False, cov_report='html', tb='auto', allure=False, allure_dir='allure-results', jenkins=False, jenkins_dir='jenkins-results')
        Exécute les tests en parallèle.

    save_errors_to_database(results, analysis, db_path)
        Sauvegarde les erreurs dans une base de données JSON.

    update_error_trends(error_db)
        Met à jour les tendances d'erreurs dans la base de données.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\testing\scripts\run_testomnibus.py


