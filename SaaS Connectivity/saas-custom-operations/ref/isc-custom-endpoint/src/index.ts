import express from 'express';
import apiRoutes from './routes/api.routes.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware, um JSON-Bodys zu parsen
app.use(express.json());

// Routen einbinden
app.use('/api', apiRoutes);

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

app.listen(PORT, () => {
  console.log(`🚀 SailPoint Extension Server läuft auf Port ${PORT}`);
});