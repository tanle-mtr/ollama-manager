/**
 * Ollama Registry Proxy - 国内镜像加速
 * 解决 registry.ollama.ai 无法访问的问题
 */

const http = require('http');
const https = require('https');
const url = require('url');

const PORT = process.env.PROXY_PORT || 18080;
const TARGET_REGISTRY = 'registry.ollama.ai';
const PROXY_MIRROR = 'mirror.ghproxy.com'; // 或者使用其他镜像

console.log(`Ollama Proxy Server started on port ${PORT}`);
console.log(`Target: ${TARGET_REGISTRY}`);
console.log(`Mirror: ${PROXY_MIRROR}`);
console.log('');
console.log('To use this proxy, set:');
console.log(`  set OLLAMA_HOST=http://localhost:${PORT}`);
console.log('');

const server = http.createServer((req, res) => {
  const targetUrl = `https://${TARGET_REGISTRY}${req.url}`;
  
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  
  const options = {
    hostname: TARGET_REGISTRY,
    port: 443,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: TARGET_REGISTRY
    }
  };

  // 尝试直接连接，如果失败则使用镜像
  const proxyReq = https.request(options, (proxyRes) => {
    console.log(`  -> ${proxyRes.statusCode}`);
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (error) => {
    console.log(`  -> Error: ${error.message}`);
    console.log(`  -> Trying mirror: ${PROXY_MIRROR}`);
    
    // 使用 ghproxy 作为镜像
    const mirrorUrl = `https://${PROXY_MIRROR}/https://${TARGET_REGISTRY}${req.url}`;
    const mirrorReq = https.request(mirrorUrl, (mirrorRes) => {
      console.log(`  -> Mirror: ${mirrorRes.statusCode}`);
      res.writeHead(mirrorRes.statusCode, mirrorRes.headers);
      mirrorRes.pipe(res);
    });

    mirrorReq.on('error', (e) => {
      console.log(`  -> Mirror failed: ${e.message}`);
      res.writeHead(502);
      res.end(JSON.stringify({ error: 'Failed to fetch model from registry or mirror' }));
    });

    req.pipe(mirrorReq);
  });

  req.pipe(proxyReq);
});

server.listen(PORT, () => {
  console.log(`✓ Ollama Registry Proxy running at http://localhost:${PORT}`);
  console.log('');
  console.log('Next steps:');
  console.log(`  export OLLAMA_HOST=http://localhost:${PORT}`);
  console.log('  ollama pull phi3');
});

process.on('SIGINT', () => {
  console.log('\nShutting down...');
  server.close(() => process.exit(0));
});
