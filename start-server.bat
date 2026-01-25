@echo off
echo Starting ShelfAssured Demo Server...
echo.
echo Choose your server option:
echo 1. Python HTTP Server (port 8000)
echo 2. Node.js HTTP Server (port 8000)
echo 3. Exit
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Starting Python HTTP Server on http://localhost:8000
    echo Press Ctrl+C to stop the server
    echo.
    python -m http.server 8000 2>nul
    if errorlevel 1 (
        py -m http.server 8000
    )
) else if "%choice%"=="2" (
    echo.
    echo Starting Node.js HTTP Server on http://localhost:8000
    echo Press Ctrl+C to stop the server
    echo.
    http-server -p 8000
) else (
    echo Exiting...
    exit /b
)
