#!/usr/bin/env node
/**
 * X Monitor Dashboard server
 * Serves the Messy Virgo X accounts dashboard and proxies twitterapi.io (keeps API key server-side).
 * Node 18+ (uses native fetch).
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.env.DASHBOARD_X_PORT || '18788', 10);
const API_KEY = process.env.XAPI_IO_API_KEY || '';
const GATEWAY_TOKEN = process.env.OPENCLAW_GATEWAY_TOKEN || '';
const GATEWAY_PORT = process.env.OPENCLAW_GATEWAY_PORT || '18789';
const WORKSPACE_DIR = process.env.WORKSPACE_DIR || '/workspace';
const BASE_URL = 'https://api.twitterapi.io';

const HANDLES = ['MEssyVirgoCoin', 'MessyVirgoBot', 'MessyVirgoF', 'MessyVirgoM'];
const MAX_TWEETS_PER_ACCOUNT = 5;
const MEMORY_DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

function serveFile(res, filePath, contentType, noStore = false) {
  const fullPath = path.join(__dirname, 'public', filePath);
  fs.readFile(fullPath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found');
      return;
    }
    const headers = { 'Content-Type': contentType };
    if (noStore) headers['Cache-Control'] = 'no-store, max-age=0';
    res.writeHead(200, headers);
    res.end(data);
  });
}

async function fetchTweets(handle) {
  if (!API_KEY) {
    return { error: 'XAPI_IO_API_KEY not configured' };
  }
  const query = encodeURIComponent(`from:${handle}`);
  const url = `${BASE_URL}/twitter/tweet/advanced_search?query=${query}&type=Latest`;
  try {
    const r = await fetch(url, {
      headers: { 'X-API-Key': API_KEY },
    });
    if (!r.ok) {
      const text = await r.text();
      return { error: `API ${r.status}: ${text.slice(0, 200)}` };
    }
    const data = await r.json();
    const tweets = (data.tweets || []).slice(0, MAX_TWEETS_PER_ACCOUNT);
    return { tweets };
  } catch (e) {
    return { error: String(e.message) };
  }
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://localhost:${PORT}`);

  // API: GET /api/tweets?handle=MEssyVirgoCoin
  if (url.pathname === '/api/tweets' && req.method === 'GET') {
    const handle = url.searchParams.get('handle') || '';
    if (!handle || !HANDLES.includes(handle)) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid or missing handle' }));
      return;
    }
    const data = await fetchTweets(handle);
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store, max-age=0',
    });
    res.end(JSON.stringify(data));
    return;
  }

  // API: GET /api/handles
  if (url.pathname === '/api/handles' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ handles: HANDLES }));
    return;
  }

  // API: GET /api/gateway-url — tokenized Control UI URL (for optional "open in new tab" link)
  if (url.pathname === '/api/gateway-url' && req.method === 'GET') {
    const requestHost = (req.headers.host || '').split(':')[0] || '127.0.0.1';
    if (GATEWAY_TOKEN) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        url: `http://${requestHost}:${GATEWAY_PORT}/?token=${encodeURIComponent(GATEWAY_TOKEN)}`,
        port: GATEWAY_PORT,
        host: requestHost,
      }));
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ url: null, port: GATEWAY_PORT, error: 'OPENCLAW_GATEWAY_TOKEN not set' }));
    }
    return;
  }

  // API: GET /api/memory/days — list available memory dates (memory/YYYY-MM-DD.md)
  if (url.pathname === '/api/memory/days' && req.method === 'GET') {
    const memoryDir = path.join(WORKSPACE_DIR, 'memory');
    try {
      const names = fs.readdirSync(memoryDir, { withFileTypes: true });
      const days = names
        .filter((d) => d.isFile() && d.name.endsWith('.md'))
        .map((d) => d.name.slice(0, -3))
        .filter((d) => MEMORY_DATE_REGEX.test(d))
        .sort()
        .reverse();
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ days }));
    } catch (e) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ days: [], error: e.code === 'ENOENT' ? 'memory/ not found' : String(e.message) }));
    }
    return;
  }

  // API: GET /api/memory?date=YYYY-MM-DD — read memory/YYYY-MM-DD.md from workspace
  if (url.pathname === '/api/memory' && req.method === 'GET') {
    const date = url.searchParams.get('date') || '';
    if (!MEMORY_DATE_REGEX.test(date)) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid date; use YYYY-MM-DD' }));
      return;
    }
    const filePath = path.join(WORKSPACE_DIR, 'memory', `${date}.md`);
    const resolved = path.resolve(filePath);
    const base = path.resolve(WORKSPACE_DIR) + path.sep;
    if (resolved !== path.resolve(WORKSPACE_DIR) && !resolved.startsWith(base)) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid path' }));
      return;
    }
    fs.readFile(filePath, 'utf8', (err, content) => {
      if (err) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ content: null, date, error: err.code === 'ENOENT' ? 'No memory file for this date' : String(err.message) }));
        return;
      }
      res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store, max-age=0' });
      res.end(JSON.stringify({ content, date }));
    });
    return;
  }

  // Static: index.html (no-store so users always get rate-limiting / sequential-load fixes)
  if (url.pathname === '/' || url.pathname === '/index.html') {
    serveFile(res, 'index.html', 'text/html', true);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`X Monitor Dashboard: http://0.0.0.0:${PORT}/`);
  if (!API_KEY) console.warn('XAPI_IO_API_KEY not set — API will return errors.');
});
