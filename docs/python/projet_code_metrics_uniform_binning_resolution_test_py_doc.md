=== Test de l'�valuation de la r�solution avec binning uniforme ===

�valuation pour la distribution gaussienne...

R�sultats pour la distribution gaussienne:
Meilleur nombre de bins selon le score de qualit�: 50
R�gle de Sturges: 11 bins
R�gle de Scott: 4 bins
R�gle de Freedman-Diaconis: 3 bins

Largeurs de bins optimales:
Selon la r�gle de Sturges: 6.4491
Selon la r�gle de Scott: 17.7350
Selon la r�gle de Freedman-Diaconis: 23.6467
Selon la m�trique FWHM: 1.4188
Selon la m�trique de r�solution relative: 4.7293

Largeurs de bins th�oriques:
Pour la m�trique fwhm: 11.7750
Pour la m�trique slope: 7.0000
Pour la m�trique curvature: 5.0000
Pour la m�trique general: 5.0000

�valuation pour la distribution bimodale...

R�sultats pour la distribution bimodale:
Meilleur nombre de bins selon le score de qualit�: 45
R�gle de Sturges: 11 bins
R�gle de Scott: 8 bins
R�gle de Freedman-Diaconis: 8 bins

Comparaison entre les distributions:
Nombre optimal de bins:
Gaussienne: 50
Bimodale: 45

R�solution relative optimale:
Gaussienne: 0.3303 (avec 15 bins)
Bimodale: 0.2976 (avec 5 bins)

Conclusions:
1. Le binning uniforme est plus efficace pour la distribution gaussienne que pour la distribution bimodale
   en termes de r�solution relative.
2. La r�gle de Scott donne g�n�ralement de bons r�sultats pour les distributions unimodales.
3. Pour les distributions multimodales, un nombre plus �lev� de bins est souvent n�cessaire
   pour capturer correctement la structure des pics.
4. La largeur optimale des bins d�pend fortement de la structure de la distribution sous-jacente.

Test termin� avec succ�s!
R�sultats sauvegard�s dans les fichiers:
- uniform_binning_resolution_test_gaussian.png
- uniform_binning_resolution_test_gaussian_bin_widths.png
- uniform_binning_resolution_test_bimodal.png
- uniform_binning_resolution_test_bimodal_bin_widths.png
Help on module uniform_binning_resolution_test:

NAME
    uniform_binning_resolution_test - Test de l'�valuation de la r�solution avec binning uniforme.

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


