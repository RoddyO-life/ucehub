import React, { useState, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  makeStyles,
  shorthands,
  Button,
  Spinner,
} from '@fluentui/react-components'
import {
  CheckmarkCircleRegular,
  AlertRegular,
  Delete20Regular,
  CloudAddRegular,
  ArrowLeftRegular,
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
    background: 'transparent',
  },
  header: {
    color: '#ffffff',
    marginBottom: '16px',
    textAlign: 'center',
  },
  headerTitle: {
    fontSize: '32px',
    fontWeight: '800',
    marginBottom: '8px',
    background: 'linear-gradient(135deg, #FFB800 0%, #FF6B00 100%)',
    '-webkit-background-clip': 'text',
    '-webkit-text-fill-color': 'transparent',
  },
  headerSubtitle: {
    fontSize: '16px',
    opacity: '0.9',
    color: '#aaa',
  },
  card: {
    background: 'rgba(20, 20, 20, 0.6)',
    backdropFilter: 'blur(16px)',
    borderRadius: '16px',
    padding: '24px',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
  },
  uploadBox: {
    ...shorthands.border('2px', 'dashed', 'rgba(255, 184, 0, 0.3)'),
    ...shorthands.borderRadius('12px'),
    ...shorthands.padding('40px'),
    textAlign: 'center',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    backgroundColor: 'rgba(255, 184, 0, 0.02)',
    '&:hover': {
      backgroundColor: 'rgba(255, 184, 0, 0.05)',
      ...shorthands.borderColor('#FFB800'),
    },
  },
  uploadIcon: {
    fontSize: '48px',
    color: '#FFB800',
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
    color: '#FFB800',
    fontSize: '14px',
  },
  input: {
    ...shorthands.padding('12px'),
    background: 'rgba(255, 255, 255, 0.05)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.1)'),
    ...shorthands.borderRadius('8px'),
    fontSize: '14px',
    color: '#fff',
    fontFamily: 'inherit',
    transition: 'all 0.3s ease',
    '&:focus': {
      outline: 'none',
      ...shorthands.borderColor('#FFB800'),
    },
  },
  textarea: {
    ...shorthands.padding('12px'),
    background: 'rgba(255, 255, 255, 0.05)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.1)'),
    ...shorthands.borderRadius('8px'),
    fontSize: '14px',
    color: '#fff',
    fontFamily: 'inherit',
    minHeight: '100px',
    resize: 'vertical',
    transition: 'all 0.3s ease',
    '&:focus': {
      outline: 'none',
      ...shorthands.borderColor('#FFB800'),
    },
  },
  filePreview: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    ...shorthands.padding('12px'),
    backgroundColor: 'rgba(255, 184, 0, 0.05)',
    ...shorthands.borderRadius('8px'),
    ...shorthands.border('1px', 'solid', 'rgba(255, 184, 0, 0.2)'),
  },
  filePreviewText: {
    flex: 1,
    fontSize: '14px',
    color: '#ffffff',
  },
  removeFileBtn: {
    background: 'none',
    ...shorthands.border('none'),
    cursor: 'pointer',
    color: '#FF3B30',
    ...shorthands.padding('4px'),
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  submitButton: {
    background: 'linear-gradient(135deg, #FF9E00 0%, #FF6B00 100%)',
    color: '#000',
    ...shorthands.border('none'),
    ...shorthands.padding('14px', '28px'),
    ...shorthands.borderRadius('8px'),
    fontWeight: '700',
    fontSize: '15px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    '&:hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 8px 20px rgba(255, 158, 0, 0.4)',
    },
    '&:disabled': {
      opacity: '0.4',
      cursor: 'not-allowed',
    },
  },
  justificationsList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
    marginTop: '20px',
  },
  justificationItem: {
    background: 'rgba(255, 255, 255, 0.03)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.05)'),
    ...shorthands.borderRadius('12px'),
    ...shorthands.padding('16px'),
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    transition: 'all 0.3s ease',
    '&:hover': {
        background: 'rgba(255, 255, 255, 0.06)',
        ...shorthands.borderColor('rgba(255, 184, 0, 0.3)'),
        transform: 'translateX(5px)',
    }
  },
  justificationStatus: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
  statusBadge: {
    ...shorthands.padding('4px', '12px'),
    ...shorthands.borderRadius('12px'),
    fontSize: '12px',
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  statusApproved: {
    background: 'rgba(0, 255, 136, 0.1)',
    color: '#00FF88',
  },
  statusPending: {
    background: 'rgba(255, 184, 0, 0.1)',
    color: '#FFB800',
  },
  statusRejected: {
    background: 'rgba(255, 59, 48, 0.1)',
    color: '#FF3B30',
  },
  actionButtons: {
    display: 'flex',
    gap: '8px',
  },
  viewButton: {
    background: 'rgba(255, 184, 0, 0.1)',
    color: '#FFB800',
    ...shorthands.border('1px', 'solid', 'rgba(255, 184, 0, 0.2)'),
    ...shorthands.padding('8px', '16px'),
    ...shorthands.borderRadius('8px'),
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
    transition: 'all 0.2s',
    '&:hover': {
      background: 'rgba(255, 184, 0, 0.2)',
    },
  },
  emptyState: {
    textAlign: 'center',
    ...shorthands.padding('40px', '20px'),
    background: 'rgba(255, 255, 255, 0.02)',
    ...shorthands.borderRadius('16px'),
    ...shorthands.border('1px', 'dashed', 'rgba(255, 255, 255, 0.1)'),
    color: '#888',
  },
  emptyIcon: {
    fontSize: '48px',
    marginBottom: '16px',
    opacity: '0.5',
    color: '#FFB800',
  },
  backButton: {
    background: 'rgba(255, 255, 255, 0.05)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.1)'),
    color: '#fff',
    ...shorthands.padding('10px', '20px'),
    ...shorthands.borderRadius('12px'),
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: '600',
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    transition: 'all 0.3s ease',
    marginBottom: '20px',
    '&:hover': {
      background: 'rgba(255, 255, 255, 0.1)',
      ...shorthands.borderColor('#FFB800'),
      transform: 'translateX(-5px)',
    }
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
  const navigate = useNavigate()
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
      setError('Por favor completa todos los campos requeridos.')
      return
    }

    setLoading(true)
    try {
      const reader = new FileReader()
      reader.onload = async () => {
        try {
          // Extrae solo la parte base64 (sin el prefijo data:application/pdf;base64,)
          const base64String = (reader.result as string).split(',')[1] || reader.result
          
          const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3001'
          const response = await axios.post(`${apiUrl}/justifications/submit`, {
            reason: reason.trim(),
            date: startDate,
            studentId: 'EST-' + new Date().getTime(),
            userEmail: 'estudiante@ucehub.edu.ec',
            userName: 'Estudiante UCE',
            documentBase64: base64String,
            documentName: selectedFile.name
          }, {
            headers: { 'Content-Type': 'application/json' }
          })

          console.log('Justification submitted:', response.data)
          setSuccess(true)
          setSelectedFile(null)
          setReason('')
          setStartDate('')
          setEndDate('')
          if (fileInputRef.current) fileInputRef.current.value = ''
          
          setTimeout(() => setSuccess(false), 3000)
        } catch (err: any) {
          console.error('Submit error:', err)
          setError(err.response?.data?.message || 'Error al enviar la justificación.')
          setLoading(false)
        }
      }
      reader.readAsDataURL(selectedFile)
    } catch (err: any) {
      console.error('Error:', err)
      setError('Error al procesar el archivo.')
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
      <button className={styles.backButton} onClick={() => navigate('/')}>
        <ArrowLeftRegular /> Volver al Inicio
      </button>

      {/* Header */}
      <div className={styles.header}>
        <div className={styles.headerTitle}>Gestión de Justificaciones</div>
        <div className={styles.headerSubtitle}>
          Administra tus ausencias y carga certificados académicos con validación inteligente.
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
