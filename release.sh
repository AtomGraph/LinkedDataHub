#!/usr/bin/env bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on develop branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "develop" ]; then
    print_warning "Currently on branch: $CURRENT_BRANCH"
    print_warning "It's recommended to start releases from 'develop' branch"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Aborted by user"
        exit 1
    fi
fi

# Ensure working directory is clean
if ! git diff-index --quiet HEAD --; then
    print_error "Working directory is not clean. Please commit or stash changes first."
    exit 1
fi

# Get current version from pom.xml
CURRENT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
print_status "Current version: $CURRENT_VERSION"

# Extract release version (remove -SNAPSHOT if present)
RELEASE_VERSION=${CURRENT_VERSION%-SNAPSHOT}
RELEASE_BRANCH="release/$RELEASE_VERSION"

print_status "Creating release branch: $RELEASE_BRANCH"

# Create and switch to release branch
git checkout -b "$RELEASE_BRANCH"

print_status "Starting Maven release process..."

# Configure Maven release plugin to not push changes automatically
mvn release:clean release:prepare -DpushChanges=false -DlocalCheckout=true

print_status "Performing Maven release (deploying to Sonatype)..."
mvn release:perform

# Capture the commit hashes
RELEASE_COMMIT=$(git log --oneline -2 --pretty=format:"%H" | tail -1)
SNAPSHOT_COMMIT=$(git log --oneline -1 --pretty=format:"%H")

print_status "Release commit: $RELEASE_COMMIT"
print_status "Development commit (SNAPSHOT bump): $SNAPSHOT_COMMIT"

# Switch to master and merge only the release commit
print_status "Merging release commit to master branch..."
git checkout master
git pull origin master  # Ensure master is up to date

# Merge only the release commit (not the SNAPSHOT bump)
git merge --no-ff "$RELEASE_COMMIT" -m "Release version $RELEASE_VERSION"

# Push master branch with tags
print_status "Pushing master branch and tags..."
git push origin master
git push origin --tags

# Switch to develop and merge the SNAPSHOT commit
print_status "Merging development version back to develop..."
git checkout develop
git pull origin develop  # Ensure develop is up to date

# Merge the entire release branch (including SNAPSHOT bump)
git merge --no-ff "$RELEASE_BRANCH" -m "Post-release version bump"

# Push develop branch
git push origin develop

# Clean up release branch
print_status "Cleaning up release branch..."
git branch -d "$RELEASE_BRANCH"

# Optional: delete remote release branch if it was pushed
if git ls-remote --heads origin "$RELEASE_BRANCH" | grep -q "$RELEASE_BRANCH"; then
    print_warning "Remote release branch exists. Delete it? (y/N): "
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin --delete "$RELEASE_BRANCH"
    fi
fi

print_status "Release $RELEASE_VERSION completed successfully!"
print_status "- Master branch contains release version $RELEASE_VERSION"
print_status "- Develop branch contains next development version"
print_status "- Artifacts deployed to Sonatype"

# Show final status
print_status "Current branch status:"
echo "Master: $(git log --oneline -1 master)"
echo "Develop: $(git log --oneline -1 develop)"
