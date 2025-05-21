const fs = require('fs');
const { execSync } = require('child_process');

// Check for required dependencies
const requiredDeps = ['saxon-js', 'axios'];

let needsInstall = false;
for (const dep of requiredDeps) {
    try {
        require(dep);
        console.log(`✅ ${dep} is already installed`);
    } catch (error) {
        console.log(`❌ ${dep} is not installed`);
        needsInstall = true;
    }
}

if (needsInstall) {
    console.log('Installing missing dependencies...');
    try {
        execSync('npm install axios', { stdio: 'inherit' });
        console.log('Dependencies installed successfully');
    } catch (error) {
        console.error('Failed to install dependencies:', error.message);
        process.exit(1);
    }
}

console.log('Setup complete. You can now run: node diggs-processor.js');
