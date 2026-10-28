#!/usr/bin/env node

/**
 * Hyprwise Google Play Store Automated Deployment Tool
 *
 * Uploads Android App Bundle (.aab) directly to Google Play Developer API tracks:
 * - internal (Internal testing track)
 * - alpha (Closed testing track)
 * - beta (Open testing track)
 * - production (Production release track)
 *
 * Zero external dependencies: Uses standard Node.js crypto, fs, and https.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');
const { execSync } = require('child_process');

const ROOT_DIR = path.resolve(__dirname, '..');
const DEFAULT_PACKAGE_NAME = 'com.hypr.hyprwise';

// Parse command line arguments
const args = process.argv.slice(2);
function getArg(flag, defaultValue = null) {
  for (const arg of args) {
    if (arg.startsWith(`${flag}=`)) {
      return arg.split('=')[1];
    }
    if (arg === flag) {
      return true;
    }
  }
  return defaultValue;
}

const track = getArg('--track', 'internal');
const packageName = getArg('--package', DEFAULT_PACKAGE_NAME);
const checkOnly = getArg('--check-only', false);
const shouldBuild = getArg('--build', false);
const keyPathArg = getArg('--key');
const aabPathArg = getArg('--aab');

console.log('\x1b[36m\x1b[1m==========================================================\x1b[0m');
console.log('\x1b[36m\x1b[1m       Hyprwise Google Play Store Publishing Tool         \x1b[0m');
console.log('\x1b[36m\x1b[1m==========================================================\x1b[0m\n');

// 1. Locate and parse service account credentials
function loadServiceAccount() {
  const possiblePaths = [
    keyPathArg,
    path.join(ROOT_DIR, 'android', 'hyprwise-play-service-account.json'),
    path.join(ROOT_DIR, 'scripts', 'hyprwise-play-service-account.json'),
    path.join(ROOT_DIR, 'hyprwise-play-service-account.json'),
  ].filter(Boolean);

  for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
      try {
        const raw = fs.readFileSync(p, 'utf8');
        return JSON.parse(raw);
      } catch (e) {
        console.error(`\x1b[31mFailed to read service account at ${p}: ${e.message}\x1b[0m`);
      }
    }
  }

  // Check environment variables
  const envKey = process.env.PLAY_STORE_JSON_KEY || process.env.GCLOUD_SERVICE_ACCOUNT_CREDENTIALS;
  if (envKey) {
    try {
      return JSON.parse(envKey);
    } catch (_) {
      try {
        const decoded = Buffer.from(envKey, 'base64').toString('utf8');
        return JSON.parse(decoded);
      } catch (e) {
        console.error('\x1b[31mFailed to parse service account from environment variables.\x1b[0m');
      }
    }
  }

  return null;
}

const sa = loadServiceAccount();
if (!sa) {
  console.error('\x1b[31mError: Google Play Service Account JSON not found.\x1b[0m');
  console.error('Please place your credentials in android/hyprwise-play-service-account.json or set PLAY_STORE_JSON_KEY.');
  process.exit(1);
}

console.log(`• Package Name:     \x1b[33m${packageName}\x1b[0m`);
console.log(`• Release Track:    \x1b[33m${track}\x1b[0m`);
console.log(`• Service Account: \x1b[32m${sa.client_email}\x1b[0m\n`);

function base64url(str) {
  return Buffer.from(str)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

// 2. Obtain OAuth2 Access Token for Android Publisher API
async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  const tokenInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(tokenInput);
  const sig = sign.sign(sa.private_key, 'base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const jwt = `${tokenInput}.${sig}`;
  const postData = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`;

  return new Promise((resolve, reject) => {
    const req = https.request(
      'https://oauth2.googleapis.com/token',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(postData),
        },
      },
      (res) => {
        let body = '';
        res.on('data', (d) => (body += d));
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            try {
              const parsed = JSON.parse(body);
              resolve(parsed.access_token);
            } catch (err) {
              reject(new Error(`Failed to parse OAuth response: ${body}`));
            }
          } else {
            reject(new Error(`OAuth error (${res.statusCode}): ${body}`));
          }
        });
      }
    );
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function httpsRequest(url, options, data = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, headers: res.headers, body });
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function run() {
  console.log('1. Authenticating with Google OAuth...');
  let token;
  try {
    token = await getAccessToken();
    console.log('\x1b[32m✓ Google OAuth access token acquired successfully.\x1b[0m\n');
  } catch (err) {
    console.error(`\x1b[31mAuthentication failed: ${err.message}\x1b[0m`);
    process.exit(1);
  }

  console.log(`2. Validating Google Play Developer API access for ${packageName}...`);
  const editRes = await httpsRequest(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/edits`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    }
  );

  if (editRes.statusCode === 403) {
    console.error('\n\x1b[33m\x1b[1m========================================================================\x1b[0m');
    console.error('\x1b[33m\x1b[1m[ACTION REQUIRED] Google Play Console Permission Linking Needed\x1b[0m');
    console.error('\x1b[33m\x1b[1m========================================================================\x1b[0m');
    console.error(`The service account \x1b[36m${sa.client_email}\x1b[0m is active on Google Cloud,`);
    console.error('but needs to be added as an authorized user in your Google Play Console.\n');
    console.error('\x1b[1mFollow these quick steps:\x1b[0m');
    console.error('  1. Open \x1b[34mhttps://play.google.com/console\x1b[0m');
    console.error('  2. Click \x1b[1mUsers and permissions\x1b[0m in the left sidebar.');
    console.error('  3. Click \x1b[1mInvite new users\x1b[0m.');
    console.error(`  4. Enter email: \x1b[32m${sa.client_email}\x1b[0m`);
    console.error('  5. Under \x1b[1mApp permissions\x1b[0m, click \x1b[1mAdd app\x1b[0m -> Select \x1b[33mcom.hypr.hyprwise\x1b[0m.');
    console.error('  6. Check:');
    console.error('     • Release apps to testing tracks');
    console.error('     • Manage testing tracks and edit tester lists');
    console.error('     • Release to production, exclude devices, and use Play App Signing');
    console.error('     • View app information and download bulk reports');
    console.error('  7. Click \x1b[1mInvite user\x1b[0m -> \x1b[1mSend invite\x1b[0m.');
    console.error('\x1b[33m========================================================================\x1b[0m\n');
    process.exit(1);
  }

  if (editRes.statusCode < 200 || editRes.statusCode >= 300) {
    console.error(`\x1b[31mFailed to create Play Store edit (${editRes.statusCode}): ${editRes.body}\x1b[0m`);
    process.exit(1);
  }

  let editData;
  try {
    editData = JSON.parse(editRes.body);
  } catch (e) {
    console.error('Failed to parse edit response:', editRes.body);
    process.exit(1);
  }

  const editId = editData.id;
  console.log(`\x1b[32m✓ Google Play active edit session created: id=${editId}\x1b[0m\n`);

  if (checkOnly) {
    console.log('\x1b[32mVerification complete (--check-only active). Service account is fully authorized!\x1b[0m');
    process.exit(0);
  }

  // 3. Locate or build the App Bundle (.aab)
  let aabPath = aabPathArg || path.join(ROOT_DIR, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab');

  if (shouldBuild || !fs.existsSync(aabPath)) {
    console.log('3. Building release Android App Bundle (.aab) with Flutter...');
    try {
      execSync('flutter build appbundle --release --dart-define-from-file=.env', {
        cwd: ROOT_DIR,
        stdio: 'inherit',
      });
      console.log('\x1b[32m✓ App Bundle build completed!\x1b[0m\n');
    } catch (err) {
      console.error('\x1b[31mFlutter build failed!\x1b[0m');
      process.exit(1);
    }
  }

  if (!fs.existsSync(aabPath)) {
    console.error(`\x1b[31mError: App Bundle (.aab) not found at: ${aabPath}\x1b[0m`);
    console.error('Run "flutter build appbundle --release" first or pass --build flag.');
    process.exit(1);
  }

  const aabStats = fs.statSync(aabPath);
  const aabSizeMb = (aabStats.size / (1024 * 1024)).toFixed(2);
  console.log(`4. Uploading App Bundle (${aabSizeMb} MB) to Google Play...`);
  console.log(`   Path: ${aabPath}`);

  const aabBuffer = fs.readFileSync(aabPath);
  const uploadRes = await httpsRequest(
    `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${packageName}/edits/${editId}/bundles?uploadType=media`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/octet-stream',
        'Content-Length': aabBuffer.length,
      },
    },
    aabBuffer
  );

  if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
    console.error(`\x1b[31mUpload failed (${uploadRes.statusCode}): ${uploadRes.body}\x1b[0m`);
    process.exit(1);
  }

  const bundleData = JSON.parse(uploadRes.body);
  const versionCode = bundleData.versionCode;
  console.log(`\x1b[32m✓ Bundle uploaded! Version Code: ${versionCode}\x1b[0m\n`);

  // 4. Assign bundle to track
  console.log(`5. Assigning version code ${versionCode} to track "${track}"...`);
  const trackBody = JSON.stringify({
    track: track,
    releases: [
      {
        name: `Hyprwise v${versionCode}`,
        versionCodes: [versionCode.toString()],
        status: 'completed',
      },
    ],
  });

  const trackRes = await httpsRequest(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/edits/${editId}/tracks/${track}`,
    {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    },
    trackBody
  );

  if (trackRes.statusCode < 200 || trackRes.statusCode >= 300) {
    console.error(`\x1b[31mFailed to update track (${trackRes.statusCode}): ${trackRes.body}\x1b[0m`);
    process.exit(1);
  }
  console.log(`\x1b[32m✓ Track "${track}" updated with version ${versionCode}.\x1b[0m\n`);

  // 5. Commit edit
  console.log('6. Committing changes to Google Play Store...');
  const commitRes = await httpsRequest(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/edits/${editId}:commit`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    }
  );

  if (commitRes.statusCode < 200 || commitRes.statusCode >= 300) {
    console.error(`\x1b[31mCommit failed (${commitRes.statusCode}): ${commitRes.body}\x1b[0m`);
    process.exit(1);
  }

  console.log('\x1b[32m\x1b[1m==========================================================\x1b[0m');
  console.log(`\x1b[32m\x1b[1m✓ Successfully deployed Hyprwise to Google Play (${track})!\x1b[0m`);
  console.log('\x1b[32m\x1b[1m==========================================================\x1b[0m\n');
}

run().catch((err) => {
  console.error('\x1b[31mUnexpected error:\x1b[0m', err);
  process.exit(1);
});
