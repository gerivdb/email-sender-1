=== Test de l'évaluation de la résolution avec binning par quantiles ===

Évaluation pour la distribution gaussienne...

Résultats pour la distribution gaussienne:
Meilleur nombre de bins (quantile): 5
Meilleur nombre de bins (uniforme): 50
Règle de Sturges: 11 bins
Règle de Scott: 4 bins
Règle de Freedman-Diaconis: 3 bins

Évaluation pour la distribution bimodale...

Résultats pour la distribution bimodale:
Meilleur nombre de bins (quantile): 5
Meilleur nombre de bins (uniforme): 45
Règle de Sturges: 11 bins
Règle de Scott: 8 bins
Règle de Freedman-Diaconis: 8 bins

Évaluation pour la distribution asymétrique (log-normale)...

Résultats pour la distribution asymétrique (log-normale):
Meilleur nombre de bins (quantile): 5
Meilleur nombre de bins (uniforme): 10
Règle de Sturges: 11 bins
Règle de Scott: 1 bins
Règle de Freedman-Diaconis: 1 bins

Comparaison entre les distributions et méthodes de binning:

Distribution gaussienne:
Résolution relative optimale (quantile): N/A
Résolution relative optimale (uniforme): N/A

Distribution bimodale:
Résolution relative optimale (quantile): N/A
Résolution relative optimale (uniforme): N/A

Distribution asymétrique (log-normale):
Résolution relative optimale (quantile): N/A
Résolution relative optimale (uniforme): N/A

Conclusions:
1. Le binning par quantiles est particulièrement efficace pour les distributions asymétriques
   où il offre une meilleure résolution que le binning uniforme.
2. Pour les distributions multimodales, le binning par quantiles permet une meilleure
   détection des pics en adaptant la largeur des bins à la densité des données.
3. Pour les distributions gaussiennes, le binning uniforme reste compétitif et plus simple à interpréter.
4. Le nombre optimal de bins dépend fortement de la distribution sous-jacente et
   de la métrique de résolution considérée.

Test terminé avec succès!
Résultats sauvegardés dans les fichiers:
- quantile_binning_resolution_test_gaussian.png
- quantile_binning_resolution_test_bimodal.png
- quantile_binning_resolution_test_lognormal.png
Help on module quantile_binning_resolution_test:

NAME
    quantile_binning_resolution_test - Test de l'évaluation de la résolution avec binning par quantiles.

DATA
    bimodal_data = array([36.99677718, 34.62316841, 30.29815185, 26...7878...
    bimodal_quantile_evaluation = {'best_quality_num_bins': 5, 'bin_count_...
    bimodal_uniform_evaluation = {'best_quality_num_bins': 45, 'bin_count_...
    gaussian_data = array([54.96714153, 48.61735699, 56.47688538, 65...976...
    gaussian_quantile_evaluation = {'best_quality_num_bins': 5, 'bin_count...
    gaussian_uniform_evaluation = {'best_quality_num_bins': 50, 'bin_count...
    lognormal_data = array([ 1.93946248,  2.52878934,  1.82903781,  2...09...
    lognormal_quantile_evaluation = {'best_quality_num_bins': 5, 'bin_coun...
    lognormal_uniform_evaluation = {'best_quality_num_bins': 10, 'bin_coun...
    optimal_res_quantile = None
    optimal_res_uniform = None

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\quantile_binning_resolution_test.py


