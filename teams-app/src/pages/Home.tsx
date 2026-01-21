import { useState, useEffect } from 'react'
import {
  makeStyles,
  Button,
  Spinner,
} from '@fluentui/react-components'
import {
  ChevronRight20Filled,
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { FACULTADES } from '../utils/constants'

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
    textAlign: 'center',
    marginBottom: '16px',
  },
  headerTitle: {
    fontSize: '32px',
    fontWeight: '700',
    marginBottom: '8px',
  },
  headerSubtitle: {
    fontSize: '16px',
    opacity: '0.9',
  },
  section: {
    marginBottom: '32px',
  },
  sectionTitle: {
    fontSize: '20px',
    fontWeight: '600',
    marginBottom: '16px',
    color: '#ffffff',
    textTransform: 'uppercase',
    letterSpacing: '0.5px',
  },
  cardsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '16px',
  },
  serviceCard: {
    background: 'rgba(255, 255, 255, 0.95)',
    backdropFilter: 'blur(10px)',
    borderRadius: '12px',
    overflow: 'hidden',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    border: '1px solid rgba(255, 255, 255, 0.3)',
    ':hover': {
      transform: 'translateY(-8px)',
      boxShadow: '0 20px 40px rgba(0, 0, 0, 0.2)',
    },
  },
  serviceCardHeader: {
    padding: '20px',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: '#ffffff',
  },
  serviceCardTitle: {
    fontSize: '18px',
    fontWeight: '700',
    marginBottom: '4px',
  },
  serviceCardDesc: {
    fontSize: '14px',
    opacity: '0.9',
  },
  serviceCardBody: {
    padding: '16px 20px',
    color: '#333333',
  },
  serviceCardFooter: {
    padding: '0 20px 16px 20px',
  },
  facultiesContainer: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))',
    gap: '12px',
  },
  facultyButton: {
    background: 'rgba(255, 255, 255, 0.95)',
    color: '#333333',
    border: '2px solid transparent',
    borderRadius: '8px',
    padding: '12px',
    textAlign: 'center',
    fontWeight: '500',
    fontSize: '13px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    ':hover': {
      transform: 'scale(1.05)',
      boxShadow: '0 8px 16px rgba(102, 126, 234, 0.3)',
    },
  },
  facultyButtonSelected: {
    background: '#667eea',
    color: '#ffffff',
  },
  actionButtons: {
    display: 'flex',
    gap: '12px',
    justifyContent: 'center',
    flexWrap: 'wrap',
  },
  primaryButton: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: '#ffffff',
    border: 'none',
    padding: '12px 28px',
    borderRadius: '6px',
    fontWeight: '600',
    fontSize: '14px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    ':hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 12px 24px rgba(102, 126, 234, 0.4)',
    },
  },
  stats: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))',
    gap: '12px',
    marginTop: '16px',
  },
  statCard: {
    background: 'rgba(255, 255, 255, 0.15)',
    backdropFilter: 'blur(10px)',
    border: '1px solid rgba(255, 255, 255, 0.3)',
    borderRadius: '8px',
    padding: '16px',
    textAlign: 'center',
    color: '#ffffff',
  },
  statValue: {
    fontSize: '24px',
    fontWeight: '700',
    marginBottom: '4px',
  },
  statLabel: {
    fontSize: '12px',
    opacity: '0.8',
    textTransform: 'uppercase',
    letterSpacing: '0.5px',
  },
})

interface HomeProps {
  teamsContext: any
  isInTeams: boolean
}

