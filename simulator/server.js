import express from 'express';

const app = express();
const PORT = process.env.PORT || 1212;

const VALID_TOKEN = 'demo-token';
let lockState = 'locked';

app.use(express.json());

app.get('/', (req, res) => {
  console.log(`[PING] Health check request`);
  res.json({ message: 'Lock API Simulator running' });
});

app.post('/lock', (req, res) => {
  const token = req.body?.token;
  if (!token || token !== VALID_TOKEN) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  lockState = 'locked';
  console.log(`[STATE] Lock state changed to: ${lockState}`);
  res.json({ state: lockState });
});

app.post('/unlock', (req, res) => {
  const token = req.body?.token;
  if (!token || token !== VALID_TOKEN) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  lockState = 'unlocked';
  console.log(`[STATE] Lock state changed to: ${lockState}`);
  res.json({ state: lockState });
});

app.post('/status', (req, res) => {
  const token = req.body?.token;
  if (!token || token !== VALID_TOKEN) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  console.log(`[STATUS] Current lock state: ${lockState}`);
  res.json({ state: lockState });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Lock Simulator running on http://0.0.0.0:${PORT}`);
  console.log(`Token: ${VALID_TOKEN}`);
});