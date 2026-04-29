import express from 'express';
import os from 'node:os';
import { randomUUID } from 'node:crypto';

const app = express();
const PORT = process.env.PORT || 1212;

const VALID_TOKEN = process.env.MICROLOCK_TOKEN || 'demo-token';
const DEVICE_NAME =
  process.env.MICROLOCK_NAME || `microlock-sim-${process.pid}`;
const AP_IP = process.env.MICROLOCK_AP_IP || detectLocalIpv4() || '127.0.0.1';
const STA_IP = process.env.MICROLOCK_STA_IP || '192.168.1.77';

let lockState = 'locked';
let deviceConfig = {
  wifiSsid: process.env.MICROLOCK_WIFI_SSID || '',
  wifiPassword: process.env.MICROLOCK_WIFI_PASSWORD || '',
  apSsid: process.env.MICROLOCK_AP_SSID || buildDefaultApSsid(),
  apPassword: process.env.MICROLOCK_AP_PASSWORD || buildDefaultApPassword(),
  apBroadcastSsid: parseBoolean(
    process.env.MICROLOCK_AP_BROADCAST_SSID,
    true,
  ),
};

app.use(express.json());

function isAuthorized(req) {
  return req.body?.token && req.body.token === VALID_TOKEN;
}

function parseBoolean(value, fallback) {
  if (value === undefined) return fallback;
  if (value === 'true') return true;
  if (value === 'false') return false;
  return fallback;
}

function detectLocalIpv4() {
  const interfaces = os.networkInterfaces();
  for (const entries of Object.values(interfaces)) {
    for (const entry of entries ?? []) {
      if (entry?.family === 'IPv4' && !entry.internal) {
        return entry.address;
      }
    }
  }

  return null;
}

function buildDefaultApSsid() {
  return `microlock-sim-${randomUUID().slice(0, 8)}`;
}

function buildDefaultApPassword() {
  return `setup-${randomUUID().replace(/-/g, '').slice(0, 12)}`;
}

function normalizeConfig() {
  if (!deviceConfig.apSsid) {
    deviceConfig.apSsid = buildDefaultApSsid();
  }

  if (!deviceConfig.wifiSsid) {
    deviceConfig.wifiPassword = '';
  }
}

function currentMode() {
  return deviceConfig.wifiSsid ? 'sta' : 'ap';
}

function currentIp() {
  return currentMode() === 'sta' ? STA_IP : AP_IP;
}

function configSummary() {
  return {
    name: DEVICE_NAME,
    mode: currentMode(),
    ip: currentIp(),
    wifi: {
      ssid: deviceConfig.wifiSsid,
      configured: Boolean(deviceConfig.wifiSsid),
      has_password: Boolean(deviceConfig.wifiPassword),
    },
    ap: {
      ssid: deviceConfig.apSsid,
      broadcast_ssid: deviceConfig.apBroadcastSsid,
      has_password: Boolean(deviceConfig.apPassword),
    },
  };
}

app.get('/', (req, res) => {
  console.log(`[PING] Health check request`);
  res.json({
    name: DEVICE_NAME,
    mode: currentMode(),
    ip: currentIp(),
    uptime_ms: process.uptime() * 1000,
    wifi_configured: Boolean(deviceConfig.wifiSsid),
  });
});

app.post('/lock', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  lockState = 'locked';
  console.log(`[STATE] Lock state changed to: ${lockState}`);
  res.json({ state: lockState });
});

app.post('/unlock', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  lockState = 'unlocked';
  console.log(`[STATE] Lock state changed to: ${lockState}`);
  res.json({ state: lockState });
});

app.post('/status', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  console.log(`[STATUS] Current lock state: ${lockState}`);
  res.json({ state: lockState });
});

app.get('/config', (req, res) => {
  console.log(`[CONFIG] Returning current provisioning summary`);
  res.json(configSummary());
});

app.post('/config', (req, res) => {
  const body = req.body ?? {};

  if (body.wifi_ssid !== undefined && typeof body.wifi_ssid !== 'string') {
    return res
      .status(400)
      .json({ error: 'invalid_config', field: 'wifi_ssid', reason: 'must be a string' });
  }

  if (
    body.wifi_password !== undefined &&
    typeof body.wifi_password !== 'string'
  ) {
    return res.status(400).json({
      error: 'invalid_config',
      field: 'wifi_password',
      reason: 'must be a string',
    });
  }

  if (body.ap_ssid !== undefined && typeof body.ap_ssid !== 'string') {
    return res
      .status(400)
      .json({ error: 'invalid_config', field: 'ap_ssid', reason: 'must be a string' });
  }

  if (body.ap_password !== undefined && typeof body.ap_password !== 'string') {
    return res.status(400).json({
      error: 'invalid_config',
      field: 'ap_password',
      reason: 'must be a string',
    });
  }

  if (
    body.ap_broadcast_ssid !== undefined &&
    typeof body.ap_broadcast_ssid !== 'boolean'
  ) {
    return res.status(400).json({
      error: 'invalid_config',
      field: 'ap_broadcast_ssid',
      reason: 'must be a boolean',
    });
  }

  if (
    typeof body.ap_password === 'string' &&
    body.ap_password.length > 0 &&
    body.ap_password.length < 8
  ) {
    return res.status(400).json({
      error: 'invalid_config',
      field: 'ap_password',
      reason: 'must be at least 8 characters or empty',
    });
  }

  deviceConfig = {
    ...deviceConfig,
    ...(body.wifi_ssid !== undefined ? { wifiSsid: body.wifi_ssid } : {}),
    ...(body.wifi_password !== undefined
      ? { wifiPassword: body.wifi_password }
      : {}),
    ...(body.ap_ssid !== undefined ? { apSsid: body.ap_ssid } : {}),
    ...(body.ap_password !== undefined ? { apPassword: body.ap_password } : {}),
    ...(body.ap_broadcast_ssid !== undefined
      ? { apBroadcastSsid: body.ap_broadcast_ssid }
      : {}),
  };

  normalizeConfig();

  console.log('[CONFIG] Updated provisioning config', deviceConfig);
  res.json({
    saved: true,
    reconfigure_pending: true,
    requested_mode: currentMode(),
    ...configSummary(),
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Lock Simulator running on http://0.0.0.0:${PORT}`);
  console.log(`Token: ${VALID_TOKEN}`);
  console.log('Provisioning config:', configSummary());
});
