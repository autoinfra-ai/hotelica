import { startWebSocketServer } from './websocket';
import express from 'express';
import cors from 'cors';
import http from 'http';
import routes from './routes';
import { getPort } from './config';
import logger from './utils/logger';
import client from 'prom-client';

const port = getPort();

const app = express();
const server = http.createServer(app);

// Create a Registry to register the metrics
const register = new client.Registry();

// Collect default metrics (CPU, memory, etc.)
client.collectDefaultMetrics({ register });

// Create custom metrics (e.g., HTTP request duration)
const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'code'],
  buckets: [50, 100, 200, 300, 400, 500],
});

// Register the custom metric
register.registerMetric(httpRequestDurationMicroseconds);

const corsOptions = {
  origin: '*',
};

app.use(cors(corsOptions));
app.use(express.json());

// Middleware to log every time a router is hit and measure response times
app.use((req, res, next) => {
  logger.info(`Router hit: ${req.method} ${req.url}`);
  const startEpoch = Date.now();

  res.on('finish', () => {
    const responseTimeInMs = Date.now() - startEpoch;
    httpRequestDurationMicroseconds
      .labels(req.method, req.route ? req.route.path : req.path, res.statusCode.toString())
      .observe(responseTimeInMs);
  });

  next();
});

app.use('/api', routes);
app.get('/api/health', (_, res) => {
  res.status(200).json({ status: 'ok' });
});

// Expose the metrics at '/metrics' endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  const metrics = await register.metrics();
  res.end(metrics);
});



server.listen(port, () => {
  logger.info(`Server is running on port ${port}`);
});

startWebSocketServer(server);

// Handle uncaught exceptions to prevent the application from crashing
process.on('uncaughtException', (err, origin) => {
  logger.error(`
    An uncaught exception occurred in the application.
    This is a critical error that was not handled by any try-catch block.
    
    Error details:
    - Origin: ${origin}
    - Error message: ${err.message}
    - Stack trace: ${err.stack}
    
    This error should be investigated immediately as it may indicate a serious issue in the application.
    Consider adding appropriate error handling to prevent such exceptions from occurring.
  `);
  
  // Optionally, you might want to perform cleanup operations or restart the application here
  // process.exit(1); // Uncomment this line if you want to terminate the application after logging
});

// Handle unhandled promise rejections to prevent the Node.js process from terminating
process.on('unhandledRejection', (reason, promise) => {
  logger.error(`
    An unhandled promise rejection was detected in the application.
    This means a Promise was rejected without a .catch() handler to process the error.
    
    Rejection details:
    - Promise: ${JSON.stringify(promise, null, 2)}
    - Reason: ${reason instanceof Error ? reason.stack : reason}
    
    To fix this, ensure all Promises have proper error handling with .catch() blocks or try-catch in async functions.
    Unhandled rejections can lead to memory leaks and unexpected application behavior.
  `);
  
  // Optionally, you can choose to terminate the process here
  // process.exit(1); // Uncomment this line if you want to terminate the application after logging
});
