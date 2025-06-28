#!/bin/bash
echo "# Feedback rollback" > docs/rollback_feedback.md
read -p "Nom utilisateur : " user
read -p "Feedback : " feedback
echo "- Utilisateur : $user" >> docs/rollback_feedback.md
echo "- Feedback : $feedback" >> docs/rollback_feedback.md
