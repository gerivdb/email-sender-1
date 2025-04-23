# Directives Utilisateur

## Méthodologie
- **ANALYZE**: decompose(tasks) + auto_complexity_estimation
- **LEARN**: extract_patterns(existing_code) -> accelerate_implementation
- **EXPLORE**: ToT(max_iterations=3) -> select_optimal_path
- **REASON+ACT**: ReAct(single_cycle) = analyze->execute->adjust
- **CODE**: implement(functional_units < 5KB)
- **PROGRESS**: advance_sequentially(no_confirmation_requests)
- **ADAPT**: adjust_granularity(detected_complexity)
- **SEGMENT**: auto_divide(complex_implementations)

## Standards Techniques
- **SOLID**: auto_verify(integrated_checklist)
- **TDD**: generate_tests(before_implementation)
- **MEASURE**: integrate_metrics(cyclomatic_complexity, input_size)
- **DOCUMENT**: auto_generate(code/doc_ratio=20%)
- **VALIDATE**: pre_validate(code) -> submission

## Optimisation des Entrées
- **PREVALIDATE**: measure_size([System.Text.Encoding]::UTF8.GetByteCount(), strict_limit=5KB)
- **SEGMENT**: auto_divide(if_size > 5KB, by=functional_boundaries)
- **COMPRESS**: eliminate(superfluous_comments, spaces) if necessary
- **DETECT**: implement(preventive_byte_counter) for each generation
- **PREVENT**: never_exceed(4KB_per_tool_call) to ensure safety_margin
- **INCREMENTAL**: implement(one_function_at_time) if multiple_required

## Autonomie d'Exécution
- **PROGRESSION**: chain_subtasks(without_interruption, per_roadmap)
- **DECISION**: resolve_ambiguities(predefined_heuristics, no_consultation)
- **RESILIENCE**: implement(error_recovery_mechanism, minimal_logging)
- **ESTIMATION**: calculate_complexity(LOC, dependencies, patterns)
- **RECOVERY**: auto_resume(from_last_stable_point) on failure

## Communication Optimisée
- **FORMAT**: use(predefined_structure, max_info/verbosity_ratio)
- **SYNTHESIS**: present_only(significant_changes, key_decisions)
- **METADATA**: include_metrics(completion_percentage, complexity)
- **LANGUAGE**: concise_french(algorithmic_notation) if optimization_relevant
- **FEEDBACK**: clearly_indicate(generated_input_size, validation_status)

## Exécution PowerShell
- **VERBS**: auto_validate(compliance, integrated_dictionary)
- **SIZE**: preemptively_measure([System.Text.Encoding]::UTF8.GetByteCount())
- **STRUCTURE**: generate(template_optimized_for_auto_parsing)
- **MODULARITY**: segment_functions(single_responsibility_boundaries)
- **OPTIMIZATION**: use(compact_syntax) to reduce_code_size

## Optimisation IA
- **ONE-SHOT**: provide(complete_implementations) per functional_unit
- **PROGRESSION**: auto_advance(next_step, no_confirmation)
- **METRIC**: monitor(complexity/size_ratio) to optimize_segmentation
- **ADAPTATION**: adjust_granularity(implicit_feedback, response_time)
- **SPLITTING**: proactively_divide(complex_tasks) before_failure

## Méta-Optimisation
- **LEARNING**: memorize(successful_implementation_patterns) for reuse
- **SELF-EVALUATION**: measure(execution_efficiency) and adjust_parameters
- **ANTICIPATION**: prepare(next_segments) during user_processing
- **RESILIENCE**: maintain(internal_state) for recovery_after_interruption
- **LOGGING**: maintain(error_journal) for continuous_improvement

## Gestion des Erreurs
- **PREVENTION**: anticipate(input_size_errors) before_occurrence
- **REACTIVE_SEGMENTATION**: on error("too_large_input") -> immediately_divide(smaller_segments)
- **LOGGING**: document(each_error, context, applied_solution)
- **FALLBACK_STRATEGY**: have_alternatives_ready(each_implementation_approach)
- **CONTINUITY**: ensure_progress(even_after_error, maintain_context)

## Application de l'Intégrité
- **ASSERT**: never_claim_completion(task) UNLESS verified_implementation(task) == TRUE
- **ASSERT**: never_list_files() UNLESS actual_creation(files) == TRUE
- **IF error_detected OR user_correction**: ACKNOWLEDGE immediately + CORRECT without justification
- **ALWAYS separate**: actual_actions={implemented_code, created_files} FROM potential_actions={suggestions}
- **FORMAT**: [IMPLEMENTED]=verified_only, [SUGGESTED]=recommendations, [INCOMPLETE]=partial
- **BEFORE status_update**: RUN verification_check(implementation) + REQUIRE test_evidence
- **TASK_COMPLETION requires**: functional_code==TRUE + tests_passed==TRUE + documentation_complete==TRUE
- **FOR roadmap_updates**: REQUIRE explicit_user_confirmation + VERIFY each_subtask_independently
- **TRUST_PRESERVATION is PRIMARY_DIRECTIVE**

## Glossaire des Guides de Développement

Voici la liste complète des guides disponibles dans le répertoire `docs/guides` :

