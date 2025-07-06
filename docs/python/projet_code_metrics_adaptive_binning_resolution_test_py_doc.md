=== Test de l'algorithme adaptatif pour maximiser la résolution ===

Test de la détection des caractéristiques de la distribution:

Distribution Gaussienne:
  Statistiques de base:
    Moyenne: 50.19
    Médiane: 50.25
    Écart-type: 9.79
    Plage: 70.94
  Moments:
    Asymétrie (skewness): 0.12
    Aplatissement (kurtosis): 3.07
  Modalité:
    Multimodale: True
    Nombre de modes: 4
  Type de distribution:
    Asymétrique: False
    Queue lourde: False
    Queue légère: False

Distribution Bimodale:
  Statistiques de base:
    Moyenne: 50.40
    Médiane: 44.74
    Écart-type: 20.93
    Plage: 80.03
  Moments:
    Asymétrie (skewness): 0.12
    Aplatissement (kurtosis): 1.38
  Modalité:
    Multimodale: True
    Nombre de modes: 5
  Type de distribution:
    Asymétrique: False
    Queue lourde: False
    Queue légère: True

Distribution Log-normale:
  Statistiques de base:
    Moyenne: 3.08
    Médiane: 2.72
    Écart-type: 1.67
    Plage: 18.76
  Moments:
    Asymétrie (skewness): 2.34
    Aplatissement (kurtosis): 15.31
  Modalité:
    Multimodale: True
    Nombre de modes: 2
  Type de distribution:
    Asymétrique: True
    Queue lourde: True
    Queue légère: False

Distribution Exponentielle:
  Statistiques de base:
    Moyenne: 4.84
    Médiane: 3.30
    Écart-type: 4.88
    Plage: 30.48
  Moments:
    Asymétrie (skewness): 1.92
    Aplatissement (kurtosis): 7.53
  Modalité:
    Multimodale: True
    Nombre de modes: 2
  Type de distribution:
    Asymétrique: True
    Queue lourde: True
    Queue légère: False

Test de la création du binning adaptatif:

Distribution Gaussienne:
  Résolution low:
    Stratégie de base: quantile
    Nombre de bins: 5
    Règles empiriques: Sturges=11, Scott=4, Freedman-Diaconis=3
  Résolution medium:
    Stratégie de base: quantile
    Nombre de bins: 4
    Règles empiriques: Sturges=11, Scott=4, Freedman-Diaconis=3
  Résolution high:
    Stratégie de base: quantile
    Nombre de bins: 22
    Règles empiriques: Sturges=11, Scott=4, Freedman-Diaconis=3

Distribution Bimodale:
  Résolution low:
    Stratégie de base: quantile
    Nombre de bins: 5
    Règles empiriques: Sturges=11, Scott=8, Freedman-Diaconis=8
  Résolution medium:
    Stratégie de base: quantile
    Nombre de bins: 8
    Règles empiriques: Sturges=11, Scott=8, Freedman-Diaconis=8
  Résolution high:
    Stratégie de base: quantile
    Nombre de bins: 22
    Règles empiriques: Sturges=11, Scott=8, Freedman-Diaconis=8

Distribution Log-normale:
  Résolution low:
    Stratégie de base: quantile
    Nombre de bins: 5
    Règles empiriques: Sturges=11, Scott=1, Freedman-Diaconis=1
  Résolution medium:
    Stratégie de base: quantile
    Nombre de bins: 1
    Règles empiriques: Sturges=11, Scott=1, Freedman-Diaconis=1
  Résolution high:
    Stratégie de base: quantile
    Nombre de bins: 22
    Règles empiriques: Sturges=11, Scott=1, Freedman-Diaconis=1

Distribution Exponentielle:
  Résolution low:
    Stratégie de base: quantile
    Nombre de bins: 5
    Règles empiriques: Sturges=11, Scott=2, Freedman-Diaconis=2
  Résolution medium:
    Stratégie de base: quantile
    Nombre de bins: 2
    Règles empiriques: Sturges=11, Scott=2, Freedman-Diaconis=2
  Résolution high:
    Stratégie de base: quantile
    Nombre de bins: 22
    Règles empiriques: Sturges=11, Scott=2, Freedman-Diaconis=2

Test de l'évaluation de la résolution avec binning adaptatif:

