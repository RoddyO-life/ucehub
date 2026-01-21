import React, { useState } from 'react'
import {
  makeStyles,
  Button,
  Spinner,
} from '@fluentui/react-components'
import {
  CheckmarkCircleRegular,
  AlertRegular,
} from '@fluentui/react-icons'
import axios from 'axios'

const Title3 = ({ children, ...props }: any) => (
  <div style={{ fontSize: '20px', fontWeight: '600', ...props.style }} {...props}>{children}</div>
)

const Body1 = ({ children, ...props }: any) => (
  <div style={{ fontSize: '14px', ...props.style }} {...props}>{children}</div>
)

const useStyles = makeStyles({
  container: {
    display: 'flex',
    flexDirection: 'column',
    gap: '24px',
    padding: '24px',
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  },
  header: {
    color: '#ffffff',
    marginBottom: '16px',
  },
  headerTitle: {
    fontSize: '28px',
    fontWeight: '700',
    marginBottom: '8px',
  },
  headerSubtitle: {
    fontSize: '14px',
    opacity: '0.9',
  },
  card: {
    background: 'rgba(255, 255, 255, 0.95)',
    backdropFilter: 'blur(10px)',
    borderRadius: '12px',
    padding: '24px',
    border: '1px solid rgba(255, 255, 255, 0.3)',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '16px',
    marginTop: '16px',
  },
  formGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  label: {
    fontWeight: '600',
    color: '#333333',
    fontSize: '14px',
  },
  input: {
    padding: '10px',
    border: '1px solid #e0e0e0',
    borderRadius: '6px',
    fontSize: '14px',
    fontFamily: 'inherit',
    ':focus': {
      outline: 'none',
    },
  },
  textarea: {
    padding: '10px',
    border: '1px solid #e0e0e0',
    borderRadius: '6px',
    fontSize: '14px',
    fontFamily: 'inherit',
    minHeight: '120px',
    resize: 'vertical',
  },
  select: {
    padding: '10px',
    border: '1px solid #e0e0e0',
    borderRadius: '6px',
    fontSize: '14px',
    fontFamily: 'inherit',
    ':focus': {
      outline: 'none',
    },
  },
  submitButton: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: '#ffffff',
    border: 'none',
    padding: '12px 28px',
    borderRadius: '6px',
    fontWeight: '600',
    fontSize: '14px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    ':hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 12px 24px rgba(102, 126, 234, 0.4)',
    },
    ':disabled': {
      opacity: '0.5',
      cursor: 'not-allowed',
    },
  },
  ticketsList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
    marginTop: '16px',
  },
  ticketItem: {
    background: 'rgba(255, 255, 255, 0.8)',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    padding: '16px',
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
    transition: 'all 0.2s',
    ':hover': {
      boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)',
    },
  },
  ticketHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  ticketNumber: {
    fontSize: '12px',
    fontWeight: '600',
    color: '#666666',
    background: '#f0f4ff',
    padding: '4px 12px',
    borderRadius: '4px',
  },
  ticketTitle: {
    fontSize: '16px',
    fontWeight: '700',
    color: '#333333',
  },
  ticketDescription: {
    fontSize: '14px',
    color: '#666666',
    lineHeight: '1.5',
  },
  ticketFooter: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '12px',
  },
  statusBadge: {
    padding: '4px 12px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '600',
  },
  statusOpen: {
    background: '#e7f3ff',
    color: '#004b7a',
  },
  statusInProgress: {
    background: '#fff4ce',
    color: '#b86f00',
  },
  statusResolved: {
    background: '#dcf5dd',
    color: '#107c10',
  },
  statusClosed: {
    background: '#f0f0f0',
    color: '#666666',
  },
  priorityBadge: {
    padding: '4px 12px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '600',
  },
  priorityLow: {
    background: '#e7f3ff',
    color: '#004b7a',
  },
  priorityMedium: {
    background: '#fff4ce',
    color: '#b86f00',
  },
  priorityHigh: {
    background: '#fed4d4',
    color: '#a4373a',
  },
  emptyState: {
    textAlign: 'center',
    padding: '40px 20px',
  },
  emptyIcon: {
    fontSize: '48px',
    marginBottom: '16px',
    opacity: '0.5',
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
    gap: '12px',
    marginTop: '16px',
  },
  statBox: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: '#ffffff',
    borderRadius: '8px',
    padding: '16px',
    textAlign: 'center',
  },
  statValue: {
    fontSize: '24px',
    fontWeight: '700',
  },
  statLabel: {
    fontSize: '12px',
    opacity: '0.9',
    marginTop: '4px',
  },
})

