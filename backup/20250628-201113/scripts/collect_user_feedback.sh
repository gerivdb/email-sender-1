#!/bin/bash
mkdir -p docs # Ensure the docs directory exists
echo "# Feedback utilisateur read_file" > docs/read_file_user_feedback.md
read -p "Nom utilisateur : " user
read -p "Feedback : " feedback
echo "- Utilisateur : $user" >> docs/read_file_user_feedback.md
echo "- Feedback : $feedback" >> docs/read_file_user_feedback.md
