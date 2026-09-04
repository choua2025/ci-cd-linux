import express from 'express';

const app = express();
const PORT = process.env.PORT || 3030;

app.get('/', (req, res) => {
  res.type('text/plain').send('ci-cd-linux is running 3030🚀 healthy sucessfully running');
});

app.get('/hello', (req, res) => {
  res.type('text/plain').send('Hello world');
});

// Fallback: Express 5 no longer accepts '*' as a route path.
app.use((req, res) => {
  res.status(404).type('text/plain').send('Not Found');
});

if (import.meta.main) {
  const server = app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
  });

  // As PID 1 in a container the kernel applies no default signal disposition,
  // so these handlers are what make `docker stop` exit promptly and cleanly.
  for (const signal of ['SIGTERM', 'SIGINT']) {
    process.on(signal, () => {
      console.log(`${signal} received, shutting down`);
      server.close(() => process.exit(0));
      // Don't let a hung keep-alive connection hold the container open.
      setTimeout(() => process.exit(1), 10_000).unref();
    });
  }
}

export default app;