interface Ticket {
  id: string
  number: string
  title: string
  description: string
  category: string
  priority: 'low' | 'medium' | 'high'
  status: 'open' | 'in-progress' | 'resolved' | 'closed'
  createdDate: string
  responses: number
}

export const Support: React.FC = () => {
  const styles = useStyles()
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [category, setCategory] = useState('technical')
  const [priority, setPriority] = useState('medium')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [tickets] = useState<Ticket[]>([
    {
      id: '1',
      number: 'TK-2024-001',
      title: 'No puedo acceder al portal',
      description: 'Error 503 al intentar ingresar',
      category: 'technical',
      priority: 'high',
      status: 'in-progress',
      createdDate: '2024-01-10',
      responses: 2
    },
    {
      id: '2',
      number: 'TK-2024-002',
      title: 'Consulta sobre horarios',
      description: 'Cómo veo mis horarios en el sistema',
      category: 'general',
      priority: 'low',
      status: 'resolved',
      createdDate: '2024-01-12',
      responses: 1
    },
  ])

  const handleSubmit = async () => {
    if (!title || !description) {
      setError('Por favor completa todos los campos.')
      return
    }

    setLoading(true)
    setError('')
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3001'
      const response = await axios.post(`${apiUrl}/support/ticket`, {
        title: title.trim(),
        description: description.trim(),
        category: category || 'general',
        priority: priority || 'medium',
        userEmail: 'estudiante@ucehub.edu.ec',
        userName: 'Estudiante UCE',
        subject: title.trim()
      }, {
        headers: { 'Content-Type': 'application/json' }
      })

      console.log('Ticket created:', response.data)
      setSuccess(true)
      setTitle('')
      setDescription('')
      setCategory('technical')
      setPriority('medium')
      
      setTimeout(() => {
        setSuccess(false)
        // Reload tickets list
        window.location.reload()
      }, 2000)
    } catch (err: any) {
      console.error('Submit error:', err)
      setError(err.response?.data?.message || 'Error al crear el ticket.')
    } finally {
      setLoading(false)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open':
        return styles.statusOpen
      case 'in-progress':
        return styles.statusInProgress
      case 'resolved':
        return styles.statusResolved
      case 'closed':
        return styles.statusClosed
      default:
        return styles.statusOpen
    }
  }

  const getStatusText = (status: string) => {
    switch (status) {
      case 'open':
        return '🟦 Abierto'
      case 'in-progress':
        return '🟨 En progreso'
      case 'resolved':
        return '🟩 Resuelto'
      case 'closed':
        return '⬜ Cerrado'
      default:
        return status
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'low':
        return styles.priorityLow
      case 'medium':
        return styles.priorityMedium
      case 'high':
        return styles.priorityHigh
      default:
        return styles.priorityMedium
    }
  }

  const getPriorityText = (priority: string) => {
    switch (priority) {
      case 'low':
        return '🔵 Baja'
      case 'medium':
        return '🟡 Media'
      case 'high':
        return '🔴 Alta'
      default:
        return priority
    }
  }

  return (
    <div className={styles.container}>
      {/* Header */}
      <div className={styles.header}>
        <div className={styles.headerTitle}>🎫 Centro de Soporte</div>
        <div className={styles.headerSubtitle}>
          Crea tickets para reportar problemas o hacer consultas
        </div>
      </div>

      {/* Stats */}
      <div className={styles.statsGrid}>
        <div className={styles.statBox}>
          <div className={styles.statValue}>{tickets.length}</div>
          <div className={styles.statLabel}>Tickets totales</div>
        </div>
        <div className={styles.statBox}>
          <div className={styles.statValue}>
            {tickets.filter(t => t.status === 'open' || t.status === 'in-progress').length}
          </div>
          <div className={styles.statLabel}>Activos</div>
        </div>
        <div className={styles.statBox}>
          <div className={styles.statValue}>
            {Math.round(tickets.reduce((acc, t) => acc + t.responses, 0) / tickets.length)}
          </div>
          <div className={styles.statLabel}>Respuestas promedio</div>
        </div>
      </div>

      {/* Create Ticket */}
      <div className={styles.card}>
        <Title3>📝 Crear Nuevo Ticket</Title3>
        
        {success && (
          <div style={{
            background: '#dcf5dd',
            color: '#107c10',
            padding: '12px',
            borderRadius: '6px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            marginTop: '16px',
          }}>
            <CheckmarkCircleRegular />
            <span>Ticket creado exitosamente</span>
          </div>
        )}

        {error && (
          <div style={{
            background: '#fed4d4',
            color: '#a4373a',
            padding: '12px',
            borderRadius: '6px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            marginTop: '16px',
          }}>
            <AlertRegular />
            <span>{error}</span>
          </div>
        )}

        <div className={styles.form}>
          <div className={styles.formGroup}>
            <label className={styles.label}>Título *</label>
            <input
              className={styles.input}
              type="text"
              placeholder="Resumen breve del problema"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </div>

          <div className={styles.formGroup}>
            <label className={styles.label}>Descripción *</label>
            <textarea
              className={styles.textarea}
              placeholder="Describe en detalle tu problema o consulta..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className={styles.formGroup}>
              <label className={styles.label}>Categoría</label>
              <select
                className={styles.select}
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                <option value="technical">🔧 Técnico</option>
                <option value="billing">💳 Facturación</option>
                <option value="account">👤 Cuenta</option>
                <option value="general">❓ General</option>
              </select>
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>Prioridad</label>
              <select
                className={styles.select}
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
              >
                <option value="low">🔵 Baja</option>
                <option value="medium">🟡 Media</option>
                <option value="high">🔴 Alta</option>
              </select>
            </div>
          </div>

          <Button
            className={styles.submitButton}
            onClick={handleSubmit}
            disabled={loading}
          >
            {loading ? <Spinner size="tiny" /> : '✉️ Enviar Ticket'}
          </Button>
        </div>
      </div>

      {/* Tickets History */}
      <div className={styles.card}>
        <Title3>📋 Mis Tickets</Title3>
        
        {tickets.length === 0 ? (
          <div className={styles.emptyState}>
            <div className={styles.emptyIcon}>🎫</div>
            <Body1>No hay tickets aún</Body1>
          </div>
        ) : (
          <div className={styles.ticketsList}>
            {tickets.map((ticket) => (
              <div key={ticket.id} className={styles.ticketItem}>
                <div className={styles.ticketHeader}>
                  <span className={styles.ticketNumber}>{ticket.number}</span>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <span className={`${styles.priorityBadge} ${getPriorityColor(ticket.priority)}`}>
                      {getPriorityText(ticket.priority)}
                    </span>
                    <span className={`${styles.statusBadge} ${getStatusColor(ticket.status)}`}>
                      {getStatusText(ticket.status)}
                    </span>
                  </div>
                </div>
                
                <div className={styles.ticketTitle}>{ticket.title}</div>
                <div className={styles.ticketDescription}>{ticket.description}</div>
                
                <div className={styles.ticketFooter}>
                  <span style={{ fontSize: '12px', color: '#999999' }}>
                    📅 Creado: {ticket.createdDate} | 💬 {ticket.responses} respuestas
                  </span>
                  <Button>Ver detalles →</Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* FAQ Section */}
      <div className={styles.card}>
        <Title3>❓ Preguntas Frecuentes</Title3>
        <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div>
            <strong>¿Cuál es el tiempo de respuesta?</strong>
            <p style={{ marginTop: '4px', opacity: '0.8' }}>
              Respondemos tickets de prioridad alta en menos de 24 horas.
            </p>
          </div>
          <div>
            <strong>¿Cómo rastreo mi ticket?</strong>
            <p style={{ marginTop: '4px', opacity: '0.8' }}>
              Usa el número de ticket para buscar en esta página.
            </p>
          </div>
          <div>
            <strong>¿Qué información debo proporcionar?</strong>
            <p style={{ marginTop: '4px', opacity: '0.8' }}>
              Incluye detalles específicos, screenshots si es posible, y steps para reproducir.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Support
