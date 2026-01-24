import { useState } from 'react'
import {
  makeStyles,
  Button,
  Title3,
  Body1,
  Spinner,
  Badge,
  Input,
} from '@fluentui/react-components'
import {
  BookRegular,
  SearchRegular,
  CheckmarkCircleRegular,
  ClockRegular,
  ArrowLeftRegular,
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
  searchBox: {
    padding: '20px',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 255, 255, 0.05)',
  },
  input: {
    backgroundColor: 'rgba(255, 255, 255, 0.05) !important',
    color: '#fff !important',
    borderRadius: '12px !important',
    border: '1px solid rgba(255, 255, 255, 0.1) !important',
    padding: '10px !important',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
    gap: '20px',
  },
  card: {
    padding: '24px',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    borderRadius: '16px',
    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
    '&:hover': {
      backgroundColor: 'rgba(255, 255, 255, 0.06)',
      borderColor: 'rgba(255, 184, 0, 0.3)',
      transform: 'translateY(-4px)',
    }
  },
  bookInfo: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  actions: {
    display: 'flex',
    gap: '10px',
    marginTop: '20px',
  },
  reserveButton: {
    background: 'linear-gradient(135deg, #FFB800 0%, #FF6B00 100%)',
    color: '#000',
    fontWeight: '700',
    borderRadius: '10px',
    border: 'none',
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

const Biblioteca = () => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [searchTerm, setSearchTerm] = useState('')

  const libros = [
    {
      id: 1,
      titulo: 'Cálculo Diferencial e Integral',
      autor: 'James Stewart',
      isbn: '978-607-522-792-7',
      disponibles: 3,
      categoria: 'Matemáticas'
    },
    {
      id: 2,
      titulo: 'Física para Ciencias e Ingeniería',
      autor: 'Raymond Serway',
      isbn: '978-607-481-472-0',
      disponibles: 5,
      categoria: 'Física'
    },
    {
      id: 3,
      titulo: 'Química General',
      autor: 'Ralph Petrucci',
      isbn: '978-848-322-608-9',
      disponibles: 0,
      categoria: 'Química'
    },
    {
      id: 4,
      titulo: 'Algoritmos y Estructuras de Datos',
      autor: 'Niklaus Wirth',
      isbn: '978-013-022-418-7',
      disponibles: 2,
      categoria: 'Computación'
    },
  ]

  const handleReservar = async (libro: typeof libros[0]) => {
    setLoading(true)
    setMessage('')

    try {
      const apiUrl = import.meta.env.VITE_API_URL
      const response = await axios.post(`${apiUrl}/biblioteca/reservar`, {
        libroId: libro.id,
        titulo: libro.titulo
      })

      setMessage(`Libro "${libro.titulo}" reservado exitosamente!`)
      console.log('Response:', response.data)
    } catch (error) {
      setMessage('Error al reservar el libro')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const filteredLibros = libros.filter(libro =>
    libro.titulo.toLowerCase().includes(searchTerm.toLowerCase()) ||
    libro.autor.toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className={styles.container}>
      <button className={styles.backButton} onClick={() => navigate('/')}>
        <ArrowLeftRegular /> Volver al Inicio
      </button>

      <div className={styles.header}>
        <h1 className={styles.headerTitle}>
          <BookRegular style={{ color: '#FFB800' }} /> Biblioteca Digital UCE
        </h1>
        <p className={styles.headerSubtitle}>Accede a miles de recursos académicos y reserva libros físicos</p>
      </div>

      <div className={styles.searchBox}>
        <Input
          className={styles.input}
          placeholder="Busca por título, autor o categoría..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          contentBefore={<SearchRegular style={{ color: '#FFB800' }} />}
          style={{ width: '100%' }}
        />
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
        {filteredLibros.map((libro) => (
          <div key={libro.id} className={styles.card}>
            <div className={styles.bookInfo}>
              <Title3 style={{ color: '#fff', fontWeight: '800' }}>{libro.titulo}</Title3>
              <Body1 style={{ color: '#aaa' }}><strong>Autor:</strong> {libro.autor}</Body1>
              <Body1 style={{ color: '#888', fontSize: '12px' }}><strong>ISBN:</strong> {libro.isbn}</Body1>
              
              <div style={{ display: 'flex', gap: '8px', margin: '8px 0' }}>
                <Badge appearance="filled" color={libro.disponibles > 0 ? 'success' : 'danger'}>
                    {libro.disponibles > 0 ? `${libro.disponibles} Libros` : 'Agotado'}
                </Badge>
                <Badge appearance="outline" style={{ color: '#FFB800', borderColor: '#FFB800' }}>{libro.categoria}</Badge>
              </div>

              <div className={styles.actions}>
                <Button
                  className={styles.reserveButton}
                  icon={libro.disponibles > 0 ? <CheckmarkCircleRegular /> : <ClockRegular />}
                  onClick={() => handleReservar(libro)}
                  disabled={loading || libro.disponibles === 0}
                  style={{ width: '100%', padding: '10px' }}
                >
                  {loading ? <Spinner size="tiny" /> : libro.disponibles > 0 ? 'Reservar Ahora' : 'Lista de Espera'}
                </Button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default Biblioteca
