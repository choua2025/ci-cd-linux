import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import app from '../index.js';

let server;
let baseUrl;

before(async () => {
  // Port 0 => OS assigns a free port, so tests never collide with a dev server.
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => new Promise((resolve) => server.close(resolve)));

describe('routes', () => {
  it('GET /hello returns Hello world', async () => {
    const res = await fetch(`${baseUrl}/hello`);
    assert.equal(res.status, 200);
    assert.equal(await res.text(), 'Hello world');
  });

  it('GET / returns the running message', async () => {
    const res = await fetch(`${baseUrl}/`);
    assert.equal(res.status, 200);
    // Matched on the stable prefix, not the whole string: the banner carries
    // decorative text that changes freely and shouldn't fail the build.
    assert.match(await res.text(), /^ci-cd-linux is running/);
  });

  it('unknown routes return 404', async () => {
    const res = await fetch(`${baseUrl}/nope`);
    assert.equal(res.status, 404);
  });
});
