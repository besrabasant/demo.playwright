#!/usr/bin/env sh

# Accept repo_id and build_number as command-line arguments
REPO_ID="${1:-$CI_REPO_ID}"
BUILD_NUMBER="${2:-$CI_BUILD_NUMBER}"

# Validate
if [ -z "$REPO_ID" ] || [ -z "$BUILD_NUMBER" ]; then
  echo "Error: REPO_ID and BUILD_NUMBER must be provided."
  echo "Usage: ./run_playwright.sh <repo_id> <build_number>"
  exit 1
fi

# Ensure workspace exists (Woodpecker sets CI_WORKSPACE)
WORKSPACE="${CI_WORKSPACE:-$(pwd)}"
cd "$WORKSPACE"

# Install dependencies
npm ci || yarn install || pnpm install

# Install Playwright system dependencies
npx playwright install --with-deps

# Run tests
npx playwright test --config basic/playwright.config.ts
PLAYWRIGHT_EXIT=$?

echo "Playwright exit code: $PLAYWRIGHT_EXIT"


# Show values for debugging
echo "REPO_ID=$REPO_ID"
echo "BUILD_NUMBER=$BUILD_NUMBER"

# Prepare artifacts directory (absolute + safe)
ARTIFACT_DIR="${WORKSPACE}/repos/${REPO_ID}/builds/${BUILD_NUMBER}/artifacts"
mkdir -p "$ARTIFACT_DIR"

# Copy artifacts
[ -f test-results.json ] && cp test-results.json "$ARTIFACT_DIR/summary.json"
[ -d playwright-report ] && cp -R playwright-report "$ARTIFACT_DIR/"

# Exit with Playwright’s exit code so CI reflects success/failure
exit $PLAYWRIGHT_EXIT