=== Test de l'impact du nombre de bins sur la r�solution ===

=== Distribution: Normale ===
Nombre optimal de bins pour FWHM: 100
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 5
Nombre optimal de bins pour la r�solution relative: 15
Nombre optimal de bins pour la d�tection de pics: 100

=== Distribution: Bimodale ===
Nombre optimal de bins pour FWHM: 95
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 5
Nombre optimal de bins pour la r�solution relative: 5
Nombre optimal de bins pour la d�tection de pics: 75

=== Distribution: Trimodale ===
Nombre optimal de bins pour FWHM: 90
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 5
Nombre optimal de bins pour la r�solution relative: 70
Nombre optimal de bins pour la d�tection de pics: 90

=== Distribution: Pics rapproch�s ===
Nombre optimal de bins pour FWHM: 100
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 85
Nombre optimal de bins pour la r�solution relative: 25
Nombre optimal de bins pour la d�tection de pics: 85

=== Distribution: Hauteurs variables ===
Nombre optimal de bins pour FWHM: 95
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 5
Nombre optimal de bins pour la r�solution relative: 5
Nombre optimal de bins pour la d�tection de pics: 95

=== Test avec diff�rentes strat�gies de binning ===

Strat�gie: uniform
Nombre optimal de bins pour FWHM: 90
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 5
Nombre optimal de bins pour la r�solution relative: 70
Nombre optimal de bins pour la d�tection de pics: 90

Strat�gie: quantile
Nombre optimal de bins pour FWHM: 95
Nombre optimal de bins pour la pente: 95
Nombre optimal de bins pour la courbure: 95
Nombre optimal de bins pour la r�solution relative: 95
Nombre optimal de bins pour la d�tection de pics: 95

Strat�gie: logarithmic
Nombre optimal de bins pour FWHM: 100
Nombre optimal de bins pour la pente: 5
Nombre optimal de bins pour la courbure: 5
Nombre optimal de bins pour la r�solution relative: 85
Nombre optimal de bins pour la d�tection de pics: 100

=== Test avec une plage de bins plus fine ===
Nombre optimal de bins pour FWHM: 200
Nombre optimal de bins pour la pente: 10
Nombre optimal de bins pour la courbure: 10
Nombre optimal de bins pour la r�solution relative: 180
Nombre optimal de bins pour la d�tection de pics: 198

Test termin� avec succ�s!
Help on module bin_count_impact_test:

NAME
    bin_count_impact_test - Test de l'impact du nombre de bins sur la r�solution.

DATA
    analysis = {'max_bins': 100, 'min_bins': 5, 'optimal_num_bins': {'curv...
    bimodal_data = array([36.99677718, 34.62316841, 30.29815185, 26...7878...
    close_peaks_data = array([34.27657733, 37.41884497, 38.7591834 , ........
    data = array([31.21828612, 24.54895797, 25.072302  , .....
           62.4...
    dist_name = 'Hauteurs variables'
    distributions = {'Bimodale': array([36.99677718, 34.62316841, 30.29815...
    fine_analysis = {'max_bins': 200, 'min_bins': 10, 'optimal_num_bins': ...
    normal_data = array([54.96714153, 48.61735699, 56.47688538, 65...97686...
    optimal_bins = {'curvature': 10, 'fwhm': 200, 'relative': 180, 'slope'...
    strategies = ['uniform', 'quantile', 'logarithmic']
    strategy = 'logarithmic'
    trimodal_data = array([17.97446518, 19.56644399, 17.62274024, 19...031...
    varying_heights_data = array([31.21828612, 24.54895797, 25.072302  , ....

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\bin_count_impact_test.py


