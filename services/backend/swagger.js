const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'UCEHub Backend API',
      version: '2.0.0',
      description: 'API central para la gestión de Cafeterías, Justificaciones y Soporte de la UCE.',
      contact: {
        name: 'Soporte UCEHub',
      },
    },
    servers: [
      {
        url: 'http://localhost:8080',
        description: 'Servidor Local',
      },
      {
        url: 'https://api.ucehub.edu.ec',
        description: 'Servidor de Producción',
      },
    ],
  },
  apis: ['./server-production.js', './server.js', './routes/*.js'], // Archivos donde buscar anotaciones
};

const specs = swaggerJsdoc(options);

module.exports = {
  swaggerUi,
  specs,
};
