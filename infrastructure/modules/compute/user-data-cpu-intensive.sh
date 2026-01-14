#!/bin/bash
set -e

# Variables
region="${region}"
environment="${environment}"

# Update system and install Docker
yum update -y
yum install -y docker

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Wait for Docker to be ready
sleep 5

# Create application directory
mkdir -p /opt/app

# Create Node.js server with CPU-intensive operations
cat > /opt/app/server.js <<'NODESCRIPT'
const http = require('http');
const os = require('os');

const environment = process.env.ENVIRONMENT || 'unknown';

// CPU-intensive Fibonacci calculation
function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// Check if number is prime
function isPrime(num) {
    if (num < 2) return false;
    for (let i = 2; i <= Math.sqrt(num); i++) {
        if (num % i === 0) return false;
    }
    return true;
}

// Matrix multiplication for CPU load
function matrixMultiply(size) {
    const a = Array(size).fill().map(() => Array(size).fill(Math.random()));
    const b = Array(size).fill().map(() => Array(size).fill(Math.random()));
    const result = Array(size).fill().map(() => Array(size).fill(0));
    
    for (let i = 0; i < size; i++) {
        for (let j = 0; j < size; j++) {
            for (let k = 0; k < size; k++) {
                result[i][j] += a[i][k] * b[k][j];
            }
        }
    }
    return result[0][0];
}

// Heavy CPU work function
function doCpuWork() {
    // Fibonacci MÁS PESADO - hasta 35 (era 30)
    let calcResult = 0;
    for (let i = 0; i < 35; i++) {
        calcResult += fibonacci(i);
    }
    
    // Check primes AUMENTADO - hasta 50000 (era 10000)
    let primes = 0;
    for (let i = 2; i < 50000; i++) {
        if (isPrime(i)) primes++;
    }
    
    // Matrix multiplication NUEVA - 100x100 matrices
    let matrixResult = 0;
    for (let i = 0; i < 3; i++) {
        matrixResult += matrixMultiply(100);
    }
    
    // String manipulation para más carga
    let stringResult = '';
    for (let i = 0; i < 100000; i++) {
        stringResult += String(Math.random());
    }
    
    return { 
        fibonacci: calcResult, 
        primes: primes,
        matrix: Math.round(matrixResult * 1000) / 1000
    };
}

// Get private IP function
function getPrivateIP() {
    const interfaces = os.networkInterfaces();
    for (let iface of Object.values(interfaces)) {
        for (let addr of iface) {
            if (addr.family === 'IPv4' && !addr.internal) {
                return addr.address;
            }
        }
    }
    return 'unknown';
}

const instanceIP = getPrivateIP();

const server = http.createServer((req, res) => {
    const startTime = Date.now();
    
    if (req.url === '/health') {
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.end('healthy\n');
    } else if (req.url === '/') {
        const cpuResult = doCpuWork();
        const duration = Date.now() - startTime;
        
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.end(`
            <html>
            <head>
                <title>UCEHub CPU Test - ${environment}</title>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body { 
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                        min-height: 100vh; 
                        padding: 20px;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }
                    .container { 
                        background: white; 
                        padding: 40px; 
                        border-radius: 20px; 
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
                        max-width: 900px; 
                        width: 100%;
                    }
                    .instance-ip { 
                        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); 
                        color: white; 
                        padding: 25px; 
                        border-radius: 15px; 
                        font-size: 32px; 
                        font-weight: bold; 
                        text-align: center; 
                        margin: 25px 0; 
                        box-shadow: 0 10px 30px rgba(245, 87, 108, 0.4);
                        transition: transform 0.3s ease;
                    }
                    .instance-ip:hover { transform: translateY(-5px); }
                    .stats { 
                        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); 
                        padding: 25px; 
                        border-radius: 15px; 
                        margin: 20px 0; 
                        border-left: 6px solid #667eea;
                    }
                    .stats p { 
                        margin: 12px 0; 
                        font-size: 18px; 
                        color: #333;
                    }
                    .stats strong { color: #667eea; }
                    h1 { 
                        color: #333; 
                        margin-bottom: 10px; 
                        font-size: 36px;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                        background-clip: text;
                    }
                    h2 { 
                        color: #666; 
                        margin-top: 0; 
                        margin-bottom: 20px;
                        font-size: 22px;
                    }
                    .tip { 
                        background: linear-gradient(135deg, #fff3cd 0%, #ffe8a1 100%); 
                        padding: 20px; 
                        border-radius: 10px; 
                        margin-top: 25px; 
                        border-left: 6px solid #ffc107;
                    }
                    .tip p { margin: 8px 0; line-height: 1.6; }
                    .emoji { font-size: 24px; }
                    .cpu-status { 
                        color: #dc3545; 
                        font-weight: bold; 
                        font-size: 20px;
                        animation: pulse 2s infinite;
                    }
                    @keyframes pulse {
                        0%, 100% { opacity: 1; }
                        50% { opacity: 0.6; }
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1><span class="emoji">🚀</span> UCEHub - ${environment}</h1>
                    <h2><span class="emoji">⚡</span> CPU-Intensive Load Balancer Test</h2>
                    <div class="instance-ip">
                        <span class="emoji">📍</span> Instance IP: ` + instanceIP + `
                    </div>
                    <div class="stats">
                        <p><strong><span class="emoji">🔢</span> Fibonacci sum:</strong> ` + cpuResult.fibonacci + `</p>
                        <p><strong><span class="emoji">🔢</span> Primes found:</strong> ` + cpuResult.primes + `</p>
                        <p><strong><span class="emoji">📊</span> Matrix result:</strong> ` + cpuResult.matrix + `</p>
                        <p><strong><span class="emoji">⏱️</span> Processing time:</strong> ` + duration + `ms</p>
                        <p><strong><span class="emoji">🔥</span> CPU Status:</strong> <span class="cpu-status">MAXIMUM LOAD!</span></p>
                    </div>
                    <div class="tip">
                        <p><span class="emoji">💡</span> <strong>Tip:</strong> Refresh the page multiple times to see the load balancer distributing traffic across different instances!</p>
                        <p><span class="emoji">🎯</span> Each instance shows its unique private IP address.</p>
                        <p><span class="emoji">📈</span> Watch the instance count increase as CPU load reaches 70%!</p>
                    </div>
                </div>
            </body>
            </html>
        `);
    } else {
        res.writeHead(404, {'Content-Type': 'text/plain'});
        res.end('Not Found\n');
    }
});

const PORT = 80;
server.listen(PORT, () => {
    console.log('CPU-intensive server running on port ' + PORT);
    console.log('Instance IP: ' + instanceIP);
    console.log('Environment: ' + environment);
});
NODESCRIPT

# Create Dockerfile
cat > /opt/app/Dockerfile <<'DOCKERFILE'
FROM node:18-alpine
WORKDIR /app
COPY server.js .
EXPOSE 80
ENV ENVIRONMENT=${environment}
CMD ["node", "server.js"]
DOCKERFILE

# Build Docker image
cd /opt/app
docker build -t ucehub-cpu-app .

# Run container
docker run -d -p 80:80 -e ENVIRONMENT="${environment}" --name ucehub-app ucehub-cpu-app