const Home = ({ teamsContext, isInTeams }: HomeProps) => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [apiStatus, setApiStatus] = useState<string>('Verificando...')
  const [loading, setLoading] = useState(true)
  const [selectedFaculty, setSelectedFaculty] = useState<number | null>(null)

  useEffect(() => {
    checkApiStatus()
  }, [])

  const checkApiStatus = async () => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL
      const response = await axios.get(`${apiUrl}/health`, {
        timeout: 5000
      })
      setApiStatus('Conectado ✓')
      console.log('API Response:', response.data)
    } catch (error) {
      setApiStatus('Desconectado ✗')
      console.error('API Error:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleServiceClick = (route: string) => {
    if (route) {
      navigate(route)
    }
  }

  const services = [
    {
      id: 1,
      title: 'Mis Justificaciones',
      description: 'Registra ausencias y visualiza tus documentos',
      icon: '📄',
      route: '/justifications'
    },
    {
      id: 2,
      title: 'Cafetería UCE',
      description: 'Ordena comida en nuestras cafeterías',
      icon: '🍽️',
      route: '/cafeteria'
    },
    {
      id: 3,
      title: 'Soporte Técnico',
      description: 'Solicita ayuda y reporta problemas',
      icon: '🎫',
      route: '/support'
    },
  ]

  return (
    <div className={styles.container}>
      {/* Header */}
      <div className={styles.header}>
        <div className={styles.headerTitle}>¡Bienvenido!</div>
        <div className={styles.headerSubtitle}>
          Sistema integrado UCEHub - Universidad Central del Ecuador
        </div>
      </div>

      {/* Stats */}
      <div className={styles.stats}>
        <div className={styles.statCard}>
          <div className={styles.statValue}>21</div>
          <div className={styles.statLabel}>Facultades</div>
        </div>
        <div className={styles.statCard}>
          <div className={styles.statValue}>4</div>
          <div className={styles.statLabel}>Cafeterías</div>
        </div>
        <div className={styles.statCard}>
          <div className={styles.statValue}>24/7</div>
          <div className={styles.statLabel}>Disponible</div>
        </div>
      </div>

      {/* Facultad Selection */}
      <div className={styles.section}>
        <div className={styles.sectionTitle}>Selecciona tu Facultad</div>
        <div className={styles.facultiesContainer}>
          {FACULTADES.map((facultad) => (
            <button
              key={facultad.id}
              className={`${styles.facultyButton} ${
                selectedFaculty === facultad.id ? styles.facultyButtonSelected : ''
              }`}
              onClick={() => setSelectedFaculty(facultad.id)}
              title={facultad.name}
            >
              {facultad.code}
            </button>
          ))}
        </div>
        {selectedFaculty && (
          <div style={{ color: '#ffffff', marginTop: '16px', fontSize: '14px' }}>
            ✓ Facultad seleccionada: {FACULTADES.find(f => f.id === selectedFaculty)?.name}
          </div>
        )}
      </div>

      {/* Services */}
      <div className={styles.section}>
        <div className={styles.sectionTitle}>Nuestros Servicios</div>
        <div className={styles.cardsGrid}>
          {services.map((service) => (
            <div
              key={service.id}
              className={styles.serviceCard}
              onClick={() => handleServiceClick(service.route)}
            >
              <div className={styles.serviceCardHeader}>
                <div style={{ fontSize: '28px', marginBottom: '8px' }}>
                  {service.icon}
                </div>
                <div className={styles.serviceCardTitle}>{service.title}</div>
                <div className={styles.serviceCardDesc}>{service.description}</div>
              </div>
              <div className={styles.serviceCardBody}>
                <small>Acceso rápido a todas tus solicitudes</small>
              </div>
              <div className={styles.serviceCardFooter}>
                <Button appearance="primary">
                  Acceder <ChevronRight20Filled />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Quick Actions */}
      <div className={styles.section} style={{ marginTop: '32px' }}>
        <div className={styles.sectionTitle}>Acciones Rápidas</div>
        <div className={styles.actionButtons}>
          <Button onClick={() => navigate('/justificaciones')}>
            + Nueva Justificación
          </Button>
          <Button onClick={() => navigate('/cafeteria')}>
            🍕 Ordenar Comida
          </Button>
          <Button onClick={() => navigate('/soporte')}>
            ? Contactar Soporte
          </Button>
        </div>
      </div>

      {/* Footer */}
      <div
        style={{
          textAlign: 'center',
          color: 'rgba(255, 255, 255, 0.7)',
          fontSize: '12px',
          marginTop: '32px',
          paddingTop: '16px',
          borderTop: '1px solid rgba(255, 255, 255, 0.2)',
        }}
      >
        <p>UCEHub © 2024 - Sistema de Gestión Integral</p>
        <p>Desarrollado con tecnología en la nube</p>
      </div>

      {import.meta.env.DEV && (
        <div style={{ marginTop: '20px', padding: '15px', backgroundColor: 'rgba(255, 243, 205, 0.9)', borderRadius: '8px', color: '#333' }}>
          <Body1>
            <strong>🔧 Modo Desarrollo</strong>
            <br />
            API URL: {import.meta.env.VITE_API_URL}
            <br />
            API Status: {loading ? <Spinner size="tiny" /> : apiStatus}
            <br />
            {isInTeams && `User ID: ${teamsContext?.user?.id}`}
          </Body1>
        </div>
      )}
    </div>
  )
}

export default Home
