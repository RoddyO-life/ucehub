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
  Input,
} from '@fluentui/react-components'
import {
  BookRegular,
  SearchRegular,
  CheckmarkCircleRegular,
  ClockRegular
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
  searchBox: {
    marginBottom: '20px',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
    gap: '20px',
    marginTop: '20px',
  },
  card: {
    padding: '20px',
  },
  bookInfo: {
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
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
      <Button 
        className={styles.backButton}
        onClick={() => navigate('/')}
      >
        ← Volver
      </Button>

      <div className={styles.header}>
        <BookRegular className={styles.icon} />
        <div>
          <Title2>Biblioteca Digital</Title2>
          <Body1>Busca y reserva libros de la biblioteca UCE</Body1>
        </div>
      </div>

      <div className={styles.searchBox}>
        <Input
          placeholder="Buscar por título o autor..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          contentBefore={<SearchRegular />}
          style={{ width: '100%' }}
        />
      </div>

      {message && (
        <Card style={{ marginBottom: '20px', padding: '15px', backgroundColor: tokens.colorPaletteGreenBackground2 }}>
          <Body1>{message}</Body1>
        </Card>
      )}

      <div className={styles.grid}>
        {filteredLibros.map((libro) => (
          <Card key={libro.id} className={styles.card}>
            <div className={styles.bookInfo}>
              <Title3>{libro.titulo}</Title3>
              <Body1><strong>Autor:</strong> {libro.autor}</Body1>
              <Body1><strong>ISBN:</strong> {libro.isbn}</Body1>
              <Badge color={libro.disponibles > 0 ? 'success' : 'danger'}>
                {libro.disponibles > 0 ? `${libro.disponibles} disponibles` : 'No disponible'}
              </Badge>
              <Badge>{libro.categoria}</Badge>
              <div className={styles.actions}>
                <Button
                  appearance="primary"
                  icon={libro.disponibles > 0 ? <CheckmarkCircleRegular /> : <ClockRegular />}
                  onClick={() => handleReservar(libro)}
                  disabled={loading || libro.disponibles === 0}
                >
                  {loading ? <Spinner size="tiny" /> : libro.disponibles > 0 ? 'Reservar' : 'En espera'}
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}

export default Biblioteca
