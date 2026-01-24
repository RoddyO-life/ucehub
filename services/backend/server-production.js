const express = require('express');
const cors = require('cors');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const Redis = require('ioredis');
const { swaggerUi, specs } = require('./swagger');

const app = express();
const PORT = process.env.PORT || 3001;

// Redis Configuration
const REDIS_ENDPOINT = process.env.REDIS_ENDPOINT || '';
let redis;

if (REDIS_ENDPOINT) {
  try {
    redis = new Redis(REDIS_ENDPOINT, {
      maxRetriesPerRequest: 1,
      connectTimeout: 5000,
    });
    redis.on('error', (err) => console.error('[Redis] Connection Error:', err.message));
    redis.on('connect', () => console.log('[Redis] Connected to cluster:', REDIS_ENDPOINT));
  } catch (err) {
    console.error('[Redis] Failed to initialize:', err.message);
  }
}

// Caching Helper
async function getCachedData(key) {
  if (!redis) return null;
  try {
    const cached = await redis.get(key);
    return cached ? JSON.parse(cached) : null;
  } catch (error) {
    console.error(`[Redis] Error getting key ${key}:`, error.message);
    return null;
  }
}

async function setCachedData(key, data, ttl = 300) {
  if (!redis) return false;
  try {
    await redis.set(key, JSON.stringify(data), 'EX', ttl);
    return true;
  } catch (error) {
    console.error(`[Redis] Error setting key ${key}:`, error.message);
    return false;
  }
}

// Middleware - IMPORTANTE: límite alto para archivos
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Swagger Documentation with Custom CSP for Styles/Scripts
const swaggerOptions = {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: "UCEHub API Documentation",
};

app.use(['/api/api-docs', '/api-docs'], swaggerUi.serve);
app.get(['/api/api-docs', '/api-docs'], (req, res, next) => {
  // Disable CSP for Swagger UI to allow inline styles/scripts required by the UI
  res.setHeader("Content-Security-Policy", "default-src * 'unsafe-inline' 'unsafe-eval'; script-src * 'unsafe-inline' 'unsafe-eval'; style-src * 'unsafe-inline';");
  next();
}, swaggerUi.setup(specs, swaggerOptions));

// Logger
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// AWS Configuration
const region = process.env.AWS_REGION || 'us-east-1';
const dynamoClient = new DynamoDBClient({ region });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const s3Client = new S3Client({ region });

// Environment variables
const CAFETERIA_TABLE = process.env.CAFETERIA_TABLE;
const SUPPORT_TICKETS_TABLE = process.env.SUPPORT_TICKETS_TABLE;
const ABSENCE_JUSTIFICATIONS_TABLE = process.env.ABSENCE_JUSTIFICATIONS_TABLE;
const DOCUMENTS_BUCKET = process.env.DOCUMENTS_BUCKET;
const TEAMS_WEBHOOK_URL = process.env.TEAMS_WEBHOOK_URL || '';

// Get instance IP
let instanceIP = 'unknown';
try {
  instanceIP = require('child_process').execSync('ec2-metadata --local-ipv4 2>/dev/null || echo "local"').toString().split(':').pop().trim();
} catch (e) {
  instanceIP = 'local-dev';
}

console.log('========================================');
console.log('UCEHub Backend v3.0 - Full Version');
console.log('Instance IP:', instanceIP);
console.log('Region:', region);
console.log('Cafeteria Table:', CAFETERIA_TABLE);
console.log('Support Table:', SUPPORT_TICKETS_TABLE);
console.log('Justifications Table:', ABSENCE_JUSTIFICATIONS_TABLE);
console.log('Documents Bucket:', DOCUMENTS_BUCKET);
console.log('Teams Webhook:', TEAMS_WEBHOOK_URL ? 'Configured' : 'Not configured');
console.log('========================================');

// Teams Notification Helper
async function sendTeamsNotification(title, message, facts = []) {
  if (!TEAMS_WEBHOOK_URL) {
    console.log('[Teams Notification - Not Sent]', title, message);
    return true;
  }

  try {
    const card = {
      "@type": "MessageCard",
      "@context": "https://schema.org/extensions",
      "summary": title,
      "themeColor": "0078D7",
      "title": title,
      "text": message,
      "sections": facts.length > 0 ? [{ "facts": facts }] : []
    };

    await axios.post(TEAMS_WEBHOOK_URL, card, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 5000
    });
    console.log('[Teams] Notification sent:', title);
    return true;
  } catch (error) {
    console.error('[Teams] Error:', error.message);
    return false;
  }
}

