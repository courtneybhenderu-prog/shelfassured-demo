# Running ShelfAssured Demo Locally

This is a static HTML/JavaScript application that uses Supabase as the backend. Here are several ways to run it on your local PC:

## Option 1: Python HTTP Server (Recommended - Works on Windows)

If you have Python installed:

1. Open PowerShell or Command Prompt
2. Navigate to the project directory:
   ```powershell
   cd "c:\Users\LavanyaBhenderu\.cursor\shelfassured-demo"
   ```
3. Start the server:
   ```powershell
   # Python 3
   python -m http.server 8000
   
   # Or if python doesn't work, try:
   py -m http.server 8000
   ```
4. Open your browser and go to: `http://localhost:8000`

## Option 2: Node.js HTTP Server

If you have Node.js installed:

1. Install http-server globally (one-time setup):
   ```powershell
   npm install -g http-server
   ```
2. Navigate to the project directory:
   ```powershell
   cd "c:\Users\LavanyaBhenderu\.cursor\shelfassured-demo"
   ```
3. Start the server:
   ```powershell
   http-server -p 8000
   ```
4. Open your browser and go to: `http://localhost:8000`

## Option 3: VS Code Live Server Extension

1. Install the "Live Server" extension in VS Code
2. Right-click on `index.html`
3. Select "Open with Live Server"
4. The app will open automatically in your browser

## Option 4: Direct File Opening (Limited)

You can try opening `index.html` directly in your browser, but some features may not work due to browser security restrictions (CORS).

## Configuration

The app is already configured with Supabase credentials in:
- `shared/api.js` (hardcoded)
- `config.js` (hardcoded)

No additional configuration is needed to run the demo.

## Troubleshooting

- **Port 8000 already in use?** Use a different port (e.g., 8080, 3000) and update the URL accordingly
- **CORS errors?** Make sure you're using a local web server (Options 1-3), not opening the file directly
- **Supabase connection issues?** Check your internet connection - the app connects to Supabase cloud services

## Stopping the Server

Press `Ctrl+C` in the terminal where the server is running.
