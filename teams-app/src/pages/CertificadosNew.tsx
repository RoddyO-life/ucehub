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
  DocumentBulletList24Regular,
  ArrowUpload24Regular,
  Checkmark24Regular,
  DocumentPdf24Regular
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
    backgroundColor: tokens.colorPaletteRoyalBlueBackground2,
    ...shorthands.borderRadius('12px'),
    color: 'white',
    marginBottom: '24px'
  },
  formCard: {
    ...shorthands.padding('24px')
  },
  fileUpload: {
    ...shorthands.border('2px', 'dashed', tokens.colorBrandStroke1),
    ...shorthands.padding('24px'),
    ...shorthands.borderRadius('8px'),
    textAlign: 'center',
    cursor: 'pointer',
    backgroundColor: tokens.colorNeutralBackground2,
    '&:hover': {
      backgroundColor: tokens.colorNeutralBackground3
    }
  },
  fileSelected: {
    display: 'flex',
    alignItems: 'center',
    ...shorthands.gap('12px'),
    ...shorthands.padding('12px'),
    backgroundColor: tokens.colorPaletteGreenBackground3,
    ...shorthands.borderRadius('8px'),
    color: 'white'
  },
  successMessage: {
    textAlign: 'center',
    ...shorthands.padding('40px'),
    backgroundColor: tokens.colorPaletteGreenBackground3,
    ...shorthands.borderRadius('12px'),
    color: 'white'
  }
})

export default function CertificadosNew() {
  const styles = useStyles()
  const [formData, setFormData] = useState({
    userName: '',
    userEmail: '',
    reason: '',
    startDate: '',
    endDate: ''
  })
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [documentBase64, setDocumentBase64] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [justificationId, setJustificationId] = useState('')

  // Get API URL from environment or use ALB endpoint
  const API_URL = import.meta.env.VITE_API_URL || 
                 import.meta.env.VITE_BACKEND_URL ||
                 'http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com' ||
                 'http://localhost:3001'

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      if (file.type !== 'application/pdf') {
        alert('Por favor selecciona un archivo PDF')
        return
      }
      if (file.size > 5 * 1024 * 1024) {
        alert('El archivo no debe superar 5MB')
        return
      }

      setSelectedFile(file)
      
      // Convert to base64
      const reader = new FileReader()
      reader.onloadend = () => {
        setDocumentBase64(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.userName || !formData.userEmail || !formData.reason || !formData.startDate || !formData.endDate) {
      alert('Por favor completa todos los campos requeridos')
      return
    }

    if (!selectedFile) {
      alert('Por favor adjunta un documento PDF')
      return
    }

    setSubmitting(true)
    try {
      const payload = {
        ...formData,
        documentBase64,
        documentName: selectedFile.name
      }

      const response = await axios.post(`${API_URL}/justifications/submit`, payload)
      setJustificationId(response.data.data.justificationId)
      setSubmitted(true)
    } catch (error) {
      console.error('Error submitting justification:', error)
      alert('Error al enviar la justificación. Por favor intenta nuevamente.')
    } finally {
      setSubmitting(false)
    }
  }

  const resetForm = () => {
    setFormData({
      userName: '',
      userEmail: '',
      reason: '',
      startDate: '',
      endDate: ''
    })
    setSelectedFile(null)
    setDocumentBase64('')
    setSubmitted(false)
    setJustificationId('')
  }

  if (submitted) {
    return (
      <div className={styles.container}>
        <Card className={styles.successMessage}>
          <Checkmark24Regular style={{ fontSize: '64px', marginBottom: '16px' }} />
          <Title3 style={{ marginBottom: '16px' }}>¡Justificación Enviada!</Title3>
          <Subtitle2>ID: {justificationId}</Subtitle2>
          <p style={{ marginTop: '16px', opacity: 0.9 }}>
            Tu justificación ha sido enviada a rjortega@uce.edu.ec
          </p>
          <p style={{ opacity: 0.9 }}>
            Recibirás una respuesta en tu correo electrónico
          </p>
          <Button
            appearance="secondary"
            onClick={resetForm}
            style={{ marginTop: '24px', backgroundColor: 'white', color: tokens.colorBrandForeground1 }}
          >
            Enviar Otra Justificación
          </Button>
        </Card>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <Title3 style={{ marginBottom: '8px' }}>
          <DocumentBulletList24Regular /> Justificar Falta
        </Title3>
        <Subtitle2>Envía tu justificación de ausencia con documento</Subtitle2>
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

          <Field label="Motivo de la ausencia" required style={{ marginTop: '16px' }}>
            <Textarea
              value={formData.reason}
              onChange={(_, data) => setFormData({ ...formData, reason: data.value })}
              placeholder="Describe el motivo de tu ausencia..."
              rows={4}
              required
            />
          </Field>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginTop: '16px' }}>
            <Field label="Fecha de inicio" required>
              <Input
                value={formData.startDate}
                onChange={(_, data) => setFormData({ ...formData, startDate: data.value })}
                type="date"
                required
              />
            </Field>

            <Field label="Fecha de fin" required>
              <Input
                value={formData.endDate}
                onChange={(_, data) => setFormData({ ...formData, endDate: data.value })}
                type="date"
                required
              />
            </Field>
          </div>

          <Field label="Documento PDF (Certificado médico u otro)" required style={{ marginTop: '16px' }}>
            {!selectedFile ? (
              <label className={styles.fileUpload}>
                <input
                  type="file"
                  accept="application/pdf"
                  onChange={handleFileChange}
                  style={{ display: 'none' }}
                />
                <ArrowUpload24Regular style={{ fontSize: '48px', color: tokens.colorBrandForeground1 }} />
                <Subtitle2>Haz clic para subir un archivo PDF</Subtitle2>
                <p style={{ fontSize: '12px', color: tokens.colorNeutralForeground3, marginTop: '8px' }}>
                  Tamaño máximo: 5MB
                </p>
              </label>
            ) : (
              <div className={styles.fileSelected}>
                <DocumentPdf24Regular fontSize={24} />
                <div style={{ flex: 1 }}>
                  <Subtitle2>{selectedFile.name}</Subtitle2>
                  <p style={{ fontSize: '12px', opacity: 0.9 }}>
                    {(selectedFile.size / 1024).toFixed(2)} KB
                  </p>
                </div>
                <Button
                  appearance="secondary"
                  onClick={() => {
                    setSelectedFile(null)
                    setDocumentBase64('')
                  }}
                  style={{ backgroundColor: 'white', color: tokens.colorBrandForeground1 }}
                >
                  Cambiar
                </Button>
              </div>
            )}
          </Field>

          <div style={{ marginTop: '24px', padding: '16px', backgroundColor: tokens.colorNeutralBackground2, borderRadius: '8px' }}>
            <Subtitle2>📧 Notificación</Subtitle2>
            <p style={{ fontSize: '14px', marginTop: '8px', color: tokens.colorNeutralForeground3 }}>
              Se enviará un correo electrónico a <strong>rjortega@uce.edu.ec</strong> con tu justificación y el documento adjunto.
            </p>
          </div>

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
              icon={<DocumentBulletList24Regular />}
              type="submit"
              disabled={submitting}
            >
              {submitting ? <Spinner size="tiny" /> : 'Enviar Justificación'}
            </Button>
          </div>
        </form>
      </Card>
    </div>
  )
}
