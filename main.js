// const { app, BrowserWindow, ipcMain, systemPreferences, shell } = require('electron');
// const { spawn } = require('child_process');
// const path = require('path');
// const fs = require('fs');

// let win;
// let recordingProcess = null;

// function createWindow() {
//     win = new BrowserWindow({
//         width: 400,
//         height: 250,
//         webPreferences: {
//             nodeIntegration: true,
//             contextIsolation: false
//         }
//     });

//     win.loadFile('index.html');
// }

// app.whenReady().then(createWindow);

// ipcMain.on('check-permission', (event) => {
//     const status = systemPreferences.getMediaAccessStatus('screen');

//     if (status !== 'granted') {
//         // Open the right macOS System Preferences pane
//         shell.openExternal('x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture');
//     }

//     event.reply('permission-status', status === 'granted');
// });

// ipcMain.on('start-recording', () => {
//     if (recordingProcess) return;

//     const outPath = path.join(__dirname, 'output.wav');
//     const binPath = path.join(__dirname, 'bin', 'audio_recorder');

//     if (!fs.existsSync(binPath)) {
//         win.webContents.send('recording-error');
//         return;
//     }

//     recordingProcess = spawn(binPath, [outPath]);

//     recordingProcess.on('close', () => {
//         win.webContents.send('recording-stopped', outPath);
//         recordingProcess = null;
//     });

//     recordingProcess.on('error', () => {
//         win.webContents.send('recording-error');
//         recordingProcess = null;
//     });
// });

// ipcMain.on('stop-recording', () => {
//     if (recordingProcess) {
//         recordingProcess.kill();
//     }
// });


const { app, BrowserWindow, ipcMain } = require('electron');
const { spawn } = require('child_process');
const path = require('path');

let win;
let recordingProcess = null;

function createWindow() {
    win = new BrowserWindow({
        width: 400,
        height: 200,
        webPreferences: { nodeIntegration: true, contextIsolation: false }
    });
    win.loadFile('index.html');
}

app.whenReady().then(createWindow);

function startRecording() {
    if (recordingProcess) return; // Prevent multiple recordings

    const outputPath = path.join(__dirname, 'recordings', `recording_${Date.now()}.wav`);
    const cliPath = path.join(__dirname, 'bin', 'audio_recorder');

    recordingProcess = spawn(cliPath, [outputPath]);

    recordingProcess.stdout.on('data', (data) => {
        console.log(`CLI: ${data}`);
        win.webContents.send('recording-status', 'Recording...');
    });

    recordingProcess.on('error', (err) => {
        console.error(`Error: ${err}`);
        win.webContents.send('recording-status', 'Error occurred');
        recordingProcess = null;
    });

    recordingProcess.on('close', () => {
        win.webContents.send('recording-status', `Saved to ${outputPath}`);
        recordingProcess = null;
    });
}

function stopRecording() {
    if (recordingProcess) {
        recordingProcess.kill();
    }
}

ipcMain.on('start-recording', startRecording);
ipcMain.on('stop-recording', stopRecording);