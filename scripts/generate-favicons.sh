#!/bin/bash
# Generate favicons from favicon.svg using Node.js and sharp
# Usage: ./scripts/generate-favicons.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

echo "=== Favicon Generator ==="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed."
    echo "Please install Node.js first: https://nodejs.org/"
    exit 1
fi

echo "Node.js version: $(node --version)"

# Check if source SVG exists
if [ ! -f "$PROJECT_DIR/static/favicon.svg" ]; then
    echo "ERROR: static/favicon.svg not found!"
    echo "Please ensure the source SVG exists before running this script."
    exit 1
fi

# Initialize package.json if it doesn't exist
if [ ! -f "package.json" ]; then
    echo "Creating package.json..."
    cat > package.json << 'EOF'
{
  "name": "favicon-generator",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "generate": "node generate-favicons.js"
  },
  "dependencies": {
    "sharp": "^0.33.0"
  }
}
EOF
fi

# Install dependencies if node_modules doesn't exist or sharp is missing
if [ ! -d "node_modules" ] || [ ! -d "node_modules/sharp" ]; then
    echo "Installing dependencies..."
    npm install
fi

echo ""
echo "Generating favicons..."
node generate-favicons.js

echo ""
echo "=== Done! ==="
echo "Favicons have been generated in static/"
