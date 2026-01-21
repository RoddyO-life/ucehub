import { useState } from 'react'
import {
  Button,
  Card,
  Title3,
  Subtitle2,
  tokens,
  makeStyles,
  shorthands,
  Input,
  Textarea,
  Field,
  Spinner
} from '@fluentui/react-components'
import {
  QuestionCircle24Regular,
  Send24Regular,
  Checkmark24Regular
} from '@fluentui/react-icons'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    ...shorthands.padding('24px'),
    backgroundColor: tokens.colorNeutralBackground3,
    minHeight: '100vh',
    maxWidth: '800px',
    margin: '0 auto'
  },
  header: {
    textAlign: 'center',
    ...shorthands.padding('20px'),
    backgroundColor: tokens.colorPaletteGoldBackground2,
    ...shorthands.borderRadius('12px'),
    color: 'white',
    marginBottom: '24px'
  },
  formCard: {
    ...shorthands.padding('24px')
  },
  successMessage: {
    textAlign: 'center',
    ...shorthands.padding('40px'),
    backgroundColor: tokens.colorPaletteGreenBackground3,
    ...shorthands.borderRadius('12px'),
    color: 'white'
  }
})

export default function SoporteNew() {
  const styles = useStyles()
  const [formData, setFormData] = useState({
    userName: '',
    userEmail: '',
    category: 'tecnico',
    subject: '',
    description: '',
    priority: 'medium'
  })
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [ticketId, setTicketId] = useState('')

  const API_URL = import.meta.env.VITE_API_URL || 
                 import.meta.env.VITE_BACKEND_URL ||
                 'http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com' ||
                 'http://localhost:3001'

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.userName || !formData.userEmail || !formData.subject || !formData.description) {
      alert('Por favor completa todos los campos requeridos')
      return
    }

    setSubmitting(true)
    try {
      const response = await axios.post(`${API_URL}/support/ticket`, formData)
      setTicketId(response.data.data.ticketId)
      setSubmitted(true)
    } catch (error) {
      console.error('Error submitting ticket:', error)
      alert('Error al enviar el ticket. Por favor intenta nuevamente.')
    } finally {
      setSubmitting(false)
    }
  }

  const resetForm = () => {
    setFormData({
      userName: '',
      userEmail: '',
      category: 'tecnico',
      subject: '',
      description: '',
      priority: 'medium'
    })
    setSubmitted(false)
    setTicketId('')
  }

  if (submitted) {
    return (
      <div className={styles.container}>
        <Card className={styles.successMessage}>
          <Checkmark24Regular style={{ fontSize: '64px', marginBottom: '16px' }} />
          <Title3 style={{ marginBottom: '16px' }}>¡Ticket Enviado!</Title3>
          <Subtitle2>ID del Ticket: {ticketId}</Subtitle2>
          <p style={{ marginTop: '16px', opacity: 0.9 }}>
            Recibirás una respuesta en tu correo electrónico
          </p>
          <Button
            appearance="secondary"
            onClick={resetForm}
            style={{ marginTop: '24px', backgroundColor: 'white', color: tokens.colorBrandForeground1 }}
          >
            Enviar Otro Ticket
          </Button>
        </Card>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <Title3 style={{ marginBottom: '8px' }}>
          <QuestionCircle24Regular /> Soporte Técnico
        </Title3>
        <Subtitle2>Envía tu consulta o reporte de problema</Subtitle2>
      </div>

      <Card className={styles.formCard}>
        <form onSubmit={handleSubmit}>
          <Field label="Nombre completo" required>
            <Input
              value={formData.userName}
              onChange={(_, data) => setFormData({ ...formData, userName: data.value })}
              placeholder="Tu nombre"
              required
            />
          </Field>

          <Field label="Email" required style={{ marginTop: '16px' }}>
            <Input
              value={formData.userEmail}
              onChange={(_, data) => setFormData({ ...formData, userEmail: data.value })}
              placeholder="tu@email.com"
              type="email"
              required
            />
          </Field>

          <Field label="Categoría" required style={{ marginTop: '16px' }}>
            <select
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              style={{ width: '100%', padding: '8px', borderRadius: '4px', border: '1px solid #ccc' }}
            >
              <option value="tecnico">Problema Técnico</option>
              <option value="acceso">Problemas de Acceso</option>
              <option value="academico">Consulta Académica</option>
              <option value="administrativo">Trámite Administrativo</option>
              <option value="otro">Otro</option>
            </select>
          </Field>

          <Field label="Prioridad" style={{ marginTop: '16px' }}>
            <select
              value={formData.priority}
              onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
              style={{ width: '100%', padding: '8px', borderRadius: '4px', border: '1px solid #ccc' }}
            >
              <option value="low">Baja</option>
              <option value="medium">Media</option>
              <option value="high">Alta</option>
              <option value="urgent">Urgente</option>
            </select>
          </Field>

          <Field label="Asunto" required style={{ marginTop: '16px' }}>
            <Input
              value={formData.subject}
              onChange={(_, data) => setFormData({ ...formData, subject: data.value })}
              placeholder="Breve descripción del problema"
              required
            />
          </Field>

          <Field label="Descripción detallada" required style={{ marginTop: '16px' }}>
            <Textarea
              value={formData.description}
              onChange={(_, data) => setFormData({ ...formData, description: data.value })}
              placeholder="Describe tu problema o consulta con el mayor detalle posible..."
              rows={6}
              required
            />
          </Field>

          <div style={{ marginTop: '24px', display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
            <Button
              appearance="secondary"
              onClick={resetForm}
              type="button"
            >
              Limpiar
            </Button>
            <Button
              appearance="primary"
              icon={<Send24Regular />}
              type="submit"
              disabled={submitting}
            >
              {submitting ? <Spinner size="tiny" /> : 'Enviar Ticket'}
            </Button>
          </div>
        </form>
      </Card>
    </div>
  )
}
