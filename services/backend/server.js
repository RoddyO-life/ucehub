const express = require('express');
const cors = require('cors');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const { swaggerUi, specs } = require('./swagger');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Logger for debugging paths
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} - ${req.path}`);
  next();
});

// Swagger Documentation
app.use(['/api-docs', '/api/api-docs'], swaggerUi.serve, swaggerUi.setup(specs));

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

// Get instance metadata
let instanceIP = 'unknown';
try {
  const response = require('child_process').execSync('ec2-metadata --local-ipv4').toString();
  instanceIP = response.split(':')[1].trim();
} catch (error) {
  console.log('Running locally, no instance metadata available');
}

// Send notification to Microsoft Teams
async function sendTeamsNotification(title, message, facts = [], actions = []) {
  if (!TEAMS_WEBHOOK_URL) {
    console.log('========================================');
    console.log('TEAMS NOTIFICATION (Webhook not configured)');
    console.log('Title:', title);
    console.log('Message:', message);
    console.log('Facts:', JSON.stringify(facts, null, 2));
    console.log('========================================');
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
      "sections": facts.length > 0 ? [{
        "facts": facts
      }] : [],
      "potentialAction": actions
    };

    await axios.post(TEAMS_WEBHOOK_URL, card);
    console.log('Teams notification sent successfully');
    return true;
  } catch (error) {
    console.error('Error sending Teams notification:', error.message);
    return false;
  }
}

// Health check
/**
 * @openapi
 * /health:
 *   get:
 *     description: Retorna el estado de salud de la API y su conectividad con AWS.
 *     responses:
 *       200:
 *         description: OK
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-backend-teams',
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
    message: 'UCEHub API v3.0 - Teams Integration',
    instance: instanceIP,
    endpoints: {
      cafeteria: ['/cafeteria/menu', '/cafeteria/order', '/cafeteria/orders'],
      support: ['/support/ticket', '/support/tickets'],
      justifications: ['/justifications/submit', '/justifications/list', '/justifications/approve', '/justifications/reject']
    }
  });
});

// ========================================
// CAFETERIA ENDPOINTS
// ========================================

// Get menu
app.get('/cafeteria/menu', async (req, res) => {
  try {
    const menu = [
      { id: 1, name: 'Cafe', price: 1.50, category: 'Bebidas', available: true },
      { id: 2, name: 'Sandwich', price: 3.00, category: 'Comida', available: true },
      { id: 3, name: 'Jugo Natural', price: 2.00, category: 'Bebidas', available: true },
      { id: 4, name: 'Empanada', price: 1.00, category: 'Snacks', available: true },
      { id: 5, name: 'Almuerzo Completo', price: 5.50, category: 'Comida', available: true }
    ];
    res.json({ success: true, data: menu });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create order
app.post('/cafeteria/order', async (req, res) => {
  try {
    const { items, total, userEmail, userName, paymentMethod } = req.body;
    
    const orderId = "ORD-" + uuidv4().substring(0, 8).toUpperCase();
    const createdAt = Date.now();
    
    const order = {
      orderId,
      createdAt,
      userEmail,
      userName: userName || 'Usuario',
      items,
      total,
      paymentMethod: paymentMethod || 'Efectivo',
      status: 'pending',
      createdAtISO: new Date().toISOString()
    };
    
    await docClient.send(new PutCommand({ TableName: CAFETERIA_TABLE, Item: order }));
    
    const itemsList = items.map(i => i.name + " x" + i.quantity + " - $" + (i.price * i.quantity).toFixed(2)).join(', ');
    
    await sendTeamsNotification(
      "Nueva Orden de Cafeteria - " + orderId,
      "Se ha recibido una nueva orden de la cafeteria",
      [
        { name: "ID de Orden", value: orderId },
        { name: "Cliente", value: userName },
        { name: "Email", value: userEmail },
        { name: "Total", value: "$" + total.toFixed(2) },
        { name: "Metodo de Pago", value: paymentMethod },
        { name: "Items", value: itemsList }
      ],
      [
        {
          "@type": "OpenUri",
          "name": "Ver Detalles",
          "targets": [{
            "os": "default",
            "uri": "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com"
          }]
        }
      ]
    );
    
    res.json({ success: true, data: order });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get all orders
app.get('/cafeteria/orders', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({ TableName: CAFETERIA_TABLE }));
    res.json({ success: true, data: result.Items || [] });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// SUPPORT ENDPOINTS
// ========================================

// Create ticket
app.post('/support/ticket', async (req, res) => {
  try {
    const { category, priority, subject, description, userEmail, userName } = req.body;
    
    const ticketId = "TICK-" + uuidv4().substring(0, 8).toUpperCase();
    const createdAt = Date.now();
    
    const ticket = {
      ticketId,
      createdAt,
      userEmail,
      userName: userName || 'Usuario',
      category,
      priority,
      subject,
      description,
      status: 'open',
      createdAtISO: new Date().toISOString()
    };
    
    await docClient.send(new PutCommand({ TableName: SUPPORT_TICKETS_TABLE, Item: ticket }));
    
    await sendTeamsNotification(
      "Nuevo Ticket de Soporte - " + ticketId,
      "Se ha creado un nuevo ticket de soporte tecnico",
      [
        { name: "ID de Ticket", value: ticketId },
        { name: "Usuario", value: userName },
        { name: "Email", value: userEmail },
        { name: "Categoria", value: category },
        { name: "Prioridad", value: priority },
        { name: "Asunto", value: subject },
        { name: "Descripcion", value: description }
      ],
      [
        {
          "@type": "OpenUri",
          "name": "Ver Ticket",
          "targets": [{
            "os": "default",
            "uri": "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com"
          }]
        }
      ]
    );
    
    res.json({ success: true, data: ticket });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get all tickets
app.get('/support/tickets', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({ TableName: SUPPORT_TICKETS_TABLE }));
    res.json({ success: true, data: result.Items || [] });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// JUSTIFICATIONS ENDPOINTS
// ========================================

// Submit justification
app.post('/justifications/submit', async (req, res) => {
  try {
    console.log('\n=== JUSTIFICATION SUBMIT REQUEST ===');
    console.log('Received data:', { reason: req.body.reason, userEmail: req.body.userEmail });
    console.log('DOCUMENTS_BUCKET:', DOCUMENTS_BUCKET);
    console.log('=====================================\n');
    
    const { reason, startDate, endDate, userEmail, userName, documentBase64, documentName } = req.body;
    
    // Validate required fields
    if (!reason || !startDate || !endDate || !userEmail || !userName) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: reason, startDate, endDate, userEmail, userName' 
      });
    }
    
    const justificationId = "JUST-" + uuidv4().substring(0, 8).toUpperCase();
    const submittedAt = Date.now();
    let documentUrl = null;
    
    if (documentBase64 && documentName) {
      try {
        const buffer = Buffer.from(documentBase64.split(',')[1], 'base64');
        const key = "justifications/" + justificationId + "/" + documentName;
        
        console.log('Uploading to S3:', { bucket: DOCUMENTS_BUCKET, key });
        
        await s3Client.send(new PutObjectCommand({
          Bucket: DOCUMENTS_BUCKET,
          Key: key,
          Body: buffer,
          ContentType: 'application/pdf'
        }));
        
        const command = new GetObjectCommand({ Bucket: DOCUMENTS_BUCKET, Key: key });
        documentUrl = await getSignedUrl(s3Client, command, { expiresIn: 604800 });
        
        // Also set Content-Disposition for inline viewing
        const contentDispositionCommand = new GetObjectCommand({ 
          Bucket: DOCUMENTS_BUCKET, 
          Key: key,
          ResponseContentDisposition: 'inline; filename="' + documentName + '"',
          ResponseContentType: 'application/pdf'
        });
        documentUrl = await getSignedUrl(s3Client, contentDispositionCommand, { expiresIn: 604800 });
        
        console.log('Document URL generated:', !!documentUrl);
      } catch (s3Error) {
        console.error('S3 Upload Error:', s3Error.message);
        console.error('Bucket:', DOCUMENTS_BUCKET);
        console.error('Region:', region);
        throw new Error('Failed to upload document to S3: ' + s3Error.message);
      }
    }
    
    if (!ABSENCE_JUSTIFICATIONS_TABLE) {
      return res.status(500).json({ 
        success: false, 
        error: 'ABSENCE_JUSTIFICATIONS_TABLE environment variable not configured' 
      });
    }
    
    const justification = {
      justificationId,
      submittedAt,
      userEmail,
      userName: userName || 'Usuario',
      reason,
      startDate,
      endDate,
      documentKey: documentBase64 ? ("justifications/" + justificationId + "/" + documentName) : null,
      documentUrl,
      status: 'pending',
      submittedAtISO: new Date().toISOString()
    };
    
    console.log('Saving to DynamoDB table:', ABSENCE_JUSTIFICATIONS_TABLE);
    console.log('Justification data:', JSON.stringify(justification, null, 2));
    
    await docClient.send(new PutCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE, Item: justification }));
    
    console.log('\n=== JUSTIFICATION SAVED SUCCESSFULLY ===');
    console.log('ID:', justificationId);
    console.log('=========================================\n');
    
    const actions = [
      {
        "@type": "HttpPOST",
        "name": "Aprobar",
        "target": "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/justifications/approve",
        "body": JSON.stringify({ justificationId: justificationId }),
        "headers": [{ "name": "Content-Type", "value": "application/json" }]
      },
      {
        "@type": "HttpPOST",
        "name": "Rechazar",
        "target": "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/justifications/reject",
        "body": JSON.stringify({ justificationId: justificationId }),
        "headers": [{ "name": "Content-Type", "value": "application/json" }]
      }
    ];
    
    if (documentUrl) {
      actions.unshift({
        "@type": "OpenUri",
        "name": "Ver Certificado",
        "targets": [{ "os": "default", "uri": documentUrl }]
      });
    }
    
    await sendTeamsNotification(
      "Nueva Justificacion de Falta - " + justificationId,
      "Se requiere aprobacion para una justificacion de ausencia",
      [
        { name: "ID", value: justificationId },
        { name: "Estudiante", value: userName },
        { name: "Email", value: userEmail },
        { name: "Motivo", value: reason },
        { name: "Periodo", value: startDate + " - " + endDate },
        { name: "Documento", value: documentUrl ? "Si adjunto" : "No adjunto" }
      ],
      actions
    );
    
    res.json({ success: true, data: justification });
  } catch (error) {
    console.error('\n=== ERROR IN JUSTIFICATION SUBMIT ===');
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    console.error('======================================\n');
    res.status(500).json({ success: false, error: error.message });
  }
});

// Approve justification
app.post('/justifications/approve', async (req, res) => {
  try {
    const { justificationId } = req.body;
    
    await docClient.send(new UpdateCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Key: { justificationId },
      UpdateExpression: 'SET #status = :status, approvedAt = :approvedAt',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
        ':status': 'approved',
        ':approvedAt': Date.now()
      }
    }));
    
    const result = await docClient.send(new GetCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Key: { justificationId }
    }));
    
    const justification = result.Item;
    
    await sendTeamsNotification(
      "Justificacion Aprobada - " + justificationId,
      "La justificacion ha sido aprobada exitosamente",
      [
        { name: "ID", value: justificationId },
        { name: "Estudiante", value: justification.userName },
        { name: "Estado", value: "APROBADA" }
      ]
    );
    
    res.json({ success: true, message: 'Justificacion aprobada' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Reject justification
app.post('/justifications/reject', async (req, res) => {
  try {
    const { justificationId } = req.body;
    
    await docClient.send(new UpdateCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Key: { justificationId },
      UpdateExpression: 'SET #status = :status, rejectedAt = :rejectedAt',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
        ':status': 'rejected',
        ':rejectedAt': Date.now()
      }
    }));
    
    const result = await docClient.send(new GetCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Key: { justificationId }
    }));
    
    const justification = result.Item;
    
    await sendTeamsNotification(
      "Justificacion Rechazada - " + justificationId,
      "La justificacion ha sido rechazada",
      [
        { name: "ID", value: justificationId },
        { name: "Estudiante", value: justification.userName },
        { name: "Estado", value: "RECHAZADA" }
      ]
    );
    
    res.json({ success: true, message: 'Justificacion rechazada' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get all justifications
app.get('/justifications/list', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE }));
    res.json({ success: true, data: result.Items || [] });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log("UCEHub Backend v3.0 listening on port " + PORT);
  console.log("Instance: " + instanceIP);
  console.log("Tables configured:");
  console.log("  - Cafeteria: " + CAFETERIA_TABLE);
  console.log("  - Support: " + SUPPORT_TICKETS_TABLE);
  console.log("  - Justifications: " + ABSENCE_JUSTIFICATIONS_TABLE);
  console.log("  - Documents Bucket: " + DOCUMENTS_BUCKET);
  console.log("Teams webhook: " + (TEAMS_WEBHOOK_URL ? "Configured" : "Not configured"));
});
