import { useState, useEffect } from 'react'
import {
  makeStyles,
  Button,
  Spinner,
  shorthands,
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
    gap: '32px',
    padding: '40px 24px',
    minHeight: '100vh',
  },
  header: {
    textAlign: 'center',
    marginBottom: '24px',
  },
  headerTitle: {
    fontSize: '48px',
    fontWeight: '800',
    marginBottom: '12px',
    letterSpacing: '-1px',
  },
  headerSubtitle: {
    fontSize: '18px',
    color: 'rgba(255, 255, 255, 0.6)',
    maxWidth: '600px',
    ...shorthands.margin('0', 'auto'),
  },
  section: {
    marginBottom: '40px',
  },
  sectionTitle: {
    fontSize: '14px',
    fontWeight: '700',
    marginBottom: '24px',
    color: '#FF6B00',
    textTransform: 'uppercase',
    letterSpacing: '2px',
    display: 'flex',
    alignItems: 'center',
    ':after': {
      content: '""',
      flexGrow: 1,
      height: '1px',
      background: 'rgba(255, 107, 0, 0.2)',
      marginLeft: '16px',
    }
  },
  cardsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '24px',
  },
  facultiesContainer: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(100px, 1fr))',
    gap: '12px',
  },
  facultyButton: {
    background: 'rgba(255, 255, 255, 0.03)',
    color: 'rgba(255, 255, 255, 0.7)',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    borderRadius: '8px',
    padding: '12px',
    textAlign: 'center',
    fontWeight: '600',
    fontSize: '12px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    ':hover': {
      background: 'rgba(255, 107, 0, 0.1)',
      borderColor: '#FF6B00',
      color: '#ffffff',
    },
  },
  facultyButtonSelected: {
    background: 'linear-gradient(135deg, #FF9E00 0%, #FF6B00 100%)',
    color: '#000000',
    borderColor: 'transparent',
  },
  stats: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '24px',
    marginBottom: '24px',
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
      const response = await axios.get(`${apiUrl}/health`, { timeout: 5000 })
      setApiStatus('Active')
      console.log('API Status:', response.data)
    } catch (error) {
      setApiStatus('Offline')
    } finally {
      setLoading(false)
    }
  }

  const handleServiceClick = (route: string) => {
    if (route === '/monitoring') {
      const grafanaUrl = import.meta.env.VITE_GRAFANA_URL || 'http://localhost:3000'
      window.open(grafanaUrl, '_blank')
    } else if (route === '/swagger') {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3001'
      window.open(`${apiUrl}/api-docs`, '_blank')
    } else {
      navigate(route)
    }
  }

  const services = [
    { id: 1, title: 'Mis Justificaciones', description: 'Gestión inteligente de ausencias y documentos académicos.', icon: '📄', route: '/justifications' },
    { id: 2, title: 'Cafetería Pro', description: 'Sistema de pedidos en tiempo real con integración de pagos.', icon: '🍽️', route: '/cafeteria' },
    { id: 3, title: 'Soporte Virtual', description: 'Centro de ayuda con sistema de tickets prioritarios.', icon: '🎫', route: '/support' },
    { id: 4, title: 'Biblioteca UCE', description: 'Acceso a recursos digitales y reserva de libros físicos.', icon: '📚', route: '/biblioteca' },
    { id: 5, title: 'Becas & Ayuda', description: 'Gestión de becas estudiantiles y programas de asistencia.', icon: '🎓', route: '/becas' },
    { id: 6, title: 'Certificados', description: 'Emisión inmediata de certificados y documentos oficiales.', icon: '📜', route: '/certificados' },
    { id: 7, title: 'Core Analytics', description: 'Métricas de infraestructura y salud del sistema en vivo.', icon: '📊', route: '/monitoring' },
    { id: 8, title: 'Swagger API', description: 'Documentación técnica interactiva para microservicios.', icon: '📘', route: '/swagger' },
  ]

  return (
    <div className={styles.container}>
      {/* Header */}
      <header className={styles.header}>
        <h1 className={`${styles.headerTitle} velocity-gradient-text`}>UCE<span style={{color: '#fff'}}>Hub</span></h1>
        <p className={styles.headerSubtitle}>
          Plataforma de servicios integrados para la comunidad universitaria de la Universidad Central del Ecuador.
        </p>
      </header>

      {/* Stats Cards */}
      <div className={styles.stats}>
        <div className="velocity-card" style={{ padding: '24px', textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#FF6B00' }}>21</div>
          <div style={{ fontSize: '12px', opacity: 0.6, textTransform: 'uppercase', letterSpacing: '1px' }}>Facultades</div>
        </div>
        <div className="velocity-card" style={{ padding: '24px', textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#FF6B00' }}>4</div>
          <div style={{ fontSize: '12px', opacity: 0.6, textTransform: 'uppercase', letterSpacing: '1px' }}>Sedes Activas</div>
        </div>
        <div className="velocity-card" style={{ padding: '24px', textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: '800', color: apiStatus === 'Active' ? '#4CAF50' : '#FF5252' }}>
            {loading ? <Spinner size="tiny" /> : apiStatus}
          </div>
          <div style={{ fontSize: '12px', opacity: 0.6, textTransform: 'uppercase', letterSpacing: '1px' }}>API Status</div>
        </div>
      </div>

      {/* Faculty Picker */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Facultad Predeterminada</h2>
        <div className={styles.facultiesContainer}>
          {FACULTADES.map((facultad) => (
            <button
              key={facultad.id}
              className={`${styles.facultyButton} ${selectedFaculty === facultad.id ? styles.facultyButtonSelected : ''}`}
              onClick={() => setSelectedFaculty(facultad.id)}
            >
              {facultad.code}
            </button>
          ))}
        </div>
      </section>

      {/* Services Grid */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Servicios Premium</h2>
        <div className={styles.cardsGrid}>
          {services.map((service) => (
            <div key={service.id} className="velocity-card" style={{ cursor: 'pointer' }} onClick={() => handleServiceClick(service.route)}>
              <div style={{ padding: '32px' }}>
                <div style={{ fontSize: '40px', marginBottom: '16px' }}>{service.icon}</div>
                <h3 style={{ fontSize: '20px', fontWeight: '700', marginBottom: '8px' }}>{service.title}</h3>
                <p style={{ fontSize: '14px', color: 'rgba(255,255,255,0.5)', lineHeight: '1.6', marginBottom: '24px' }}>
                  {service.description}
                </p>
                <button className="velocity-button" style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  Explorar Servicio <ChevronRight20Filled />
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer style={{ marginTop: 'auto', paddingTop: '40px', borderTop: '1px solid rgba(255,255,255,0.05)', textAlign: 'center' }}>
        <p style={{ fontSize: '12px', color: 'rgba(255,255,255,0.3)' }}>
          UCEHub v4.0.0 • Desplegado con Terraform & AWS
        </p>
      </footer>
    </div>
  )
}

export default Home
