#!/bin/bash
echo "# Recueil des besoins utilisateurs pour read_file" > docs/read_file_user_needs.md
read -p "Utilisateur : " user
read -p "Cas d'usage : " usecase
read -p "Limitations rencontrées : " limits
read -p "Fonctionnalités attendues : " features
read -p "Priorité : " priority
echo "- Utilisateur : $user" >> docs/read_file_user_needs.md
echo "- Cas d'usage : $usecase" >> docs/read_file_user_needs.md
echo "- Limitations rencontrées : $limits" >> docs/read_file_user_needs.md
echo "- Fonctionnalités attendues : $features" >> docs/read_file_user_needs.md
echo "- Priorité : $priority" >> docs/read_file_user_needs.md
