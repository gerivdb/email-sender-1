=== Test de l'évaluation de la résolution avec binning uniforme ===

Évaluation pour la distribution gaussienne...

Résultats pour la distribution gaussienne:
Meilleur nombre de bins selon le score de qualité: 50
Règle de Sturges: 11 bins
Règle de Scott: 4 bins
Règle de Freedman-Diaconis: 3 bins

Largeurs de bins optimales:
Selon la règle de Sturges: 6.4491
Selon la règle de Scott: 17.7350
Selon la règle de Freedman-Diaconis: 23.6467
Selon la métrique FWHM: 1.4188
Selon la métrique de résolution relative: 4.7293

Largeurs de bins théoriques:
Pour la métrique fwhm: 11.7750
Pour la métrique slope: 7.0000
Pour la métrique curvature: 5.0000
Pour la métrique general: 5.0000

Évaluation pour la distribution bimodale...

Résultats pour la distribution bimodale:
Meilleur nombre de bins selon le score de qualité: 45
Règle de Sturges: 11 bins
Règle de Scott: 8 bins
Règle de Freedman-Diaconis: 8 bins

Comparaison entre les distributions:
Nombre optimal de bins:
Gaussienne: 50
Bimodale: 45

Résolution relative optimale:
Gaussienne: 0.3303 (avec 15 bins)
Bimodale: 0.2976 (avec 5 bins)

Conclusions:
1. Le binning uniforme est plus efficace pour la distribution gaussienne que pour la distribution bimodale
   en termes de résolution relative.
2. La règle de Scott donne généralement de bons résultats pour les distributions unimodales.
3. Pour les distributions multimodales, un nombre plus élevé de bins est souvent nécessaire
   pour capturer correctement la structure des pics.
4. La largeur optimale des bins dépend fortement de la structure de la distribution sous-jacente.

Test terminé avec succès!
Résultats sauvegardés dans les fichiers:
- uniform_binning_resolution_test_gaussian.png
- uniform_binning_resolution_test_gaussian_bin_widths.png
- uniform_binning_resolution_test_bimodal.png
- uniform_binning_resolution_test_bimodal_bin_widths.png
Help on module uniform_binning_resolution_test:

NAME
    uniform_binning_resolution_test - Test de l'évaluation de la résolution avec binning uniforme.

DATA
    bimodal_data = array([36.99677718, 34.62316841, 30.29815185, 26...7878...
    bimodal_evaluation = {'best_quality_num_bins': 45, 'bin_count_analysis...
    bimodal_optimal_bins = 5
    bimodal_optimal_resolution = 0.29759746356110095
    gaussian_data = array([54.96714153, 48.61735699, 56.47688538, 65...976...
    gaussian_evaluation = {'best_quality_num_bins': 50, 'bin_count_analysi...
    gaussian_optimal_bins = 15
    gaussian_optimal_resolution = 0.3303063033300183
    metric = 'general'
    width = 5.0

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\uniform_binning_resolution_test.py


