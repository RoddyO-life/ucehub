import React, { useState, useRef } from 'react'
import {
  makeStyles,
  Button,
  Spinner,
} from '@fluentui/react-components'
import {
  CheckmarkCircleRegular,
  AlertRegular,
  Delete20Regular,
  CloudAddRegular,
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
  uploadBox: {
    border: '2px dashed #667eea',
    borderRadius: '8px',
    padding: '40px',
    textAlign: 'center',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    backgroundColor: 'rgba(102, 126, 234, 0.05)',
    ':hover': {
      backgroundColor: 'rgba(102, 126, 234, 0.1)',
    },
  },
  uploadIcon: {
    fontSize: '48px',
    color: '#667eea',
    marginBottom: '16px',
  },
  fileInput: {
    display: 'none',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '16px',
    marginTop: '20px',
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
    transition: 'border-color 0.2s',
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
    minHeight: '100px',
    resize: 'vertical',
  },
  filePreview: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    padding: '12px',
    backgroundColor: '#f0f4ff',
    borderRadius: '6px',
    border: '1px solid #667eea',
  },
  filePreviewText: {
    flex: 1,
    fontSize: '14px',
    color: '#333333',
  },
  removeFileBtn: {
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    color: '#d13438',
    padding: '4px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
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
  justificationsList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
    marginTop: '16px',
  },
  justificationItem: {
    background: 'rgba(255, 255, 255, 0.8)',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    padding: '16px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    transition: 'all 0.2s',
    ':hover': {
      boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)',
    },
  },
  justificationStatus: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
  statusBadge: {
    padding: '4px 12px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '600',
  },
  statusApproved: {
    background: '#dcf5dd',
    color: '#107c10',
  },
  statusPending: {
    background: '#fff4ce',
    color: '#b86f00',
  },
  statusRejected: {
    background: '#fed4d4',
    color: '#a4373a',
  },
  actionButtons: {
    display: 'flex',
    gap: '8px',
  },
  viewButton: {
    background: '#667eea',
    color: '#ffffff',
    border: 'none',
    padding: '8px 16px',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
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
})

interface Justification {
  id: string
  date: string
  reason: string
  documentUrl: string
  status: 'pending' | 'approved' | 'rejected'
  comments?: string
}

