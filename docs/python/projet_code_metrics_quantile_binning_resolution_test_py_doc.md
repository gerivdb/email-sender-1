=== Test de l'�valuation de la r�solution avec binning par quantiles ===

�valuation pour la distribution gaussienne...

R�sultats pour la distribution gaussienne:
Meilleur nombre de bins (quantile): 5
Meilleur nombre de bins (uniforme): 50
R�gle de Sturges: 11 bins
R�gle de Scott: 4 bins
R�gle de Freedman-Diaconis: 3 bins

�valuation pour la distribution bimodale...

R�sultats pour la distribution bimodale:
Meilleur nombre de bins (quantile): 5
Meilleur nombre de bins (uniforme): 45
R�gle de Sturges: 11 bins
R�gle de Scott: 8 bins
R�gle de Freedman-Diaconis: 8 bins

�valuation pour la distribution asym�trique (log-normale)...

R�sultats pour la distribution asym�trique (log-normale):
Meilleur nombre de bins (quantile): 5
Meilleur nombre de bins (uniforme): 10
R�gle de Sturges: 11 bins
R�gle de Scott: 1 bins
R�gle de Freedman-Diaconis: 1 bins

Comparaison entre les distributions et m�thodes de binning:

Distribution gaussienne:
R�solution relative optimale (quantile): N/A
R�solution relative optimale (uniforme): N/A

Distribution bimodale:
R�solution relative optimale (quantile): N/A
R�solution relative optimale (uniforme): N/A

Distribution asym�trique (log-normale):
R�solution relative optimale (quantile): N/A
R�solution relative optimale (uniforme): N/A

Conclusions:
1. Le binning par quantiles est particuli�rement efficace pour les distributions asym�triques
   o� il offre une meilleure r�solution que le binning uniforme.
2. Pour les distributions multimodales, le binning par quantiles permet une meilleure
   d�tection des pics en adaptant la largeur des bins � la densit� des donn�es.
3. Pour les distributions gaussiennes, le binning uniforme reste comp�titif et plus simple � interpr�ter.
4. Le nombre optimal de bins d�pend fortement de la distribution sous-jacente et
   de la m�trique de r�solution consid�r�e.

Test termin� avec succ�s!
R�sultats sauvegard�s dans les fichiers:
- quantile_binning_resolution_test_gaussian.png
- quantile_binning_resolution_test_bimodal.png
- quantile_binning_resolution_test_lognormal.png
Help on module quantile_binning_resolution_test:

NAME
    quantile_binning_resolution_test - Test de l'�valuation de la r�solution avec binning par quantiles.

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


