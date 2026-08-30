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

# Track if release completed successfully
RELEASE_SUCCESSFUL=false

# Trap handler for automatic cleanup on failure
cleanup_on_failure() {
    local exit_code=$?

    # Only clean up if release failed (non-zero exit) and wasn't successful
    if [ $exit_code -ne 0 ] && [ "$RELEASE_SUCCESSFUL" = false ]; then
        print_error "Release failed! Rolling back changes..."

        # Clean up Maven release artifacts
        mvn release:clean 2>/dev/null || true

        # Delete release tag if it exists
        if [ -n "$RELEASE_TAG" ]; then
            git tag -d "$RELEASE_TAG" 2>/dev/null || true
        fi

        # Switch back to develop branch
        git checkout develop 2>/dev/null || true

        # Delete release branch if it exists
        if [ -n "$RELEASE_BRANCH" ]; then
            git branch -D "$RELEASE_BRANCH" 2>/dev/null || true
        fi

        print_status "Rollback complete. You're back on develop branch."
        exit $exit_code
    fi
}

trap cleanup_on_failure EXIT

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

# Check if GPG is installed and configured
if ! command -v gpg &> /dev/null; then
    print_error "GPG is not installed. Maven release requires GPG to sign artifacts."
    print_error "Install GPG with: brew install gnupg"
    exit 1
fi

# Check if GPG has at least one secret key
GPG_KEYS=$(gpg --list-secret-keys --keyid-format=long 2>&1)
if ! echo "$GPG_KEYS" | grep -q "^sec"; then
    print_error "No GPG secret key found. You need a GPG key to sign Maven artifacts."
    print_error "gpg --list-secret-keys output was:"
    echo "$GPG_KEYS" >&2
    print_error "If keys exist but gpg reports a lock timeout, a stale lock is blocking it:"
    print_error "run 'gpgconf --kill all' and remove ~/.gnupg/public-keys.d/*.lock"
    print_error "Otherwise generate a key with: gpg --gen-key"
    exit 1
fi

print_status "GPG check passed"

# Set cli/pom.xml to the given version and commit it. The CLI is not a module of the platform
# reactor, so maven-release-plugin does not rewrite it - it is kept in step here instead, once for
# the release version and once for the next development version.
sync_cli_version() {
    local version="$1"

    (cd cli && mvn -B -q versions:set -DnewVersion="$version" -DgenerateBackupPoms=false)

    if git diff --quiet -- cli/pom.xml; then
        print_status "cli/pom.xml already at $version"
    else
        git add cli/pom.xml
        git commit -m "Set the CLI version to $version"
        print_status "cli/pom.xml set to $version"
    fi
}

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

# Check if release tag already exists and offer to clean up
RELEASE_TAG="linkeddatahub-$RELEASE_VERSION"
if git tag -l | grep -q "^$RELEASE_TAG$"; then
    print_warning "Release tag '$RELEASE_TAG' already exists from a previous attempt."
    print_warning "This usually means a previous release failed partway through."
    read -p "Do you want to clean up and retry? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up previous release attempt..."
        git tag -d "$RELEASE_TAG" 2>/dev/null || true
        mvn release:clean
    else
        print_error "Cannot proceed with existing release tag. Please clean up manually or use a different version."
        exit 1
    fi
fi

# Align the CLI before release:prepare, so its version is already correct in the commit that gets
# tagged - and so the two commits release:prepare adds stay the last two, which the merge below reads
# by position
sync_cli_version "$RELEASE_VERSION"

# Configure Maven release plugin to not push changes automatically
mvn release:clean release:prepare -DpushChanges=false -DlocalCheckout=true

print_status "Performing Maven release (deploying to Sonatype)..."
mvn release:perform -DlocalCheckout=true

# Capture the commit hashes
RELEASE_COMMIT=$(git log --oneline -2 --pretty=format:"%H" | tail -1)
SNAPSHOT_COMMIT=$(git log --oneline -1 --pretty=format:"%H")

print_status "Release commit: $RELEASE_COMMIT"
print_status "Development commit (SNAPSHOT bump): $SNAPSHOT_COMMIT"

# Follow the platform onto the next development version. Deliberately after the two hashes are
# captured: it adds a commit on top, and both are read by position. Master merges $RELEASE_COMMIT
# alone so it does not go there, develop merges the whole branch so it does.
NEXT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
sync_cli_version "$NEXT_VERSION"

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

# Mark release as successful to prevent rollback
RELEASE_SUCCESSFUL=true

print_status "Release $RELEASE_VERSION completed successfully!"
print_status "- Master branch contains release version $RELEASE_VERSION"
print_status "- Develop branch contains next development version"
print_status "- Artifacts deployed to Sonatype"

# Show final status
print_status "Current branch status:"
echo "Master: $(git log --oneline -1 master)"
echo "Develop: $(git log --oneline -1 develop)"