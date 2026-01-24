import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
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
  Spinner,
  Body1,
} from '@fluentui/react-components'
import {
  DocumentBulletList24Regular,
  ArrowUpload24Regular,
  Checkmark24Regular,
  DocumentPdf24Regular,
  ArrowLeftRegular,
} from '@fluentui/react-icons'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    padding: '24px',
    backgroundColor: 'transparent',
    minHeight: '100vh',
    maxWidth: '1200px',
    margin: '0 auto',
    display: 'flex',
    flexDirection: 'column',
    gap: '24px',
  },
  header: {
    textAlign: 'center',
    padding: '40px',
    backgroundColor: 'rgba(20, 20, 20, 0.4)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    marginBottom: '24px',
  },
  headerTitle: {
    fontSize: '32px',
    fontWeight: '800',
    background: 'linear-gradient(135deg, #FFB800 0%, #FF6B00 100%)',
    '-webkit-background-clip': 'text',
    '-webkit-text-fill-color': 'transparent',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '12px',
  },
  headerSubtitle: {
    color: '#aaa',
    fontSize: '16px',
    marginTop: '8px',
  },
  formCard: {
    padding: '32px',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    borderRadius: '16px',
    backdropFilter: 'blur(16px)',
  },
  fileUpload: {
    border: '2px dashed rgba(255, 184, 0, 0.3)',
    padding: '32px',
    borderRadius: '12px',
    textAlign: 'center',
    cursor: 'pointer',
    backgroundColor: 'rgba(255, 184, 0, 0.03)',
    transition: 'all 0.3s ease',
    '&:hover': {
      backgroundColor: 'rgba(255, 184, 0, 0.06)',
      borderColor: '#FFB800',
    }
  },
  fileSelected: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    padding: '16px',
    backgroundColor: 'rgba(0, 183, 117, 0.1)',
    borderRadius: '10px',
    border: '1px solid rgba(0, 183, 117, 0.2)',
    color: '#00B775',
  },
  successMessage: {
    textAlign: 'center',
    padding: '60px',
    backgroundColor: 'rgba(0, 183, 117, 0.05)',
    border: '1px solid rgba(0, 183, 117, 0.2)',
    borderRadius: '20px',
    color: '#fff',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '20px',
    '@media (max-width: 600px)': {
      gridTemplateColumns: '1fr',
    }
  },
  input: {
    backgroundColor: 'rgba(255, 255, 255, 0.05) !important',
    color: '#fff !important',
    borderRadius: '8px !important',
    border: '1px solid rgba(255, 255, 255, 0.1) !important',
  },
  submitButton: {
    background: 'linear-gradient(135deg, #FFB800 0%, #FF6B00 100%)',
    color: '#000',
    fontWeight: '700',
    padding: '12px 32px',
    borderRadius: '10px',
    border: 'none',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    marginTop: '20px',
    width: '100%',
    '&:hover': {
      boxShadow: '0 0 20px rgba(255, 184, 0, 0.3)',
      transform: 'translateY(-2px)',
    }
  },
  backButton: {
    background: 'rgba(255, 255, 255, 0.05)',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    color: '#fff',
    padding: '10px 20px',
    borderRadius: '12px',
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: '600',
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    transition: 'all 0.3s ease',
    alignSelf: 'flex-start',
    '&:hover': {
      background: 'rgba(255, 255, 255, 0.1)',
      borderColor: '#FFB800',
      transform: 'translateX(-5px)',
    }
  }
})

