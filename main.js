const { app, BrowserWindow, shell, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

// Setup logging
const logPath = path.join(app.getPath('userData'), 'app.log');
function log(message) {
    try {
        fs.appendFileSync(logPath, `${new Date().toISOString()} - ${message}\n`);
    } catch (e) {
        // ignore
    }
}

// Global error handlers
process.on('uncaughtException', (error) => {
    log(`Uncaught Exception: ${error.stack}`);
    dialog.showErrorBox('Error', `An error occurred: ${error.message}`);
});

function createWindow() {
  log('Creating window...');
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      // preload: path.join(__dirname, 'preload.js') 
    },
    autoHideMenuBar: true, // Hide default menu bar
    title: "广西自动化学会会员管理系统"
  });

  // Load the index.html of the app.
  const indexPath = path.join(__dirname, 'index.html');
  log(`Loading file: ${indexPath}`);
  
  win.loadFile(indexPath).catch(e => {
      log(`Failed to load index.html: ${e}`);
  });

  // Open external links (http/https) in the default system browser
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http:') || url.startsWith('https:')) {
      shell.openExternal(url);
      return { action: 'deny' };
    }
    return { action: 'allow' };
  });
  
  // Open DevTools in development or if there is an error
  // win.webContents.openDevTools();
  
  win.on('unresponsive', () => {
      log('Window unresponsive');
  });
  
  win.webContents.on('crashed', () => {
      log('Renderer process crashed');
  });
}

app.whenReady().then(() => {
  log('App Ready');
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});