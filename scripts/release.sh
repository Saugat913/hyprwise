#!/usr/bin/env bash
# ==============================================================================
# Hyprwise Automated Release & Versioning Tool
# ==============================================================================
# Usage:
#   Interactive mode:    ./scripts/release.sh
#   Non-interactive:    ./scripts/release.sh --type=internal [--push]
#                       ./scripts/release.sh --type=production [--push]
#                       ./scripts/release.sh --type=patch [--push]
# ==============================================================================

set -euo pipefail

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT_DIR/pubspec.yaml"

echo -e "${CYAN}${BOLD}"
echo "=========================================================="
echo "          Hyprwise Release & Versioning Tool              "
echo "=========================================================="
echo -e "${NC}"

# Check environment configuration
ENV_FILE="$ROOT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$ROOT_DIR/.env.example" ]; then
    echo -e "${YELLOW}Warning: .env not found. Creating from .env.example...${NC}"
    cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  else
    echo -e "${RED}Error: .env file is missing and required for build-time configuration!${NC}"
    echo "Please create a .env file with SERVER_URL before releasing."
    exit 1
  fi
fi

# Parse CLI flags
RELEASE_TYPE=""
DO_PUSH=false
DRY_RUN=false
SKIP_TESTS=false
AUTO_CONFIRM=false

for arg in "$@"; do
  case $arg in
    --type=*)
      RELEASE_TYPE="${arg#*=}"
      ;;
    --push)
      DO_PUSH=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --skip-tests)
      SKIP_TESTS=true
      ;;
    --yes|-y)
      AUTO_CONFIRM=true
      ;;
    --help|-h)
      echo "Usage: ./scripts/release.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --type=internal     Internal Testing Release (v0.x.x, targets dev/internal)"
      echo "  --type=production   Production Release (v1.x.x, targets main/production)"
      echo "  --type=patch        Production Hotfix/Patch (v1.0.x, targets 'patch' branch, syncs with main)"
      echo "  --push              Automatically push git commit and tags to origin"
      echo "  --yes, -y           Automatically confirm and proceed without interactive prompt"
      echo "  --dry-run           Preview calculated versions without making changes"
      echo "  --skip-tests        Skip flutter analyze and test verification"
      exit 0
      ;;
  esac
done

# Check git status
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "Current branch: ${YELLOW}${CURRENT_BRANCH}${NC}"

# Fetch latest tags from remote (ignore error if no network/remote)
echo -e "Fetching latest git tags..."
git fetch --tags origin 2>/dev/null || true

# Extract current version from pubspec.yaml
CURRENT_VERSION_LINE=$(grep "^version:" "$PUBSPEC")
CURRENT_FULL_VERSION=$(echo "$CURRENT_VERSION_LINE" | awk '{print $2}')
CURRENT_VERSION_NAME=$(echo "$CURRENT_FULL_VERSION" | cut -d'+' -f1)
CURRENT_BUILD_CODE=$(echo "$CURRENT_FULL_VERSION" | cut -d'+' -f2)

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION_NAME"

echo -e "Current Pubspec Version: ${BOLD}${CURRENT_VERSION_NAME}+${CURRENT_BUILD_CODE}${NC}"

LATEST_GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "None")
echo -e "Latest Git Tag:         ${BOLD}${LATEST_GIT_TAG}${NC}\n"

# Interactive prompt if release type was not provided
if [ -z "$RELEASE_TYPE" ]; then
  echo -e "${BOLD}Select release target:${NC}"
  echo -e "  ${CYAN}[1] Internal Testing${NC}  (Play Store Internal Track · v0.x.x · Build +1)"
  echo -e "  ${GREEN}[2] Production Release${NC} (Play Store Production Track · v1.x.x · Build 100+)"
  echo -e "  ${YELLOW}[3] Production Patch${NC}   (Play Store Patch/Hotfix · targets single 'patch' branch · Build +1)"
  echo -e "  ${RED}[q] Quit${NC}"
  echo ""
  read -rp "Enter choice [1-3 or q]: " choice
  case "$choice" in
    1) RELEASE_TYPE="internal" ;;
    2) RELEASE_TYPE="production" ;;
    3) RELEASE_TYPE="patch" ;;
    q|Q) echo "Cancelled."; exit 0 ;;
    *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
  esac
fi

NEW_VERSION_NAME=""
NEW_BUILD_CODE=""
TARGET_BRANCH=""