// ========================================
// HEALTH & INFO ENDPOINTS
// ========================================

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-backend',
    version: '3.0.0',
    instance: instanceIP,
    timestamp: new Date().toISOString(),
    config: {
      cafeteria_table: CAFETERIA_TABLE,
      support_table: SUPPORT_TICKETS_TABLE,
      justifications_table: ABSENCE_JUSTIFICATIONS_TABLE,
      documents_bucket: DOCUMENTS_BUCKET,
      teams_webhook_configured: !!TEAMS_WEBHOOK_URL
    }
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub API v3.0 - Universidad Central del Ecuador',
    instance: instanceIP,
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      cafeteria: {
        menu: 'GET /cafeteria/menu',
        order: 'POST /cafeteria/order',
        orders: 'GET /cafeteria/orders'
      },
      support: {
        ticket: 'POST /support/ticket',
        tickets: 'GET /support/tickets'
      },
      justifications: {
        submit: 'POST /justifications/submit',
        list: 'GET /justifications/list'
      }
    }
  });
});

// ========================================
// CAFETERIA ENDPOINTS
// ========================================

/**
 * @openapi
 * /cafeteria/menu:
 *   get:
 *     summary: Obtiene el menú disponible en la cafetería
 *     tags: [Cafeteria]
 *     responses:
 *       200:
 *         description: Menú obtenido exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 */
app.get('/cafeteria/menu', async (req, res) => {
  try {
    const menu = [
      { id: '1', name: 'Almuerzo Ejecutivo', description: 'Sopa del día + Segundo + Jugo natural', price: 3.50, category: 'almuerzos', icon: '🍽️', available: true },
      { id: '2', name: 'Desayuno Continental', description: 'Café + Pan artesanal + Huevos revueltos', price: 2.50, category: 'desayunos', icon: '🥐', available: true },
      { id: '3', name: 'Snack Saludable', description: 'Bowl de frutas + Yogurt griego + Granola', price: 2.00, category: 'snacks', icon: '🥗', available: true },
      { id: '4', name: 'Café Americano', description: 'Café de especialidad 100% arábica', price: 1.00, category: 'bebidas', icon: '☕', available: true },
      { id: '5', name: 'Jugo Natural', description: 'Naranja, Mora, Piña o Maracuyá', price: 1.50, category: 'bebidas', icon: '🥤', available: true },
      { id: '6', name: 'Sandwich Integral', description: 'Pan integral + Pollo + Vegetales frescos', price: 2.75, category: 'snacks', icon: '🥪', available: true },
      { id: '7', name: 'Ensalada César', description: 'Lechuga romana + Pollo grillado + Aderezo', price: 3.00, category: 'almuerzos', icon: '🥬', available: true },
      { id: '8', name: 'Batido Proteico', description: 'Leche + Banano + Proteína + Avena', price: 2.25, category: 'bebidas', icon: '🥛', available: true }
    ];

    res.json({
      success: true,
      data: menu,
      count: menu.length,
      instance: instanceIP,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('[Cafeteria Menu] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener el menú',
      error: error.message,
      instance: instanceIP
    });
  }
});

/**
 * @openapi
 * /cafeteria/order:
 *   post:
 *     summary: Crea una nueva orden de comida
 *     tags: [Cafeteria]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [userName, userEmail, items]
 *             properties:
 *               userName: {type: string}
 *               userEmail: {type: string}
 *               totalPrice: {type: number}
 *               items: {type: array, items: {type: object}}
 *     responses:
 *       200:
 *         description: Orden creada exitosamente
 */
app.post('/cafeteria/order', async (req, res) => {
  try {
    const { userName, userEmail, items, totalPrice, deliveryTime, notes } = req.body;

    if (!userName || !userEmail || !items || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Datos incompletos. Se requiere: userName, userEmail, items',
        instance: instanceIP
      });
    }

    const orderId = uuidv4();
    const timestamp = new Date().toISOString();

    const order = {
      orderId,
      userName,
      userEmail,
      items,
      totalPrice: totalPrice || 0,
      deliveryTime: deliveryTime || '12:00-13:00',
      notes: notes || '',
      status: 'pending',
      createdAt: timestamp,
      updatedAt: timestamp,
      instance: instanceIP
    };

    await docClient.send(new PutCommand({
      TableName: CAFETERIA_TABLE,
      Item: order
    }));

    // Invalidate cache
    if (redis) await redis.del('cafeteria:orders');

    console.log('[Cafeteria] New order:', orderId, 'by', userName);

    // Send Teams notification
    await sendTeamsNotification(
      '🍽️ Nueva Orden de Cafetería',
      `${userName} ha realizado un pedido`,
      [
        { name: 'Email', value: userEmail },
        { name: 'Total', value: `$${(totalPrice || 0).toFixed(2)}` },
        { name: 'Horario', value: deliveryTime || '12:00-13:00' },
        { name: 'Items', value: items.map(i => i.name).join(', ') },
        { name: 'Orden ID', value: orderId }
      ]
    );

    res.json({
      success: true,
      message: 'Orden creada exitosamente',
      data: {
        orderId,
        status: 'pending',
        estimatedTime: deliveryTime || '12:00-13:00'
      },
      instance: instanceIP
    });

  } catch (error) {
    console.error('[Cafeteria Order] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear la orden',
      error: error.message,
      instance: instanceIP
    });
  }
});

