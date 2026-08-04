import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config';
import routes from './routes';
import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import { requestLogger } from './middleware/requestLogger';
import { authRateLimiter } from './middleware/rateLimit';

const app = express();

app.set('trust proxy', config.isProduction); // correct client IPs behind Render's proxy

app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests without an Origin header (native mobile, curl, server-to-server).
    if (!origin || config.cors.origins.includes('*') || config.cors.origins.includes(origin)) {
      callback(null, true);
      return;
    }
    callback(new Error(`Origin ${origin} is not allowed by CORS`));
  },
}));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use(requestLogger);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api/auth', authRateLimiter);
app.use('/api', routes);

// Order matters: 404 handler first, then the global error handler.
app.use(notFound);
app.use(errorHandler);

const server = app.listen(config.port, () => {
  console.log(`🦾 TitanFit API running on port ${config.port} (${config.nodeEnv})`);
});

// Graceful shutdown — let in-flight requests drain, then exit.
const shutdown = (signal: string) => {
  console.log(`${signal} received, shutting down gracefully…`);
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 10_000).unref();
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

export default app;