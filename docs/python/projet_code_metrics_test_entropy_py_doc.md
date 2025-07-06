=== Test des métriques basées sur l'entropie ===

1. Test du calcul de l'entropie de Shannon
Entropie de Shannon: 1.8464 bits

2. Test du calcul de l'entropie d'un histogramme
Distribution normale: 3.5115 bits
Distribution asymétrique: 3.5498 bits
Distribution bimodale: 3.8784 bits

Test terminé avec succès!
Help on module test_entropy:

NAME
    test_entropy - Test direct des métriques basées sur l'entropie.

FUNCTIONS
    calculate_shannon_entropy(probabilities, base=2.0)
        # Fonction pour calculer l'entropie de Shannon

DATA
    bin_counts = array([  6,  31,  63, 117, 129,  86,  58,  13,  ...,  87,...
    data = array([ 73.93797298,  50.72327421,  67.21116606,...5239 , 103.1...
    data_asymmetric = array([ 56.66685669,  44.79498834,  27.65232722,...9...
    data_bimodal = array([ 73.93797298,  50.72327421,  67.21116606,...5239...
    data_normal = array([107.4507123 ,  97.92603548, 109.71532807,...2979 ...
    entropy = np.float64(3.878385803066775)
    name = 'bimodale'
    probabilities = array([0.006, 0.031, 0.063, 0.117, 0.129, 0.086,...0.0...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\test_entropy.py


