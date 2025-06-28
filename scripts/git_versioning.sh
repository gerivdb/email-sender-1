#!/bin/bash

# Configuration
COMMIT_MESSAGE="backup: automated commit before critical modification"
TAG_PREFIX="backup-"

# Function to perform git operations
perform_git_operations() {
    echo "Adding all changes to git..."
    git add .
    if [ $? -ne 0 ]; then
        echo "Error: git add failed."
        exit 1
    fi

    echo "Committing changes with message: '$COMMIT_MESSAGE'..."
    git commit -m "$COMMIT_MESSAGE"
    if [ $? -ne 0 ]; then
        echo "Warning: git commit failed (possibly no changes to commit)."
    fi

    TAG_NAME="${TAG_PREFIX}$(date +%Y%m%d-%H%M%S)"
    echo "Creating tag: '$TAG_NAME'..."
    git tag "$TAG_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: git tag failed."
        exit 1
    fi

    echo "Git operations completed successfully."
    echo "Remember to push tags and branches to remote: git push origin --tags && git push"
}

# Main execution
perform_git_operations
