/**
 * ============================================================================
 * DevilConnectiond Mod Loader (v1.0.0)
 * Created by: 白猫
 * * This is a fan-made tool and is not affiliated with the original game developers.
 * Use this software at your own risk. The author is not responsible for any
 * damage to your game files or save data.
 * * Features:
 * - Auto-loads translation files (.asar) from 'plugins' folder.
 * - Supports multiple mods with priority system.
 * - Minimal modification to original game files.
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');
const electron = require('electron');

const PLUGIN_DIR_NAME = 'plugins';

let gameRoot;
const isMainProcess = (process && process.type === 'browser');

try {
    if (isMainProcess) {
        gameRoot = path.dirname(electron.app.getPath('exe'));
    } else {
        gameRoot = path.resolve(__dirname, '..', '..');
        if (!fs.existsSync(path.join(gameRoot, PLUGIN_DIR_NAME))) {
             gameRoot = path.dirname(process.execPath);
        }
    }
} catch (e) {
    gameRoot = process.cwd();
}

const pluginDirPath = path.join(gameRoot, PLUGIN_DIR_NAME);
let loadedPlugins = [];

if (fs.existsSync(pluginDirPath)) {
    try {
        const files = fs.readdirSync(pluginDirPath);
        const validItems = files.filter(item => {
            if (item.startsWith('.')) return false;
            const fullPath = path.join(pluginDirPath, item);
            try {
                const stat = fs.statSync(fullPath);
                return stat.isDirectory() || item.toLowerCase().endsWith('.asar');
            } catch(e) { return false; }
        });
        
        validItems.sort();
        validItems.reverse();

        loadedPlugins = validItems.map(item => path.join(pluginDirPath, item));
    } catch (e) {}
}

if (loadedPlugins.length > 0) {
    if (isMainProcess) {
        setupMainProcess();
    } else {
        setupRendererProcess();
    }
}

function resolveFromPlugins(relative, existsSyncFunc) {
    for (const pluginPath of loadedPlugins) {
        const tryPath = path.join(pluginPath, relative);
        if (existsSyncFunc(tryPath)) return tryPath;
    }
    return null;
}

function setupMainProcess() {
    const { app, protocol } = electron;
    applyFSHooks();

    app.whenReady().then(() => {
        protocol.interceptFileProtocol('file', (request, callback) => {
            let url = request.url.substr(8);
            url = decodeURIComponent(url);
            
            const queryIndex = url.indexOf('?');
            if (queryIndex !== -1) url = url.substring(0, queryIndex);
            
            let targetPath = path.normalize(url);
            
            if (targetPath.includes('app.asar')) {
                let relative = targetPath.substring(targetPath.indexOf('app.asar') + 'app.asar'.length);
                const found = resolveFromPlugins(relative, fs.existsSync);
                if (found) return callback({ path: found });
            }
            return callback({ path: targetPath });
        });
    });
}

function setupRendererProcess() {
    applyFSHooks();
}

function applyFSHooks() {
    const original = {
        readFileSync: fs.readFileSync,
        readFile: fs.readFile,
        existsSync: fs.existsSync,
        statSync: fs.statSync,
        lstatSync: fs.lstatSync,
        readdirSync: fs.readdirSync,
    };

    function getRealFilePath(targetPath) {
        if (typeof targetPath !== 'string') return targetPath;
        
        let relative = null;

        if (targetPath.includes('app.asar')) {
            relative = targetPath.substring(targetPath.indexOf('app.asar') + 'app.asar'.length);
        } 
        else if (!path.isAbsolute(targetPath)) {
            let cleanRel = targetPath.replace(/^(\.[\/\\])/, '');
            if (!cleanRel.startsWith('/') && !cleanRel.startsWith('\\')) cleanRel = '/' + cleanRel;
            relative = cleanRel;
        }

        if (relative) {
            const found = resolveFromPlugins(relative, original.existsSync);
            if (found) return found;
        }

        return targetPath;
    }

    fs.readFileSync = (p, o) => original.readFileSync(getRealFilePath(p), o);
    fs.readFile = (p, o, c) => { if(typeof o==='function'){c=o;o=null;} original.readFile(getRealFilePath(p), o, c); };
    fs.existsSync = (p) => original.existsSync(getRealFilePath(p));
    fs.statSync = (p, o) => original.statSync(getRealFilePath(p), o);
    fs.lstatSync = (p, o) => original.lstatSync(getRealFilePath(p), o);
    fs.readdirSync = (p, o) => original.readdirSync(getRealFilePath(p), o);
}