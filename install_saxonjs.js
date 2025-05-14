// install_saxon.js - Install SaxonJS 3 packages locally

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const SAXON_DIR = path.join(process.cwd(), 'saxon');

// Create directories
console.log(`Creating Saxon directory at ${SAXON_DIR}...`);
if (!fs.existsSync(SAXON_DIR)) {
    fs.mkdirSync(SAXON_DIR, { recursive: true });
}

// Create package.json for local installation
const packageJson = {
    name: "saxon-local",
    version: "1.0.0",
    description: "Local installation of SaxonJS 3",
    main: "index.js",
    dependencies: {
        "saxonjs-he": "^3.0.0-beta1",
        "xslt3-he": "^3.0.0-beta1"
    }
};

console.log('Creating package.json...');
fs.writeFileSync(
    path.join(SAXON_DIR, 'package.json'), 
    JSON.stringify(packageJson, null, 2)
);

// Install SaxonJS packages
console.log('Installing SaxonJS 3 packages (this may take a minute)...');
try {
    execSync('npm install', { 
        cwd: SAXON_DIR, 
        stdio: 'inherit' 
    });
    
    console.log('\nPackages installed successfully!');
    console.log(`SaxonJS installed at: ${SAXON_DIR}/node_modules/saxonjs-he`);
    console.log(`XSLT3 CLI installed at: ${SAXON_DIR}/node_modules/.bin/xslt3-he`);
    console.log('\nYou can now use the xsl_to_sef.js script to compile your XSL files.');
} catch (error) {
    console.error('Failed to install packages:', error.message);
    process.exit(1);
}