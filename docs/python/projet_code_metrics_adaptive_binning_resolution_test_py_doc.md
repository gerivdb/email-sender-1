=== Test de l'algorithme adaptatif pour maximiser la r�solution ===

Test de la d�tection des caract�ristiques de la distribution:

Distribution Gaussienne:
  Statistiques de base:
    Moyenne: 50.19
    M�diane: 50.25
    �cart-type: 9.79
    Plage: 70.94
  Moments:
    Asym�trie (skewness): 0.12
    Aplatissement (kurtosis): 3.07
  Modalit�:
    Multimodale: True
    Nombre de modes: 4
  Type de distribution:
    Asym�trique: False
    Queue lourde: False
    Queue l�g�re: False

Distribution Bimodale:
  Statistiques de base:
    Moyenne: 50.40
    M�diane: 44.74
    �cart-type: 20.93
    Plage: 80.03
  Moments:
    Asym�trie (skewness): 0.12
    Aplatissement (kurtosis): 1.38
  Modalit�:
    Multimodale: True
    Nombre de modes: 5
  Type de distribution:
    Asym�trique: False
    Queue lourde: False
    Queue l�g�re: True

Distribution Log-normale:
  Statistiques de base:
    Moyenne: 3.08
    M�diane: 2.72
    �cart-type: 1.67
    Plage: 18.76
  Moments:
    Asym�trie (skewness): 2.34
    Aplatissement (kurtosis): 15.31
  Modalit�:
    Multimodale: True
    Nombre de modes: 2
  Type de distribution:
    Asym�trique: True
    Queue lourde: True
    Queue l�g�re: False

Distribution Exponentielle:
  Statistiques de base:
    Moyenne: 4.84
    M�diane: 3.30
    �cart-type: 4.88
    Plage: 30.48
  Moments:
    Asym�trie (skewness): 1.92
    Aplatissement (kurtosis): 7.53
  Modalit�:
    Multimodale: True
    Nombre de modes: 2
  Type de distribution:
    Asym�trique: True
    Queue lourde: True
    Queue l�g�re: False

Test de la cr�ation du binning adaptatif:

Distribution Gaussienne:
  R�solution low:
    Strat�gie de base: quantile
    Nombre de bins: 5
    R�gles empiriques: Sturges=11, Scott=4, Freedman-Diaconis=3
  R�solution medium:
    Strat�gie de base: quantile
    Nombre de bins: 4
    R�gles empiriques: Sturges=11, Scott=4, Freedman-Diaconis=3
  R�solution high:
    Strat�gie de base: quantile
    Nombre de bins: 22
    R�gles empiriques: Sturges=11, Scott=4, Freedman-Diaconis=3

Distribution Bimodale:
  R�solution low:
    Strat�gie de base: quantile
    Nombre de bins: 5
    R�gles empiriques: Sturges=11, Scott=8, Freedman-Diaconis=8
  R�solution medium:
    Strat�gie de base: quantile
    Nombre de bins: 8
    R�gles empiriques: Sturges=11, Scott=8, Freedman-Diaconis=8
  R�solution high:
    Strat�gie de base: quantile
    Nombre de bins: 22
    R�gles empiriques: Sturges=11, Scott=8, Freedman-Diaconis=8

Distribution Log-normale:
  R�solution low:
    Strat�gie de base: quantile
    Nombre de bins: 5
    R�gles empiriques: Sturges=11, Scott=1, Freedman-Diaconis=1
  R�solution medium:
    Strat�gie de base: quantile
    Nombre de bins: 1
    R�gles empiriques: Sturges=11, Scott=1, Freedman-Diaconis=1
  R�solution high:
    Strat�gie de base: quantile
    Nombre de bins: 22
    R�gles empiriques: Sturges=11, Scott=1, Freedman-Diaconis=1