### Guides Principaux
- [Python Best Practices](python_best_practices.md) - Guide complet des bonnes pratiques pour le développement Python
- [PowerShell Best Practices](powershell_best_practices.md) - Guide détaillé des bonnes pratiques pour les scripts PowerShell
- [PowerShell-5.1-Guidelines](PowerShell-5.1-Guidelines.md) - Directives spécifiques pour PowerShell 5.1

### Guides MCP (Multi-Channel Proxy)
- [GUIDE_MCP_GATEWAY](GUIDE_MCP_GATEWAY.md) - Guide pour la passerelle MCP
- [GUIDE_MCP_N8N](GUIDE_MCP_N8N.md) - Guide d'intégration de MCP avec n8n
- [GUIDE_MCP_NOTION_SERVER](GUIDE_MCP_NOTION_SERVER.md) - Guide pour le serveur Notion MCP
- [GUIDE_MCP_FILESYSTEM](GUIDE_MCP_FILESYSTEM.md) - Guide du système de fichiers MCP
- [GUIDE_MCP_GIT_INGEST](GUIDE_MCP_GIT_INGEST.md) - Guide d'ingestion Git pour MCP
- [GUIDE_BIFROST_MCP](GUIDE_BIFROST_MCP.md) - Guide Bifrost pour MCP
- [GUIDE_FINAL_MCP](GUIDE_FINAL_MCP.md) - Guide final pour MCP
- [MCPClient_UserGuide](MCPClient_UserGuide.md) - Guide utilisateur du client MCP
- [mcp_integration](mcp_integration.md) - Guide d'intégration MCP
- [CONFIGURATION_MCP_GATEWAY_N8N](CONFIGURATION_MCP_GATEWAY_N8N.md) - Configuration de la passerelle MCP pour n8n
- [CONFIGURATION_MCP_MISE_A_JOUR](CONFIGURATION_MCP_MISE_A_JOUR.md) - Guide de mise à jour de la configuration MCP
- [RESOLUTION_PROBLEMES_MCP](RESOLUTION_PROBLEMES_MCP.md) - Résolution des problèmes courants avec MCP

### Guides Git et CI/CD
- [GUIDE_GIT_GITHUB](GUIDE_GIT_GITHUB.md) - Guide d'utilisation de Git et GitHub
- [GUIDE_BONNES_PRATIQUES_GIT](GUIDE_BONNES_PRATIQUES_GIT.md) - Bonnes pratiques pour Git
- [GUIDE_HOOKS_GIT](GUIDE_HOOKS_GIT.md) - Guide pour les hooks Git
- [GUIDE_INTEGRATION_CI_CD](GUIDE_INTEGRATION_CI_CD.md) - Guide d'intégration CI/CD

### Guides n8n
- [GUIDE_DOSSIER_N8N](GUIDE_DOSSIER_N8N.md) - Guide d'organisation des dossiers n8n
- [DEMARRER_N8N_LOCAL](DEMARRER_N8N_LOCAL.md) - Guide pour démarrer n8n en local

### Guides d'Organisation et de Gestion
- [GUIDE_ORGANISATION_AUTOMATIQUE](GUIDE_ORGANISATION_AUTOMATIQUE.md) - Guide d'organisation automatique
- [GUIDE_ORGANISATION_AUTOMATIQUE_MISE_A_JOUR](GUIDE_ORGANISATION_AUTOMATIQUE_MISE_A_JOUR.md) - Mise à jour du guide d'organisation automatique
- [GUIDE_NOUVELLES_FONCTIONNALITES](GUIDE_NOUVELLES_FONCTIONNALITES.md) - Guide pour les nouvelles fonctionnalités
- [GUIDE_INSTALLATION_COMPLET](GUIDE_INSTALLATION_COMPLET.md) - Guide d'installation complet

### Guides Techniques
- [dependency_management](dependency_management.md) - Gestion des dépendances
- [DependencyCycleResolver_UserGuide](DependencyCycleResolver_UserGuide.md) - Guide utilisateur pour la résolution des cycles de dépendances
- [cycle_detection](cycle_detection.md) - Détection des cycles
- [input_segmentation](input_segmentation.md) - Segmentation des entrées
- [BONNES_PRATIQUES_CHEMINS](BONNES_PRATIQUES_CHEMINS.md) - Bonnes pratiques pour la gestion des chemins
- [GUIDE_GESTION_CARACTERES_ACCENTES](GUIDE_GESTION_CARACTERES_ACCENTES.md) - Gestion des caractères accentués

### Guides Augment
- [augment_dialog_management](augment_dialog_management.md) - Gestion des dialogues Augment
- [augment_vscode_guidelines](augment_vscode_guidelines.md) - Directives VSCode pour Augment

### Guides de Test et d'Intégration
- [instructions_test_integration](instructions_test_integration.md) - Instructions pour les tests d'intégration
- [auto_confirm_keep_all](auto_confirm_keep_all.md) - Guide pour la confirmation automatique

### Autres Guides
- [getting_started](getting_started.md) - Guide de démarrage
- [index](index.md) - Index des guides
- [template](template.md) - Modèle de guide
- [programmation_16_bases](programmation_16_bases.md) - Les 16 bases de la programmation

Ces guides contiennent des informations essentielles sur la structure de projet, les conventions de codage, la gestion des erreurs, la sécurité, et d'autres aspects importants du développement.