export default function CertificadosNew() {
  const styles = useStyles()
  const navigate = useNavigate()
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
        <div className={styles.successMessage}>
          <Checkmark24Regular style={{ fontSize: '64px', marginBottom: '16px', color: '#00B775' }} />
          <h2 style={{ fontSize: '28px', fontWeight: '800', marginBottom: '16px' }}>¡Solicitud Enviada!</h2>
          <Body1 style={{ fontSize: '18px', color: '#aaa', display: 'block' }}>ID Seguimiento: {justificationId}</Body1>
          <p style={{ marginTop: '24px', color: '#ccc', lineHeight: '1.6' }}>
            Tu solicitud de certificado/justificación ha sido enviada con éxito.<br/>
            Un revisor académico procesará tu pedido en las próximas 24-48 horas.
          </p>
          <div style={{ display: 'flex', gap: '12px', justifyContent: 'center', marginTop: '32px' }}>
            <Button
              appearance="primary"
              onClick={resetForm}
              style={{ background: '#FFB800', color: '#000', fontWeight: 'bold' }}
            >
              Nueva Solicitud
            </Button>
            <Button
                appearance="outline"
                onClick={() => navigate('/')}
                style={{ color: '#fff', borderColor: 'rgba(255,255,255,0.2)' }}
            >
                Volver al Inicio
            </Button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <button className={styles.backButton} onClick={() => navigate('/')}>
        <ArrowLeftRegular /> Volver al Inicio
      </button>

      <div className={styles.header}>
        <h1 className={styles.headerTitle}>
          <DocumentBulletList24Regular style={{ color: '#FFB800' }} /> Certificados y Justificaciones
        </h1>
        <p className={styles.headerSubtitle}>Portal de gestión académica automatizada de la UCE</p>
      </div>

      <div className={styles.formCard}>
        <form onSubmit={handleSubmit}>
          <div className={styles.grid}>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ color: '#aaa', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Nombre Completo</label>
              <Input
                className={styles.input}
                style={{ width: '100%' }}
                value={formData.userName}
                onChange={(_, data) => setFormData({ ...formData, userName: data.value })}
                placeholder="Ej. Juan Pérez"
              />
            </div>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ color: '#aaa', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Correo Institucional</label>
              <Input
                className={styles.input}
                style={{ width: '100%' }}
                type="email"
                value={formData.userEmail}
                onChange={(_, data) => setFormData({ ...formData, userEmail: data.value })}
                placeholder="ejemplo@uce.edu.ec"
              />
            </div>
          </div>

          <div style={{ marginBottom: '20px' }}>
            <label style={{ color: '#aaa', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Tipo de Solicitud / Motivo</label>
            <Textarea
              className={styles.input}
              style={{ width: '100%' }}
              value={formData.reason}
              onChange={(_, data) => setFormData({ ...formData, reason: data.value })}
              placeholder="Describe brevemente tu requerimiento..."
              rows={4}
            />
          </div>

          <div className={styles.grid}>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ color: '#aaa', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Fecha Inicio</label>
              <Input
                className={styles.input}
                style={{ width: '100%' }}
                type="date"
                value={formData.startDate}
                onChange={(_, data) => setFormData({ ...formData, startDate: data.value })}
              />
            </div>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ color: '#aaa', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Fecha Fin</label>
              <Input
                className={styles.input}
                style={{ width: '100%' }}
                type="date"
                value={formData.endDate}
                onChange={(_, data) => setFormData({ ...formData, endDate: data.value })}
              />
            </div>
          </div>

          <div style={{ margin: '24px 0' }}>
            <label style={{ color: '#aaa', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Documento de Respaldo (PDF)</label>
            {!selectedFile ? (
              <div 
                className={styles.fileUpload}
                onClick={() => document.getElementById('fileInput')?.click()}
              >
                <ArrowUpload24Regular style={{ fontSize: '32px', marginBottom: '12px', color: '#FFB800' }} />
                <div style={{ color: '#fff', fontWeight: '600' }}>Cargar Documento PDF</div>
                <div style={{ color: '#666', fontSize: '12px', marginTop: '4px' }}>Máximo 5MB</div>
                <input
                  id="fileInput"
                  type="file"
                  hidden
                  accept=".pdf"
                  onChange={handleFileChange}
                />
              </div>
            ) : (
              <div className={styles.fileSelected}>
                <DocumentPdf24Regular style={{ fontSize: '24px' }} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 'bold' }}>{selectedFile.name}</div>
                  <div style={{ fontSize: '12px', opacity: 0.8 }}>{(selectedFile.size / 1024 / 1024).toFixed(2)} MB</div>
                </div>
                <Button 
                  appearance="subtle" 
                  onClick={() => setSelectedFile(null)}
                  style={{ color: '#ff4d4d' }}
                >
                  Quitar
                </Button>
              </div>
            )}
          </div>

          <button 
            type="submit" 
            className={styles.submitButton}
            disabled={submitting}
          >
            {submitting ? (
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' }}>
                <Spinner size="tiny" labelPosition="after" /> Enviando...
              </div>
            ) : 'Enviar Solicitud'}
          </button>
        </form>
      </div>
    </div>
  )
}