export const Justifications: React.FC = () => {
  const styles = useStyles()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [reason, setReason] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [justifications] = useState<Justification[]>([
    {
      id: '1',
      date: '2024-01-10 - 2024-01-12',
      reason: 'Cita médica',
      documentUrl: '/documents/1.pdf',
      status: 'approved',
      comments: 'Aprobado. Documentación válida.'
    },
    {
      id: '2',
      date: '2024-01-15',
      reason: 'Problemas familiares',
      documentUrl: '/documents/2.pdf',
      status: 'pending',
      comments: ''
    },
  ])

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      if (file.size > 10 * 1024 * 1024) {
        setError('Archivo muy grande. Máximo 10 MB.')
        return
      }
      if (file.type !== 'application/pdf') {
        setError('Solo se aceptan archivos PDF.')
        return
      }
      setSelectedFile(file)
      setError('')
    }
  }

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    const file = e.dataTransfer.files?.[0]
    if (file) {
      handleFileSelect({ target: { files: e.dataTransfer.files } } as any)
    }
  }

  const handleSubmit = async () => {
    if (!selectedFile || !reason || !startDate) {
      setError('Por favor completa todos los campos.')
      return
    }

    setLoading(true)
    try {
      // Read file as base64
      const reader = new FileReader()
      reader.onload = async () => {
        try {
          const base64String = reader.result as string
          
          const apiUrl = import.meta.env.VITE_API_URL
          await axios.post(`${apiUrl}/justifications/submit`, {
            reason,
            startDate,
            endDate: endDate || startDate,
            userEmail: 'user@ucehub.edu.ec',
            userName: 'Estudiante',
            documentBase64: base64String,
            documentName: selectedFile.name
          }, {
            headers: { 'Content-Type': 'application/json' }
          })

          setSuccess(true)
          setSelectedFile(null)
          setReason('')
          setStartDate('')
          setEndDate('')
          
          setTimeout(() => setSuccess(false), 3000)
        } catch (err: any) {
          setError(err.response?.data?.error || 'Error al enviar justificación.')
          setLoading(false)
        }
      }
      reader.readAsDataURL(selectedFile)
    } catch (err: any) {
      setError(err.response?.data?.error || 'Error al procesar archivo.')
      setLoading(false)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved':
        return styles.statusApproved
      case 'rejected':
        return styles.statusRejected
      default:
        return styles.statusPending
    }
  }

  const getStatusText = (status: string) => {
    switch (status) {
      case 'approved':
        return '✓ Aprobada'
      case 'rejected':
        return '✗ Rechazada'
      default:
        return '⏳ Pendiente'
    }
  }

  return (
    <div className={styles.container}>
      {/* Header */}
      <div className={styles.header}>
        <div className={styles.headerTitle}>📄 Mis Justificaciones</div>
        <div className={styles.headerSubtitle}>
          Carga documentos para justificar tus ausencias
        </div>
      </div>

      {/* Upload Card */}
      <div className={styles.card}>
        <div style={{ fontSize: '20px', fontWeight: '600', marginBottom: '12px' }}>Agregar Nueva Justificación</div>
        
        {success && (
          <div style={{
            background: '#dcf5dd',
            color: '#107c10',
            padding: '12px',
            borderRadius: '6px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            marginBottom: '16px',
            marginTop: '16px',
          }}>
            <CheckmarkCircleRegular />
            <span>Justificación enviada exitosamente</span>
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
            marginBottom: '16px',
            marginTop: '16px',
          }}>
            <AlertRegular />
            <span>{error}</span>
          </div>
        )}

        {/* File Upload */}
        <div
          className={styles.uploadBox}
          onClick={() => fileInputRef.current?.click()}
          onDrop={handleDrop}
          onDragOver={(e) => e.preventDefault()}
        >
          <div className={styles.uploadIcon}>
            <CloudAddRegular fontSize={48} />
          </div>
          <Body1 style={{ fontWeight: '600', marginBottom: '4px' }}>
            Arrastra tu PDF aquí o haz clic
          </Body1>
          <Body1 style={{ fontSize: '12px', opacity: '0.7' }}>
            Máximo 10 MB. Solo archivos PDF.
          </Body1>
          <input
            ref={fileInputRef}
            className={styles.fileInput}
            type="file"
            accept=".pdf"
            onChange={handleFileSelect}
          />
        </div>

        {selectedFile && (
          <div className={styles.filePreview}>
            <span className={styles.filePreviewText}>
              📎 {selectedFile.name} ({(selectedFile.size / 1024 / 1024).toFixed(2)} MB)
            </span>
            <button
              className={styles.removeFileBtn}
              onClick={() => setSelectedFile(null)}
            >
              <Delete20Regular />
            </button>
          </div>
        )}

        {/* Form */}
        <div className={styles.form}>
          <div className={styles.formGroup}>
            <label className={styles.label}>Motivo de la ausencia *</label>
            <textarea
              className={styles.textarea}
              placeholder="Describe el motivo de tu ausencia"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className={styles.formGroup}>
              <label className={styles.label}>Fecha de inicio *</label>
              <input
                className={styles.input}
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>Fecha de fin (opcional)</label>
              <input
                className={styles.input}
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </div>
          </div>

          <Button
            className={styles.submitButton}
            onClick={handleSubmit}
            disabled={loading}
          >
            {loading ? <Spinner size="tiny" /> : '📤 Enviar Justificación'}
          </Button>
        </div>
      </div>

      {/* History */}
      <div className={styles.card}>
        <div style={{ fontSize: '20px', fontWeight: '600', marginBottom: '12px' }}>Historial de Justificaciones</div>
        
        {justifications.length === 0 ? (
          <div className={styles.emptyState}>
            <div className={styles.emptyIcon}>📭</div>
            <div>No hay justificaciones registradas aún</div>
          </div>
        ) : (
          <div className={styles.justificationsList}>
            {justifications.map((j) => (
              <div key={j.id} className={styles.justificationItem}>
                <div style={{ flex: 1 }}>
                  <div style={{ marginBottom: '8px' }}>
                    <strong>{j.reason}</strong>
                    <span style={{ opacity: '0.6', marginLeft: '12px', fontSize: '12px' }}>
                      {j.date}
                    </span>
                  </div>
                  {j.comments && (
                    <div style={{ fontSize: '12px', color: '#666666' }}>
                      {j.comments}
                    </div>
                  )}
                </div>
                <div className={styles.justificationStatus}>
                  <span className={`${styles.statusBadge} ${getStatusColor(j.status)}`}>
                    {getStatusText(j.status)}
                  </span>
                  <button
                    className={styles.viewButton}
                    onClick={() => window.open(j.documentUrl, '_blank')}
                  >
                    Ver PDF
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default Justifications
