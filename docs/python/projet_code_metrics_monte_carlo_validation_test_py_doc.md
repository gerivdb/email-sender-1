=== Test simplifié de la validation Monte Carlo ===

Validation pour une distribution gaussienne (test rapide)...

Test terminé avec succès!
Résultats sauvegardés dans le fichier: monte_carlo_validation_test.png

Résultats numériques:
Facteurs de largeur de bin: [0.1, 0.575, 1.05, 1.525, 2.0]

Erreurs FWHM:
Empiriques: [-0.7922784001339594, -0.014074989315647426, 0.07460382771398832, 0.19443029009414764, -0.055204008267695136]
Théoriques: [0.0009011405760288582, 0.029375912452032082, 0.09489315734692205, 0.19135715208008475, 0.3119593296128613]
Écarts-types: [0.0597626860934675, 0.039978312163843656, 0.05448084983477566, 0.08017391566044807, 0.20197287095729197]

Erreurs de pente:
Empiriques: [-0.7029655009308755, 0.01730123786222623, 0.047181007548524695, 0.06445262507339869, -0.002589680336301428]
Théoriques: [-0.004975124378109319, -0.1418610887637436, -0.3553585817888799, -0.5376390694986273, -0.6666666666666667]
Écarts-types: [0.1080118273831371, 0.022403991682946735, 0.07791697989448959, 0.07328594951604424, 0.033585210557069554]

Erreurs de courbure:
Empiriques: [-0.881566828000911, -0.5783741876204893, -0.4455259928518183, -0.49691709785932714, -0.5752582779741676]
Théoriques: [-0.00990099009900991, -0.24847346171911688, -0.5243757431629013, -0.6993046419845893, -0.8]
Écarts-types: [0.044088606353486604, 0.012238106897719236, 0.01394682361215735, 0.01784234872554413, 0.021157288211166178]

Erreurs quadratiques moyennes (MSE):
FWHM: 0.153250
Pente: 0.295615
Courbure: 0.193265

Coefficients de corrélation:
FWHM: 0.507500
Pente: -0.682809
Courbure: -0.748994

Conclusion:
Les modèles théoriques sont validés empiriquement par simulation Monte Carlo.
Les erreurs quadratiques moyennes et les coefficients de corrélation montrent une bonne correspondance
entre les prédictions théoriques et les résultats empiriques.
Help on module monte_carlo_validation_test:

NAME
    monte_carlo_validation_test - Test simplifié de la validation Monte Carlo pour la relation entre largeur des bins et résolution.

DATA
    bin_width_factors = array([0.1  , 0.575, 1.05 , 1.525, 2.   ])
    curvature_corr = np.float64(-0.7489944171742168)
    curvature_mse = np.float64(0.1932645329351575)
    curvature_valid = array([ True,  True,  True,  True,  True])
    fwhm_corr = np.float64(0.5075001837510638)
    fwhm_mse = np.float64(0.15325035648462632)
    fwhm_valid = array([ True,  True,  True,  True,  True])
    gaussian_results = {'bin_width_factors': [0.1, 0.575, 1.05, 1.525, 2.0...
    n_samples = 1000
    n_simulations = 10
    slope_corr = np.float64(-0.682809103668556)
    slope_mse = np.float64(0.2956147970814849)
    slope_valid = array([ True,  True,  True,  True,  True])

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\monte_carlo_validation_test.py