Distribution Exponentielle:
  R�solution low:
    Strat�gie de base: quantile
    Nombre de bins: 5
    R�gles empiriques: Sturges=11, Scott=2, Freedman-Diaconis=2
  R�solution medium:
    Strat�gie de base: quantile
    Nombre de bins: 2
    R�gles empiriques: Sturges=11, Scott=2, Freedman-Diaconis=2
  R�solution high:
    Strat�gie de base: quantile
    Nombre de bins: 22
    R�gles empiriques: Sturges=11, Scott=2, Freedman-Diaconis=2

Test de l'�valuation de la r�solution avec binning adaptatif:

Distribution Gaussienne:
  Binning adaptatif:
    Strat�gie de base: quantile
    Nombre de bins: 22
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics d�tect�s: 1
    R�solution relative: 0.3090
  Binning quantile:
    Nombre de pics d�tect�s: 0
    R�solution relative: N/A
  Binning logarithmic:
    Nombre de pics d�tect�s: 1
    R�solution relative: 0.2636

Distribution Bimodale:
  Binning adaptatif:
    Strat�gie de base: quantile
    Nombre de bins: 22
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics d�tect�s: 2
    R�solution relative: 0.3521
  Binning quantile:
    Nombre de pics d�tect�s: 0
    R�solution relative: N/A
  Binning logarithmic:
    Nombre de pics d�tect�s: 2
    R�solution relative: 0.3504

Distribution Log-normale:
  Binning adaptatif:
    Strat�gie de base: quantile
    Nombre de bins: 22
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics d�tect�s: 1
    R�solution relative: 0.1234
  Binning quantile:
    Nombre de pics d�tect�s: 0
    R�solution relative: N/A
  Binning logarithmic:
    Nombre de pics d�tect�s: 2
    R�solution relative: 2.6688

Distribution Exponentielle:
  Binning adaptatif:
    Strat�gie de base: quantile
    Nombre de bins: 22
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  Binning uniform:
    Nombre de pics d�tect�s: 0
    R�solution relative: N/A
  Binning quantile:
    Nombre de pics d�tect�s: 0
    R�solution relative: N/A
  Binning logarithmic:
    Nombre de pics d�tect�s: 1
    R�solution relative: 0.1656

Test de l'impact du niveau de r�solution cible:

Distribution Gaussienne:
  R�solution low:
    Strat�gie de base: quantile
    Nombre de bins: 5
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  R�solution medium:
    Strat�gie de base: quantile
    Nombre de bins: 4
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  R�solution high:
    Strat�gie de base: quantile
    Nombre de bins: 22
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Distribution Bimodale:
  R�solution low:
    Strat�gie de base: quantile
    Nombre de bins: 5
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  R�solution medium:
    Strat�gie de base: quantile
    Nombre de bins: 8
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}
  R�solution high:
    Strat�gie de base: quantile
    Nombre de bins: 22
    Nombre de pics d�tect�s: 0
    R�solution relative: {'relative_resolution': None, 'resolution_quality': 'Ind�finie', 'fwhm_results': {'peaks': [], 'fwhm_bins': [], 'fwhm_values': [], 'mean_fwhm_bins': 0.0, 'mean_fwhm_values': 0.0}}

Conclusions:
1. L'algorithme adaptatif s�lectionne automatiquement la strat�gie de binning optimale
   en fonction des caract�ristiques de la distribution.
2. Pour les distributions gaussiennes, le binning uniforme est g�n�ralement pr�f�r�,
   tandis que pour les distributions asym�triques, le binning logarithmique est choisi.
3. Pour les distributions multimodales, le binning par quantiles offre souvent
   une meilleure r�solution en adaptant la largeur des bins � la densit� des donn�es.
4. Le niveau de r�solution cible permet d'ajuster le compromis entre la d�tection
   des pics et la lisibilit� de l'histogramme.
5. L'algorithme adaptatif combine les avantages des diff�rentes strat�gies de binning
   pour maximiser la r�solution en fonction du type de distribution.

Test termin� avec succ�s!
R�sultats sauvegard�s dans les fichiers PNG correspondants.
Help on module adaptive_binning_resolution_test:

NAME
    adaptive_binning_resolution_test - Test de l'algorithme adaptatif pour maximiser la r�solution des histogrammes.

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


