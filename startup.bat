@echo off
REM ShopHub E-Commerce - Quick Start Guide for Windows
REM This batch file helps you set up and run the Angular e-commerce project

echo ================================
echo ShopHub E-Commerce - Quick Start
echo ================================
echo.

REM Check if Node.js is installed
node -v >nul 2>&1
if errorlevel 1 (
    echo X Node.js is not installed. Please install Node.js v16+ from https://nodejs.org/
    pause
    exit /b 1
)

echo.
echo * Node.js version:
node -v
echo.
echo * npm version:
npm -v
echo.

REM Install dependencies
echo Installing dependencies...
echo This may take a few minutes...
echo.
call npm install

if errorlevel 1 (
    echo.
    echo X Failed to install dependencies. Please check your npm installation.
    pause
    exit /b 1
)

echo.
echo * Dependencies installed successfully!
echo.
echo Starting the development server...
echo.
echo The application will open at: http://localhost:4200
echo Press Ctrl+C to stop the server
echo.

REM Start the development server
call npm start
