#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test avec flush de la sortie standard.
"""

import sys

print("Test avec flush de la sortie standard...")
sys.stdout.flush()

print("Cette ligne devrait s'afficher immédiatement.")
sys.stdout.flush()

print("Test terminé avec succès!")
sys.stdout.flush()
