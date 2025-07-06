=== Test de l'évaluation de la résolution avec binning logarithmique ===

Évaluation pour la distribution gaussienne...

Résultats pour la distribution gaussienne:
Meilleur nombre de bins (logarithmique): 30
Meilleur nombre de bins (uniforme): 50
Meilleur nombre de bins (quantile): 5
Règle de Sturges: 11 bins
Règle de Scott: 4 bins
Règle de Freedman-Diaconis: 3 bins

Évaluation pour la distribution asymétrique (log-normale)...

Résultats pour la distribution asymétrique (log-normale):
Meilleur nombre de bins (logarithmique): 50
Meilleur nombre de bins (uniforme): 10
Meilleur nombre de bins (quantile): 5
Règle de Sturges: 11 bins
Règle de Scott: 1 bins
Règle de Freedman-Diaconis: 1 bins

Évaluation pour la distribution exponentielle...

Résultats pour la distribution exponentielle:
Meilleur nombre de bins (logarithmique): 45
Meilleur nombre de bins (uniforme): 45
Meilleur nombre de bins (quantile): 5
Règle de Sturges: 11 bins
Règle de Scott: 2 bins
Règle de Freedman-Diaconis: 2 bins

Recherche de la stratégie optimale pour chaque distribution...

Stratégie optimale pour chaque distribution:
Gaussienne: None avec None bins
Log-normale: None avec None bins
Exponentielle: None avec None bins

Comparaison des performances des différentes stratégies:

Distribution gaussienne:
  Stratégie uniform:
    Nombre de pics détectés: 2
    Résolution relative: {'relative_resolution': 1.7301424681625164, 'resolution_quality': 'Limitée', 'mean_mode_distance': 7.093998830723798, 'fwhm_results': {'peaks': [np.float64(44.189822214523495), np.float64(51.283821045247294)], 'fwhm_bins': [8.692063963947149, 60.513634762553544], 'fwhm_values': [3.083074579840875, 21.46418271242008], 'mean_fwhm_bins': 34.60284936325034, 'mean_fwhm_values': 12.273628646130478}}
  Stratégie logarithmic:
    Nombre de pics détectés: 1
    Résolution relative: {'relative_resolution': 0.25762459218473976, 'resolution_quality': 'Excellente', 'mean_mode_distance': 70.93998830723794, 'fwhm_results': {'peaks': [np.float64(52.39881881857406)], 'fwhm_bins': [51.52491843694796], 'fwhm_values': [18.275885557242383], 'mean_fwhm_bins': 51.52491843694796, 'mean_fwhm_values': 18.275885557242383}}
  Stratégie quantile:
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Distribution log-normale:
  Stratégie uniform:
    Nombre de pics détectés: 1
    Résolution relative: {'relative_resolution': 0.10192213547892044, 'resolution_quality': 'Excellente', 'mean_mode_distance': 18.757611181708292, 'fwhm_results': {'peaks': [np.float64(2.007462909442351)], 'fwhm_bins': [20.38442709578409], 'fwhm_values': [1.9118157881229856], 'mean_fwhm_bins': 20.38442709578409, 'mean_fwhm_values': 1.9118157881229856}}
  Stratégie logarithmic:
    Nombre de pics détectés: 1
    Résolution relative: {'relative_resolution': 0.33643153712691803, 'resolution_quality': 'Excellente', 'mean_mode_distance': 18.75761118170829, 'fwhm_results': {'peaks': [np.float64(2.637891861872209)], 'fwhm_bins': [67.2863074253836], 'fwhm_values': [6.310651962691185], 'mean_fwhm_bins': 67.2863074253836, 'mean_fwhm_values': 6.310651962691185}}
  Stratégie quantile:
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Distribution exponentielle:
  Stratégie uniform:
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Stratégie logarithmic:
    Nombre de pics détectés: 1
    Résolution relative: {'relative_resolution': 0.18630150573385423, 'resolution_quality': 'Excellente', 'mean_mode_distance': 30.48261414644973, 'fwhm_results': {'peaks': [np.float64(6.945994907694681)], 'fwhm_bins': [37.26030114677084], 'fwhm_values': [5.678956914187671], 'mean_fwhm_bins': 37.26030114677084, 'mean_fwhm_values': 5.678956914187671}}
  Stratégie quantile:
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Conclusions:
1. Le binning logarithmique est particulièrement efficace pour les distributions asymétriques
   et à queue lourde comme les distributions log-normales et exponentielles.
2. Pour les distributions gaussiennes, le binning uniforme reste généralement plus efficace
   en termes de résolution et de détection des pics.
3. Le binning logarithmique offre une meilleure résolution dans les régions de faible densité
   (queues des distributions), au prix d'une résolution réduite dans les régions de forte densité.
4. Le ratio entre la largeur maximale et minimale des bins logarithmiques augmente avec le nombre
   de bins, ce qui peut affecter l'interprétation visuelle de l'histogramme.
5. Pour les distributions fortement asymétriques, le binning logarithmique peut être préférable
   même avec un nombre réduit de bins, offrant un bon compromis entre résolution et lisibilité.

Test terminé avec succès!
Résultats sauvegardés dans les fichiers PNG correspondants.
Help on module logarithmic_binning_resolution_test:

NAME
    logarithmic_binning_resolution_test - Test de l'évaluation de la résolution avec binning logarithmique.

FUNCTIONS
    simple_compare_strategies(data, strategies=None, num_bins=20)
        # Créer une fonction simplifiée pour comparer les stratégies de binning

    simple_find_optimal_strategy(data, strategies=None, num_bins_range=None)
        # Créer une fonction simplifiée pour trouver la stratégie optimale

DATA
    bimodal_data = array([36.99677718, 34.62316841, 30.29815185, 26...7878...
    exponential_comparison = {'logarithmic': {'fwhm_values': [5.6789569141...
    exponential_data = array([8.53912040e+00, 2.05423817e+01, 1.5033019......
    exponential_log_evaluation = {'best_quality_num_bins': 45, 'bin_count_...
    exponential_optimization = {'best_num_bins': None, 'best_resolution': ...
    exponential_quantile_evaluation = {'best_quality_num_bins': 5, 'bin_co...
    exponential_uniform_evaluation = {'best_quality_num_bins': 45, 'bin_co...
    gaussian_comparison = {'logarithmic': {'fwhm_values': [18.275885557242...
    gaussian_data = array([54.96714153, 48.61735699, 56.47688538, 65...976...
    gaussian_log_evaluation = {'best_quality_num_bins': 30, 'bin_count_ana...
    gaussian_optimization = {'best_num_bins': None, 'best_resolution': inf...
    gaussian_quantile_evaluation = {'best_quality_num_bins': 5, 'bin_count...
    gaussian_uniform_evaluation = {'best_quality_num_bins': 50, 'bin_count...
    lognormal_comparison = {'logarithmic': {'fwhm_values': [6.310651962691...
    lognormal_data = array([ 1.93946248,  2.52878934,  1.82903781,  2...09...
    lognormal_log_evaluation = {'best_quality_num_bins': 50, 'bin_count_an...
    lognormal_optimization = {'best_num_bins': None, 'best_resolution': in...
    lognormal_quantile_evaluation = {'best_quality_num_bins': 5, 'bin_coun...
    lognormal_uniform_evaluation = {'best_quality_num_bins': 10, 'bin_coun...
    result = {'fwhm_values': [], 'max_curvatures': [], 'max_slopes': [], '...
    strategy = 'quantile'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\logarithmic_binning_resolution_test.py