case "$RELEASE_TYPE" in
  internal)
    TARGET_BRANCH="dev"
    # If currently on 0.x.x, increment patch, otherwise start 0.1.0
    if [[ "$MAJOR" -eq 0 ]]; then
      NEW_PATCH=$((PATCH + 1))
      NEW_VERSION_NAME="${MAJOR}.${MINOR}.${NEW_PATCH}"
    else
      NEW_VERSION_NAME="0.1.0"
    fi
    NEW_BUILD_CODE=$((CURRENT_BUILD_CODE + 1))
    ;;

  production)
    TARGET_BRANCH="main"
    # Transition to 1.0.0 if not already, else bump minor
    if [[ "$MAJOR" -eq 0 ]]; then
      NEW_VERSION_NAME="1.0.0"
      # Production builds start at 100+ for build codes
      if [[ "$CURRENT_BUILD_CODE" -lt 100 ]]; then
        NEW_BUILD_CODE=100
      else
        NEW_BUILD_CODE=$((CURRENT_BUILD_CODE + 1))
      fi
    else
      NEW_MINOR=$((MINOR + 1))
      NEW_VERSION_NAME="${MAJOR}.${NEW_MINOR}.0"
      NEW_BUILD_CODE=$((CURRENT_BUILD_CODE + 1))
    fi
    ;;

  patch)
    TARGET_BRANCH="patch"
    if [[ "$MAJOR" -eq 0 ]]; then
      NEW_VERSION_NAME="1.0.1"
      NEW_BUILD_CODE=101
    else
      NEW_PATCH=$((PATCH + 1))
      NEW_VERSION_NAME="${MAJOR}.${MINOR}.${NEW_PATCH}"
      NEW_BUILD_CODE=$((CURRENT_BUILD_CODE + 1))
    fi
    ;;

  *)
    echo -e "${RED}Unknown release type: $RELEASE_TYPE${NC}"
    exit 1
    ;;
esac

TAG_NAME="v${NEW_VERSION_NAME}"
NEW_FULL_VERSION="${NEW_VERSION_NAME}+${NEW_BUILD_CODE}"

echo ""
echo -e "${BOLD}Target Summary:${NC}"
echo -e "  Release Type:   ${CYAN}${RELEASE_TYPE}${NC}"
echo -e "  Target Branch:  ${YELLOW}${TARGET_BRANCH}${NC}"
echo -e "  New Version:    ${GREEN}${NEW_FULL_VERSION}${NC}"
echo -e "  New Git Tag:    ${GREEN}${TAG_NAME}${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}[DRY RUN] No changes written to files or git.${NC}"
  exit 0
fi

if [ "$AUTO_CONFIRM" = false ]; then
  read -rp "Proceed with this version bump and release? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# Run Quality Checks
if [ "$SKIP_TESTS" = false ]; then
  echo -e "\n${CYAN}Running quality checks (flutter analyze & flutter test)...${NC}"
  flutter analyze
  flutter test --dart-define-from-file="$ENV_FILE"
  echo -e "${GREEN}✓ Quality checks passed!${NC}\n"
else
  echo -e "${YELLOW}Skipping tests (--skip-tests active).${NC}"
fi

# Update pubspec.yaml
echo "Updating pubspec.yaml to $NEW_FULL_VERSION..."
sed -i -E "s/^version: .*/version: $NEW_FULL_VERSION/" "$PUBSPEC"

# Commit and Tag
echo "Committing version bump..."
git add "$PUBSPEC"
git commit -m "chore(release): bump version to ${TAG_NAME}+${NEW_BUILD_CODE} [${RELEASE_TYPE}]"

echo "Creating annotated git tag: ${TAG_NAME}..."
git tag -a "${TAG_NAME}" -m "Hyprwise Release ${TAG_NAME} (Build ${NEW_BUILD_CODE})"

echo -e "\n${GREEN}${BOLD}✓ Version bumped and tagged successfully!${NC}"
echo -e "  Commit: $(git rev-parse --short HEAD)"
echo -e "  Tag:    ${TAG_NAME}"

# Prompt to push to remote
if [ "$DO_PUSH" = false ]; then
  echo ""
  read -rp "Push commit and tag to origin remote now? [y/N]: " push_confirm
  if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
    DO_PUSH=true
  fi
fi

if [ "$DO_PUSH" = true ]; then
  echo -e "\nPushing branch and tags to origin..."
  git push origin "$CURRENT_BRANCH"
  git push origin "${TAG_NAME}"
  echo -e "${GREEN}${BOLD}✓ Pushed to origin! CI/CD workflow triggered.${NC}"
else
  echo -e "\n${YELLOW}To push manually later, run:${NC}"
  echo -e "  git push origin $CURRENT_BRANCH"
  echo -e "  git push origin ${TAG_NAME}"
fi
