import { useState } from 'react'
import {
  makeStyles,
  Button,
  Title3,
  Body1,
  Spinner,
  Badge,
  ProgressBar,
} from '@fluentui/react-components'
import {
  CheckmarkCircleRegular,
  ArrowUploadRegular,
  DocumentRegular,
  ArrowLeftRegular,
  StarRegular,
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'
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
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))',
    gap: '24px',
  },
  card: {
    padding: '28px',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    borderRadius: '16px',
    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
    display: 'flex',
    flexDirection: 'column',
    gap: '16px',
    '&:hover': {
      backgroundColor: 'rgba(255, 255, 255, 0.06)',
      borderColor: 'rgba(255, 184, 0, 0.3)',
      transform: 'translateY(-4px)',
    }
  },
  becaInfo: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
    flex: 1,
  },
  requisitos: {
    listStyle: 'none',
    paddingLeft: '0',
    marginTop: '10px',
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  requisitoItem: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    color: '#ccc',
    fontSize: '13px',
  },
  actions: {
    marginTop: 'auto',
    paddingTop: '20px',
  },
  applyButton: {
    background: 'linear-gradient(135deg, #FFB800 0%, #FF6B00 100%)',
    color: '#000',
    fontWeight: '700',
    borderRadius: '10px',
    border: 'none',
    width: '100%',
    padding: '12px',
    '&:hover': {
      boxShadow: '0 0 15px rgba(255, 184, 0, 0.3)',
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
  },
})

const Becas = () => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  const becas = [
    {
      id: 1,
      nombre: 'Beca de Excelencia Académica',
      monto: '100%',
      descripcion: 'Para estudiantes con promedio superior a 9.0',
      requisitos: ['Promedio ≥ 9.0', 'Sin materias reprobadas', 'Carta de recomendación'],
      cupos: 15,
      disponible: true
    },
    {
      id: 2,
      nombre: 'Beca Socioeconómica',
      monto: '75%',
      descripcion: 'Apoyo a estudiantes de escasos recursos',
      requisitos: ['Estudio socioeconómico', 'Comprobantes de ingresos', 'Promedio ≥ 7.5'],
      cupos: 30,
      disponible: true
    },
    {
      id: 3,
      nombre: 'Beca Deportiva',
      monto: '50%',
      descripcion: 'Para atletas representantes de la universidad',
      requisitos: ['Certificado deportivo', 'Carta del entrenador', 'Promedio ≥ 7.0'],
      cupos: 10,
      disponible: true
    },
    {
      id: 4,
      nombre: 'Beca Cultural',
      monto: '50%',
      descripcion: 'Para estudiantes en grupos culturales',
      requisitos: ['Participación activa en grupo cultural', 'Portafolio de actividades'],
      cupos: 8,
      disponible: false
    },
  ]

  const handleSolicitar = async (beca: typeof becas[0]) => {
    setLoading(true)
    setMessage('')

    try {
      const apiUrl = import.meta.env.VITE_API_URL
      const response = await axios.post(`${apiUrl}/becas/solicitar`, {
        becaId: beca.id,
        nombre: beca.nombre
      })

      setMessage(`Solicitud de ${beca.nombre} enviada! Revisa tu correo para los siguientes pasos.`)
      console.log('Response:', response.data)
    } catch (error) {
      setMessage('Error al solicitar la beca')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.container}>
      <button className={styles.backButton} onClick={() => navigate('/')}>
        <ArrowLeftRegular /> Volver al Inicio
      </button>

      <div className={styles.header}>
        <h1 className={styles.headerTitle}>
          <StarRegular style={{ color: '#FFB800' }} /> Programa de Becas UCE
        </h1>
        <p className={styles.headerSubtitle}>Apoyamos tu excelencia académica y compromiso con el futuro</p>
      </div>

      {message && (
        <div style={{ 
            padding: '16px', 
            borderRadius: '12px', 
            backgroundColor: 'rgba(0, 183, 117, 0.1)', 
            border: '1px solid rgba(0, 183, 117, 0.2)',
            color: '#00B775',
            textAlign: 'center',
            marginBottom: '20px'
        }}>
          {message}
        </div>
      )}

      <div className={styles.grid}>
        {becas.map((beca) => (
          <div key={beca.id} className={styles.card}>
            <div className={styles.becaInfo}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Title3 style={{ color: '#fff', fontWeight: '800' }}>{beca.nombre}</Title3>
                <Badge size="large" appearance="filled" style={{ background: '#FFB800', color: '#000' }}>{beca.monto}</Badge>
              </div>
              
              <Body1 style={{ color: '#aaa', lineHeight: '1.4' }}>{beca.descripcion}</Body1>
              
              <div style={{ marginTop: '10px' }}>
                <Body1 style={{ color: '#fff', fontWeight: 'bold', fontSize: '13px' }}>Requisitos:</Body1>
                <ul className={styles.requisitos}>
                  {beca.requisitos.map((req, idx) => (
                    <li key={idx} className={styles.requisitoItem}>
                        <CheckmarkCircleRegular style={{ color: '#FFB800', fontSize: '14px' }} />
                        <span>{req}</span>
                    </li>
                  ))}
                </ul>
              </div>

              <div style={{ marginTop: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <Body1 style={{ color: '#888', fontSize: '12px' }}>Cupos disponibles</Body1>
                    <Body1 style={{ color: '#FFB800', fontSize: '12px', fontWeight: 'bold' }}>{beca.cupos} de 50</Body1>
                </div>
                <ProgressBar 
                    value={beca.cupos / 50} 
                    style={{ height: '6px', borderRadius: '3px' }} 
                    color={beca.cupos > 20 ? 'success' : 'warning'}
                />
              </div>

              <div style={{ marginTop: '16px' }}>
                <Badge 
                    appearance="outline"
                    color={beca.disponible ? 'success' : 'warning'}
                    icon={beca.disponible ? <CheckmarkCircleRegular /> : <DocumentRegular />}
                    style={{ padding: '6px 12px' }}
                >
                    {beca.disponible ? 'Convocatoria Abierta' : 'Convocatoria Cerrada'}
                </Badge>
              </div>

              <div className={styles.actions}>
                <Button
                  className={styles.applyButton}
                  icon={<ArrowUploadRegular />}
                  onClick={() => handleSolicitar(beca)}
                  disabled={loading || !beca.disponible}
                >
                  {loading ? <Spinner size="tiny" /> : 'Solicitar Ahora'}
                </Button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default Becas
