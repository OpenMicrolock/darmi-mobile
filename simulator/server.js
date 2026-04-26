import express from 'express';

const app = express();
const PORT = process.env.PORT || 1212;

const VALID_TOKEN = 'demo-token';
let lockState = 'locked';
let hideSsidInApMode = false;

app.use(express.json());

function isAuthorized(req) {
  return req.body?.token && req.body.token === VALID_TOKEN;
}

app.get('/', (req, res) => {
  console.log(`[PING] Health check request`);
  res.json({
    name: 'microlock-simulator',
    ip: '192.168.4.1',
    uptime_ms: process.uptime() * 1000,
    hide_ssid_in_ap_mode: hideSsidInApMode,
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

app.post('/config/status', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  console.log(`[CONFIG] Current hide_ssid_in_ap_mode: ${hideSsidInApMode}`);
  res.json({ hide_ssid_in_ap_mode: hideSsidInApMode });
});

app.post('/config', (req, res) => {
  if (!isAuthorized(req)) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  if (typeof req.body?.hide_ssid_in_ap_mode !== 'boolean') {
    return res.status(400).json({ error: 'invalid_request' });
  }

  const previousValue = hideSsidInApMode;
  hideSsidInApMode = req.body.hide_ssid_in_ap_mode;
  console.log(
    `[CONFIG] hide_ssid_in_ap_mode changed: ${previousValue} -> ${hideSsidInApMode}`,
  );
  console.log(`[CONFIG] User selected hidden SSID: ${hideSsidInApMode}`);
  res.json({
    hide_ssid_in_ap_mode: hideSsidInApMode,
    message: 'saved',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Lock Simulator running on http://0.0.0.0:${PORT}`);
  console.log(`Token: ${VALID_TOKEN}`);
});
