import { useState } from 'react'
import {
  makeStyles,
  Button,
  Card,
  Title2,
  Title3,
  Body1,
  tokens,
  Badge,
  Dropdown,
  Option,
} from '@fluentui/react-components'
import {
  FoodRegular,
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'

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
  filters: {
    marginBottom: '20px',
  },
  menuGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '20px',
    marginTop: '20px',
  },
  menuCard: {
    padding: '20px',
  },
  menuInfo: {
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
  },
  priceTag: {
    fontSize: '24px',
    fontWeight: 'bold',
    color: tokens.colorBrandForeground1,
  },
  backButton: {
    marginBottom: '20px',
  },
})

const Cafeteria = () => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [selectedDia, setSelectedDia] = useState('hoy')

  const menu = [
    {
      id: 1,
      nombre: 'Almuerzo Completo',
      descripcion: 'Sopa + Segundo + Jugo + Postre',
      precio: '$3.50',
      disponible: true,
      categoria: 'Menú del día'
    },
    {
      id: 2,
      nombre: 'Desayuno Continental',
      descripcion: 'Café + Pan + Huevos + Jugo',
      precio: '$2.00',
      disponible: true,
      categoria: 'Desayunos'
    },
    {
      id: 3,
      nombre: 'Sandwich de Pollo',
      descripcion: 'Pan integral con pollo, lechuga, tomate',
      precio: '$2.50',
      disponible: true,
      categoria: 'Rápidos'
    },
    {
      id: 4,
      nombre: 'Ensalada César',
      descripcion: 'Lechuga, pollo, queso parmesano, crutones',
      precio: '$3.00',
      disponible: true,
      categoria: 'Saludables'
    },
    {
      id: 5,
      nombre: 'Hamburguesa UCE',
      descripcion: 'Carne, queso, lechuga, tomate, papas',
      precio: '$4.00',
      disponible: true,
      categoria: 'Especialidades'
    },
    {
      id: 6,
      nombre: 'Jugo Natural',
      descripcion: 'Variedad de frutas de temporada',
      precio: '$1.50',
      disponible: true,
      categoria: 'Bebidas'
    },
  ]

  const horarioAtencion = {
    desayuno: '07:00 - 09:30',
    almuerzo: '12:00 - 15:00',
    merienda: '17:00 - 19:00'
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
        <FoodRegular className={styles.icon} />
        <div>
          <Title2>Cafetería Universitaria</Title2>
          <Body1>Consulta el menú y horarios de la cafetería</Body1>
        </div>
      </div>

      <Card style={{ padding: '20px', marginBottom: '20px', backgroundColor: tokens.colorBrandBackground2 }}>
        <Title3 style={{ marginBottom: '10px' }}>Horarios de Atención</Title3>
        <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
          <div>
            <Body1><strong>Desayuno:</strong> {horarioAtencion.desayuno}</Body1>
          </div>
          <div>
            <Body1><strong>Almuerzo:</strong> {horarioAtencion.almuerzo}</Body1>
          </div>
          <div>
            <Body1><strong>Merienda:</strong> {horarioAtencion.merienda}</Body1>
          </div>
        </div>
      </Card>

      <div className={styles.filters}>
        <Dropdown
          placeholder="Selecciona día"
          value={selectedDia}
          onOptionSelect={(_: any, data: any) => setSelectedDia(data.optionValue as string)}
        >
          <Option value="hoy">Menú de Hoy</Option>
          <Option value="semana">Menú de la Semana</Option>
        </Dropdown>
      </div>

      <Title3 style={{ marginTop: '20px', marginBottom: '10px' }}>Menú Disponible</Title3>
      <div className={styles.menuGrid}>
        {menu.map((item) => (
          <Card key={item.id} className={styles.menuCard}>
            <div className={styles.menuInfo}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Title3>{item.nombre}</Title3>
                <FoodRegular style={{ fontSize: '24px', color: tokens.colorBrandForeground1 }} />
              </div>
              
              <Body1>{item.descripcion}</Body1>
              
              <Badge>{item.categoria}</Badge>
              
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '10px' }}>
                <span className={styles.priceTag}>{item.precio}</span>
                <Badge color={item.disponible ? 'success' : 'danger'}>
                  {item.disponible ? 'Disponible' : 'Agotado'}
                </Badge>
              </div>
            </div>
          </Card>
        ))}
      </div>

      <Card style={{ padding: '20px', marginTop: '30px', backgroundColor: tokens.colorNeutralBackground2 }}>
        <Title3 style={{ marginBottom: '10px' }}>Información Adicional</Title3>
        <Body1>
          💳 <strong>Formas de pago:</strong> Efectivo, tarjeta, carnet universitario
        </Body1>
        <Body1 style={{ marginTop: '8px' }}>
          📍 <strong>Ubicación:</strong> Edificio Central, Planta Baja
        </Body1>
        <Body1 style={{ marginTop: '8px' }}>
          📞 <strong>Contacto:</strong> ext. 1250
        </Body1>
      </Card>
    </div>
  )
}

export default Cafeteria
