import { useState, useEffect } from 'react'
import {
  makeStyles,
  Button,
  Card,
  CardHeader,
  Title3,
  Body1,
  tokens,
  Spinner,
} from '@fluentui/react-components'
import {
  PersonRegular,
  BookRegular,
  DocumentRegular,
  CalendarRegular,
  CheckmarkCircleRegular
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
    padding: '20px',
    maxWidth: '1200px',
    margin: '0 auto',
  },
  header: {
    textAlign: 'center',
    marginBottom: '20px',
  },
  title: {
    color: tokens.colorBrandForeground1,
    marginBottom: '10px',
  },
  servicesGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
    gap: '20px',
  },
  serviceCard: {
    padding: '20px',
    cursor: 'pointer',
    transition: 'transform 0.2s',
    ':hover': {
      transform: 'translateY(-4px)',
      boxShadow: tokens.shadow16,
    },
  },
  serviceIcon: {
    fontSize: '48px',
    marginBottom: '15px',
    color: tokens.colorBrandForeground1,
  },
  statusSection: {
    marginTop: '20px',
    padding: '20px',
    backgroundColor: tokens.colorNeutralBackground2,
    borderRadius: '8px',
  },
  statusItem: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    marginBottom: '10px',
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
    navigate(route)
  }

  const services = [
    {
      id: 1,
      title: 'Certificados',
      description: 'Solicita y descarga certificados académicos',
      icon: <DocumentRegular />,
      route: '/certificados'
    },
    {
      id: 2,
      title: 'Biblioteca',
      description: 'Reserva y gestiona préstamos de libros',
      icon: <BookRegular />,
      route: '/biblioteca'
    },
    {
      id: 3,
      title: 'Soporte Técnico',
      description: 'Crea tickets de soporte',
      icon: <PersonRegular />,
      route: '/soporte'
    },
    {
      id: 4,
      title: 'Becas',
      description: 'Solicita y gestiona becas universitarias',
      icon: <CheckmarkCircleRegular />,
      route: '/becas'
    },
    {
      id: 5,
      title: 'Horarios',
      description: 'Consulta tus horarios de clase',
      icon: <CalendarRegular />,
      route: '/horarios'
    },
    {
      id: 6,
      title: 'Cafetería',
      description: 'Consulta el menú y precios',
      icon: <CalendarRegular />,
      route: '/cafeteria'
    },
  ]

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <Title3 className={styles.title}>
          🎓 UCEHub - Servicios Universitarios
        </Title3>
        <Body1>
          {isInTeams
            ? `Bienvenido ${teamsContext?.user?.displayName || 'Estudiante'}`
            : 'Modo Desarrollo (Fuera de Teams)'}
        </Body1>
      </div>

      <div className={styles.statusSection}>
        <Title3 style={{ marginBottom: '15px' }}>Estado del Sistema</Title3>
        <div className={styles.statusItem}>
          <CheckmarkCircleRegular fontSize={24} />
          <Body1>
            <strong>API Backend:</strong>{' '}
            {loading ? <Spinner size="tiny" /> : apiStatus}
          </Body1>
        </div>
        <div className={styles.statusItem}>
          <CheckmarkCircleRegular fontSize={24} />
          <Body1>
            <strong>Microsoft Teams:</strong> {isInTeams ? 'Conectado ✓' : 'Standalone ✗'}
          </Body1>
        </div>
        <div className={styles.statusItem}>
          <CheckmarkCircleRegular fontSize={24} />
          <Body1>
            <strong>Ambiente:</strong> QA (Testing)
          </Body1>
        </div>
      </div>

      <Title3 style={{ marginTop: '20px' }}>Servicios Disponibles</Title3>
      <div className={styles.servicesGrid}>
        {services.map((service) => (
          <Card key={service.id} className={styles.serviceCard}>
            <CardHeader
              header={<Title3>{service.title}</Title3>}
              description={<Body1>{service.description}</Body1>}
              image={<div className={styles.serviceIcon}>{service.icon}</div>}
            />
            <Button 
              appearance="primary" 
              style={{ marginTop: '10px' }}
              onClick={() => handleServiceClick(service.route)}
            >
              Acceder
            </Button>
          </Card>
        ))}
      </div>

      {import.meta.env.DEV && (
        <div style={{ marginTop: '20px', padding: '15px', backgroundColor: '#fff3cd', borderRadius: '8px' }}>
          <Body1>
            <strong>🔧 Modo Desarrollo</strong>
            <br />
            API URL: {import.meta.env.VITE_API_URL}
            <br />
            {isInTeams && `User ID: ${teamsContext?.user?.id}`}
          </Body1>
        </div>
      )}
    </div>
  )
}

export default Home
