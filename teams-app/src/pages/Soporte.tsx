import { useState } from 'react'
import {
  makeStyles,
  Button,
  Card,
  Title2,
  Title3,
  Body1,
  tokens,
  Spinner,
  Input,
  Textarea,
  Dropdown,
  Option,
} from '@fluentui/react-components'
import {
  PersonRegular,
  SendRegular
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    padding: '20px',
    maxWidth: '800px',
    margin: '0 auto',
  },
  header: {
    marginBottom: '30px',
    display: 'flex',
    alignItems: 'center',
    gap: '15px',
  },
  icon: {
    fontSize: '40px',
    color: tokens.colorBrandForeground1,
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
  },
  backButton: {
    marginBottom: '20px',
  },
})

const Soporte = () => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [formData, setFormData] = useState({
    categoria: '',
    asunto: '',
    descripcion: ''
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setMessage('')

    try {
      const apiUrl = import.meta.env.VITE_API_URL
      const response = await axios.post(`${apiUrl}/soporte/ticket`, formData)

      setMessage('Ticket creado exitosamente! Número: #' + response.data.ticketId)
      setFormData({ categoria: '', asunto: '', descripcion: '' })
    } catch (error) {
      setMessage('Error al crear el ticket de soporte')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.container}>
      <Button 
        className={styles.backButton}
        onClick={() => navigate('/')}
      >
        ← Volver
      </Button>

      <div className={styles.header}>
        <PersonRegular className={styles.icon} />
        <div>
          <Title2>Soporte Técnico</Title2>
          <Body1>Crea un ticket de soporte para resolver tus problemas</Body1>
        </div>
      </div>

      {message && (
        <Card style={{ marginBottom: '20px', padding: '15px', backgroundColor: tokens.colorPaletteGreenBackground2 }}>
          <Body1>{message}</Body1>
        </Card>
      )}

      <Card style={{ padding: '30px' }}>
        <Title3 style={{ marginBottom: '20px' }}>Nuevo Ticket de Soporte</Title3>
        <form className={styles.form} onSubmit={handleSubmit}>
          <div>
            <Body1 style={{ marginBottom: '8px' }}><strong>Categoría</strong></Body1>
            <Dropdown
              placeholder="Selecciona una categoría"
              value={formData.categoria}
              onOptionSelect={(_: any, data: any) => setFormData({ ...formData, categoria: data.optionValue as string })}
              style={{ width: '100%' }}
            >
              <Option value="plataforma">Plataforma Virtual</Option>
              <Option value="correo">Correo Institucional</Option>
              <Option value="wifi">Red WiFi</Option>
              <Option value="laboratorio">Laboratorio de Cómputo</Option>
              <Option value="otro">Otro</Option>
            </Dropdown>
          </div>

          <div>
            <Body1 style={{ marginBottom: '8px' }}><strong>Asunto</strong></Body1>
            <Input
              placeholder="Describe brevemente el problema"
              value={formData.asunto}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => 
                setFormData({ ...formData, asunto: e.target.value })
              }
              required
            />
          </div>

          <div>
            <Body1 style={{ marginBottom: '8px' }}><strong>Descripción Detallada</strong></Body1>
            <Textarea
              placeholder="Describe el problema con el mayor detalle posible..."
              value={formData.descripcion}
              onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => 
                setFormData({ ...formData, descripcion: e.target.value })
              }
              rows={6}
              required
            />
          </div>

          <Button
            appearance="primary"
            icon={<SendRegular />}
            type="submit"
            disabled={loading}
            style={{ width: 'fit-content' }}
          >
            {loading ? <Spinner size="tiny" /> : 'Enviar Ticket'}
          </Button>
        </form>
      </Card>
    </div>
  )
}

export default Soporte
