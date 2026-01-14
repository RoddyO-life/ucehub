/**
 * UCEHub Services API
 * Supports both Lambda and EC2/Docker deployment
 * Handles: Auth, Certificados, Biblioteca, Soporte, Becas
 */

const IS_LAMBDA = !!process.env.AWS_LAMBDA_FUNCTION_NAME;

// Lambda Handler
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    const path = event.path || event.rawPath || '/';
    const method = event.httpMethod || event.requestContext?.http?.method || 'GET';
    let body = {};
    
    try {
        if (event.body) {
            body = JSON.parse(event.body);
        }
    } catch (e) {
        body = {};
    }
    
    // CORS headers
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
    };
    
    // Handle OPTIONS preflight
    if (method === 'OPTIONS') {
        return { statusCode: 200, headers, body: '' };
    }
    
    try {
        // Health check
        if (path === '/health' || path === '/' || path === '/auth') {
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    status: 'healthy',
                    service: 'UCEHub API',
                    timestamp: new Date().toISOString(),
                    version: '1.0.0',
                    environment: process.env.ENVIRONMENT || 'qa'
                })
            };
        }
        
        // Auth login
        if (path === '/auth/login' && method === 'POST') {
            const { email, password } = body;
            if (email && password) {
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({
                        success: true,
                        message: 'Login successful',
                        user: {
                            id: '12345',
                            name: 'Juan Pérez',
                            email: email,
                            role: 'student'
                        },
                        token: 'mock-jwt-token-' + Date.now()
                    })
                };
            }
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ error: 'Email and password required' })
            };
        }
        
        // Certificados - Solicitar
        if (path === '/certificados/solicitar' && method === 'POST') {
            const { tipo, precio } = body;
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    message: 'Certificado solicitado exitosamente',
                    solicitud: {
                        id: 'CERT-' + Date.now(),
                        tipo,
                        precio,
                        estado: 'En proceso',
                        fecha: new Date().toISOString()
                    }
                })
            };
        }
        
        // Biblioteca - Reservar
        if (path === '/biblioteca/reservar' && method === 'POST') {
            const { libroId, titulo } = body;
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    message: 'Libro reservado exitosamente',
                    reserva: {
                        id: 'RES-' + Date.now(),
                        libroId,
                        titulo,
                        fechaReserva: new Date().toISOString(),
                        fechaDevolucion: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString()
                    }
                })
            };
        }
        
        // Soporte - Crear ticket
        if (path === '/soporte/ticket' && method === 'POST') {
            const { categoria, asunto, descripcion } = body;
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    message: 'Ticket creado exitosamente',
                    ticketId: 'TKT-' + Math.floor(Math.random() * 10000),
                    ticket: {
                        categoria,
                        asunto,
                        descripcion,
                        estado: 'Abierto',
                        prioridad: 'Media',
                        fechaCreacion: new Date().toISOString()
                    }
                })
            };
        }
        
        // Becas - Solicitar
        if (path === '/becas/solicitar' && method === 'POST') {
            const { becaId, nombre } = body;
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    message: 'Solicitud de beca enviada',
                    solicitud: {
                        id: 'BECA-' + Date.now(),
                        becaId,
                        nombre,
                        estado: 'En revisión',
                        fechaSolicitud: new Date().toISOString()
                    }
                })
            };
        }
        
        // 404 - Not found
        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({
                error: 'Endpoint not found',
                path,
                method
            })
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};

// HTTP Server for EC2/Docker
if (!IS_LAMBDA && require.main === module) {
    const http = require('http');
    const PORT = process.env.PORT || 3001;
    
    const server = http.createServer(async (req, res) => {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', async () => {
            const event = {
                path: req.url,
                httpMethod: req.method,
                headers: req.headers,
                body: body || null,
                requestContext: { http: { method: req.method } }
            };
            
            try {
                const response = await exports.handler(event);
                res.writeHead(response.statusCode, response.headers);
                res.end(response.body);
            } catch (error) {
                console.error('Server error:', error);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Internal server error' }));
            }
        });
    });
    
    server.listen(PORT, '0.0.0.0', () => {
        console.log(`🚀 UCEHub API Server running on port ${PORT}`);
        console.log(`📍 Health: http://localhost:${PORT}/health`);
        console.log(`🔐 Auth: http://localhost:${PORT}/auth/login`);
        console.log(`📄 Certificados: http://localhost:${PORT}/certificados/solicitar`);
        console.log(`📚 Biblioteca: http://localhost:${PORT}/biblioteca/reservar`);
        console.log(`🎫 Soporte: http://localhost:${PORT}/soporte/ticket`);
        console.log(`🎓 Becas: http://localhost:${PORT}/becas/solicitar`);
    });
}