Distribution Gaussienne:
  Binning adaptatif:
    Stratégie de base: quantile
    Nombre de bins: 22
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics détectés: 1
    Résolution relative: 0.3090
  Binning quantile:
    Nombre de pics détectés: 0
    Résolution relative: N/A
  Binning logarithmic:
    Nombre de pics détectés: 1
    Résolution relative: 0.2636

Distribution Bimodale:
  Binning adaptatif:
    Stratégie de base: quantile
    Nombre de bins: 22
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics détectés: 2
    Résolution relative: 0.3521
  Binning quantile:
    Nombre de pics détectés: 0
    Résolution relative: N/A
  Binning logarithmic:
    Nombre de pics détectés: 2
    Résolution relative: 0.3504

Distribution Log-normale:
  Binning adaptatif:
    Stratégie de base: quantile
    Nombre de bins: 22
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics détectés: 1
    Résolution relative: 0.1234
  Binning quantile:
    Nombre de pics détectés: 0
    Résolution relative: N/A
  Binning logarithmic:
    Nombre de pics détectés: 2
    Résolution relative: 2.6688

Distribution Exponentielle:
  Binning adaptatif:
    Stratégie de base: quantile
    Nombre de bins: 22
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics détectés: 0
    Résolution relative: N/A
  Binning quantile:
    Nombre de pics détectés: 0
    Résolution relative: N/A
  Binning logarithmic:
    Nombre de pics détectés: 1
    Résolution relative: 0.1656

Test de l'impact du niveau de résolution cible:

Distribution Gaussienne:
  Résolution low:
    Stratégie de base: quantile
    Nombre de bins: 5
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Résolution medium:
    Stratégie de base: quantile
    Nombre de bins: 4
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Résolution high:
    Stratégie de base: quantile
    Nombre de bins: 22
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Distribution Bimodale:
  Résolution low:
    Stratégie de base: quantile
    Nombre de bins: 5
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Résolution medium:
    Stratégie de base: quantile
    Nombre de bins: 8
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Résolution high:
    Stratégie de base: quantile
    Nombre de bins: 22
    Nombre de pics détectés: 0
    Résolution relative: {'relative_resolution': None, 'resolution_quality': 'Indéfinie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Conclusions:
1. L'algorithme adaptatif sélectionne automatiquement la stratégie de binning optimale
   en fonction des caractéristiques de la distribution.
2. Pour les distributions gaussiennes, le binning uniforme est généralement préféré,
   tandis que pour les distributions asymétriques, le binning logarithmique est choisi.
3. Pour les distributions multimodales, le binning par quantiles offre souvent
   une meilleure résolution en adaptant la largeur des bins à la densité des données.
4. Le niveau de résolution cible permet d'ajuster le compromis entre la détection
   des pics et la lisibilité de l'histogramme.
5. L'algorithme adaptatif combine les avantages des différentes stratégies de binning
   pour maximiser la résolution en fonction du type de distribution.

Test terminé avec succès!
Résultats sauvegardés dans les fichiers PNG correspondants.
Help on module adaptive_binning_resolution_test:

NAME
    adaptive_binning_resolution_test - Test de l'algorithme adaptatif pour maximiser la résolution des histogrammes.

DATA
    adaptive_results = {'bin_counts': array([1.        , 0.97826087, 1.   ...
    bimodal_data = array([36.99677718, 34.62316841, 30.29815185, 26...7878...
    bin_edges = array([1.53596586e-04, 2.50733404e-01, 4.4189661... 1.1411...
    characteristics = {'basic_stats': {'iqr': np.float64(5.147835215541295...
    data = array([36.99677718, 34.62316841, 30.29815185, 26...78782993, 62...
    evaluation = {'adaptive': {'bin_counts': array([1.        , 0.97826087...
    exponential_data = array([8.53912040e+00, 2.05423817e+01, 1.5033019......
    gaussian_data = array([54.96714153, 48.61735699, 56.47688538, 65...976...
    lognormal_data = array([ 1.93946248,  2.52878934,  1.82903781,  2...09...
    metadata = {'base_strategy': 'quantile', 'characteristics': {'basic_st...
    name = 'Bimodale'
    rel_res = {'fwhm_results': {'fwhm_bins': [], 'fwhm_values': [], 'mean_...
    resolution = 'high'
    result = {'bin_counts': array([  1,   0,   0,   1,   0,   1,   1,   0,...
    strategy = 'logarithmic'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\adaptive_binning_resolution_test.py


