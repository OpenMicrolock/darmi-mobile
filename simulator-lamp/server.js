import express from 'express';
import os from 'node:os';

const app = express();
const PORT = process.env.PORT || 1212;

const VALID_TOKEN = process.env.MICROLOCK_TOKEN || 'demo-token';
const DEVICE_NAME =
  process.env.MICROLOCK_NAME || `lamp-sim-${process.pid}`;
const AP_IP = process.env.MICROLOCK_AP_IP || detectLocalIpv4() || '127.0.0.1';
const STA_IP = process.env.MICROLOCK_STA_IP || '192.168.1.78';

let lightState = 'off';
let deviceConfig = {
  apSsid: process.env.MICROLOCK_AP_SSID || 'Microlock',
  apPassword: process.env.MICROLOCK_AP_PASSWORD || '1samapai8',
};

const startTime = Date.now();

app.use(express.json());

function isAuthorized(req) {
  return req.body?.token && req.body.token === VALID_TOKEN;
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

function currentMode() {
  return 'ap';
}

function currentIp() {
  return AP_IP;
}

app.get('/', (req, res) => {
  console.log(`[PING] Health check request`);
  res.json({
    name: DEVICE_NAME,
    device_type: 'lamp',
    mode: currentMode(),
    ip: currentIp(),
    uptime_ms: Date.now() - startTime,
  });
});

app.post('/on', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  lightState = 'on';
  console.log(`[STATE] Light changed to: ${lightState}`);
  res.json({ state: lightState });
});

app.post('/off', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  lightState = 'off';
  console.log(`[STATE] Light changed to: ${lightState}`);
  res.json({ state: lightState });
});

app.post('/toggle', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  lightState = lightState === 'on' ? 'off' : 'on';
  console.log(`[STATE] Light toggled to: ${lightState}`);
  res.json({ state: lightState });
});

app.post('/status', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  console.log(`[STATUS] Current light state: ${lightState}`);
  res.json({
    state: lightState,
    uptime_ms: Date.now() - startTime,
  });
});

app.post('/config/status', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  res.json({
    wifi_mode: currentMode(),
    ip: currentIp(),
    ssid: deviceConfig.apSsid,
  });
});

app.post('/config', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  const body = req.body ?? {};

  if (body.ap_ssid !== undefined && typeof body.ap_ssid !== 'string') {
    return res
      .status(400)
      .json({ error: 'invalid_request', field: 'ap_ssid', reason: 'must be a string' });
  }
  if (body.ap_password !== undefined && typeof body.ap_password !== 'string') {
    return res
      .status(400)
      .json({ error: 'invalid_request', field: 'ap_password', reason: 'must be a string' });
  }

  deviceConfig = {
    ...deviceConfig,
    ...(body.ap_ssid !== undefined ? { apSsid: body.ap_ssid } : {}),
    ...(body.ap_password !== undefined ? { apPassword: body.ap_password } : {}),
  };

  console.log('[CONFIG] Updated config', deviceConfig);
  res.json({
    message: 'config changes require flash update',
    note: 'edit src/main.cpp and reflash',
    ap_ssid: deviceConfig.apSsid,
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Lamp Simulator running on http://0.0.0.0:${PORT}`);
  console.log(`Token: ${VALID_TOKEN}`);
  console.log('Config:', deviceConfig);
});