// Get orders
app.get('/cafeteria/orders', async (req, res) => {
  const cacheKey = 'cafeteria:orders';
  try {
    // Try cache first
    const cachedOrders = await getCachedData(cacheKey);
    if (cachedOrders) {
      console.log('[Redis] Cache HIT for cafeteria orders');
      return res.json({
        success: true,
        data: cachedOrders,
        count: cachedOrders.length,
        instance: instanceIP,
        source: 'cache'
      });
    }

    const result = await docClient.send(new ScanCommand({
      TableName: CAFETERIA_TABLE,
      Limit: 100
    }));

    const orders = (result.Items || []).sort((a, b) => 
      new Date(b.createdAt) - new Date(a.createdAt)
    );

    // Save to cache
    await setCachedData(cacheKey, orders, 60);

    res.json({
      success: true,
      data: orders,
      count: orders.length,
      instance: instanceIP,
      source: 'database'
    });
  } catch (error) {
    console.error('[Cafeteria Orders] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener órdenes',
      error: error.message,
      instance: instanceIP
    });
  }
});

// ========================================
// SUPPORT TICKET ENDPOINTS
// ========================================

// Create ticket
app.post('/support/ticket', async (req, res) => {
  try {
    const { userName, userEmail, category, subject, description, priority } = req.body;

    if (!userName || !userEmail || !subject || !description) {
      return res.status(400).json({
        success: false,
        message: 'Datos incompletos. Se requiere: userName, userEmail, subject, description',
        instance: instanceIP
      });
    }

    const ticketId = uuidv4();
    const timestamp = new Date().toISOString();

    const ticket = {
      ticketId,
      userName,
      userEmail,
      category: category || 'general',
      subject,
      description,
      priority: priority || 'medium',
      status: 'open',
      createdAt: timestamp,
      updatedAt: timestamp,
      instance: instanceIP
    };

    await docClient.send(new PutCommand({
      TableName: SUPPORT_TICKETS_TABLE,
      Item: ticket
    }));

    console.log('[Support] New ticket:', ticketId, 'by', userName);

    // Send Teams notification
    await sendTeamsNotification(
      '🎫 Nuevo Ticket de Soporte',
      `${userName} ha creado un nuevo ticket`,
      [
        { name: 'Email', value: userEmail },
        { name: 'Categoría', value: category || 'general' },
        { name: 'Asunto', value: subject },
        { name: 'Prioridad', value: priority || 'medium' },
        { name: 'Ticket ID', value: ticketId }
      ]
    );

    res.json({
      success: true,
      message: 'Ticket creado exitosamente',
      data: {
        ticketId,
        status: 'open'
      },
      instance: instanceIP
    });

  } catch (error) {
    console.error('[Support Ticket] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear el ticket',
      error: error.message,
      instance: instanceIP
    });
  }
});

// Get tickets
app.get('/support/tickets', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: SUPPORT_TICKETS_TABLE,
      Limit: 100
    }));

    const tickets = (result.Items || []).sort((a, b) => 
      new Date(b.createdAt) - new Date(a.createdAt)
    );

    res.json({
      success: true,
      data: tickets,
      count: tickets.length,
      instance: instanceIP
    });
  } catch (error) {
    console.error('[Support Tickets] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener tickets',
      error: error.message,
      instance: instanceIP
    });
  }
});

// ========================================
// JUSTIFICATION ENDPOINTS
// ========================================

