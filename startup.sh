#!/bin/bash

# ShopHub E-Commerce - Quick Start Guide
# This script helps you set up and run the Angular e-commerce project

echo "================================"
echo "ShopHub E-Commerce - Quick Start"
echo "================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js v16+ from https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"
echo "✅ npm version: $(npm -v)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
echo "This may take a few minutes..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "🚀 Starting the development server..."
    echo ""
    echo "The application will open at: http://localhost:4200"
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    # Start the development server
    npm start
else
    echo "❌ Failed to install dependencies. Please check your npm installation."
    exit 1
fi
