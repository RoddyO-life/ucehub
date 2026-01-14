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
  Badge,
  ProgressBar,
} from '@fluentui/react-components'
import {
  CheckmarkCircleRegular,
  ArrowUploadRegular,
  DocumentRegular
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    padding: '20px',
    maxWidth: '1000px',
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
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
    gap: '20px',
    marginTop: '20px',
  },
  card: {
    padding: '20px',
  },
  becaInfo: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  requisitos: {
    listStyle: 'disc',
    paddingLeft: '20px',
    marginTop: '5px',
  },
  actions: {
    display: 'flex',
    gap: '10px',
    marginTop: '15px',
  },
  backButton: {
    marginBottom: '20px',
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
      <Button 
        className={styles.backButton}
        onClick={() => navigate('/')}
      >
        ← Volver
      </Button>

      <div className={styles.header}>
        <CheckmarkCircleRegular className={styles.icon} />
        <div>
          <Title2>Becas Universitarias</Title2>
          <Body1>Solicita becas y apoyos económicos para tus estudios</Body1>
        </div>
      </div>

      {message && (
        <Card style={{ marginBottom: '20px', padding: '15px', backgroundColor: tokens.colorPaletteGreenBackground2 }}>
          <Body1>{message}</Body1>
        </Card>
      )}

      <div className={styles.grid}>
        {becas.map((beca) => (
          <Card key={beca.id} className={styles.card}>
            <div className={styles.becaInfo}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Title3>{beca.nombre}</Title3>
                <Badge size="large" color="informative">{beca.monto}</Badge>
              </div>
              
              <Body1>{beca.descripcion}</Body1>
              
              <div>
                <Body1><strong>Requisitos:</strong></Body1>
                <ul className={styles.requisitos}>
                  {beca.requisitos.map((req, idx) => (
                    <li key={idx}><Body1>{req}</Body1></li>
                  ))}
                </ul>
              </div>

              <div>
                <Body1><strong>Cupos disponibles: {beca.cupos}</strong></Body1>
                <ProgressBar value={beca.cupos / 50} style={{ marginTop: '5px' }} />
              </div>

              <Badge 
                color={beca.disponible ? 'success' : 'warning'}
                icon={beca.disponible ? <CheckmarkCircleRegular /> : <DocumentRegular />}
              >
                {beca.disponible ? 'Convocatoria abierta' : 'Convocatoria cerrada'}
              </Badge>

              <div className={styles.actions}>
                <Button
                  appearance="primary"
                  icon={<ArrowUploadRegular />}
                  onClick={() => handleSolicitar(beca)}
                  disabled={loading || !beca.disponible}
                >
                  {loading ? <Spinner size="tiny" /> : 'Solicitar'}
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}

export default Becas