// Submit justification
app.post('/justifications/submit', async (req, res) => {
  try {
    const { userName, userEmail, studentId, reason, date, documentBase64, documentName } = req.body;

    if (!userName || !userEmail || !reason || !date) {
      return res.status(400).json({
        success: false,
        message: 'Datos incompletos. Se requiere: userName, userEmail, reason, date',
        instance: instanceIP
      });
    }

    const justificationId = uuidv4();
    const timestamp = new Date().toISOString();
    let documentUrl = null;

    // Upload document to S3 if provided
    if (documentBase64 && documentName && DOCUMENTS_BUCKET) {
      try {
        const documentKey = `justifications/${justificationId}/${documentName}`;
        const buffer = Buffer.from(documentBase64, 'base64');

        await s3Client.send(new PutObjectCommand({
          Bucket: DOCUMENTS_BUCKET,
          Key: documentKey,
          Body: buffer,
          ContentType: 'application/pdf'
        }));

        // Generate presigned URL (valid for 7 days)
        documentUrl = await getSignedUrl(s3Client, new GetObjectCommand({
          Bucket: DOCUMENTS_BUCKET,
          Key: documentKey
        }), { expiresIn: 604800 });

        console.log('[Justification] Document uploaded:', documentKey);
      } catch (s3Error) {
        console.error('[Justification] S3 upload error:', s3Error.message);
        // Continue without document
      }
    }

    const justification = {
      justificationId,
      userName,
      userEmail,
      studentId: studentId || 'N/A',
      reason,
      date,
      documentUrl,
      documentName: documentName || null,
      status: 'pending',
      createdAt: timestamp,
      updatedAt: timestamp,
      instance: instanceIP
    };

    await docClient.send(new PutCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Item: justification
    }));

    console.log('[Justification] New submission:', justificationId, 'by', userName);

    // Send Teams notification
    await sendTeamsNotification(
      '📜 Nueva Justificación de Ausencia',
      `${userName} ha enviado una justificación`,
      [
        { name: 'Estudiante ID', value: studentId || 'N/A' },
        { name: 'Email', value: userEmail },
        { name: 'Fecha', value: date },
        { name: 'Razón', value: reason.substring(0, 100) + (reason.length > 100 ? '...' : '') },
        { name: 'Documento', value: documentUrl ? '✅ Adjuntado' : '❌ Sin documento' },
        { name: 'Justificación ID', value: justificationId }
      ]
    );

    res.json({
      success: true,
      message: 'Justificación enviada exitosamente',
      data: {
        justificationId,
        status: 'pending',
        documentUrl
      },
      instance: instanceIP
    });

  } catch (error) {
    console.error('[Justification Submit] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al enviar la justificación',
      error: error.message,
      instance: instanceIP
    });
  }
});

// Get justifications
app.get('/justifications/list', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Limit: 100
    }));

    const justifications = (result.Items || []).sort((a, b) => 
      new Date(b.createdAt) - new Date(a.createdAt)
    );

    res.json({
      success: true,
      data: justifications,
      count: justifications.length,
      instance: instanceIP
    });
  } catch (error) {
    console.error('[Justifications List] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener justificaciones',
      error: error.message,
      instance: instanceIP
    });
  }
});

// ========================================
// DOCUMENT ENDPOINTS
// ========================================

// Download document
app.get('/documents/download/:documentId/:fileName', async (req, res) => {
  try {
    const { documentId, fileName } = req.params;
    
    if (!documentId || !fileName || !DOCUMENTS_BUCKET) {
      return res.status(400).json({
        success: false,
        message: 'Parámetros requeridos faltantes',
        instance: instanceIP
      });
    }

    const documentKey = `justifications/${documentId}/${fileName}`;
    
    console.log('[Document] Downloading:', documentKey);

    try {
      const response = await s3Client.send(new GetObjectCommand({
        Bucket: DOCUMENTS_BUCKET,
        Key: documentKey
      }));

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      
      // Pipe the stream to response
      response.Body.pipe(res);
    } catch (s3Error) {
      console.error('[Document] S3 Error:', s3Error.message);
      res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
        error: s3Error.message,
        instance: instanceIP
      });
    }
  } catch (error) {
    console.error('[Document Download] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al descargar documento',
      error: error.message,
      instance: instanceIP
    });
  }
});

// Get document via presigned URL (already exists, but documented here)
app.get('/documents/presigned/:documentId/:fileName', async (req, res) => {
  try {
    const { documentId, fileName } = req.params;
    
    if (!documentId || !fileName || !DOCUMENTS_BUCKET) {
      return res.status(400).json({
        success: false,
        message: 'Parámetros requeridos faltantes',
        instance: instanceIP
      });
    }

    const documentKey = `justifications/${documentId}/${fileName}`;
    
    // Generate presigned URL (valid for 1 hour)
    const presignedUrl = await getSignedUrl(s3Client, new GetObjectCommand({
      Bucket: DOCUMENTS_BUCKET,
      Key: documentKey
    }), { expiresIn: 3600 });

    console.log('[Document] Presigned URL generated:', documentKey);

    res.json({
      success: true,
      data: {
        url: presignedUrl,
        fileName,
        expiresIn: 3600
      },
      instance: instanceIP
    });
  } catch (error) {
    console.error('[Document Presigned] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error al generar URL presignada',
      error: error.message,
      instance: instanceIP
    });
  }
});

// ========================================
// START SERVER
// ========================================

app.listen(PORT, '0.0.0.0', () => {
  console.log('========================================');
  console.log(`✅ UCEHub Backend running on port ${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/health`);
  console.log(`   API: http://localhost:${PORT}/`);
  console.log('Instance:', instanceIP);
  console.log('========================================');
});
