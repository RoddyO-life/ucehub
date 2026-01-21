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
  Spinner,
} from '@fluentui/react-components'
import {
  FoodRegular,
  DeleteRegular,
  CheckmarkCircleRegular,
  AlertRegular,
} from '@fluentui/react-icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    padding: '20px',
    maxWidth: '1200px',
    margin: '0 auto',
    display: 'grid',
    gridTemplateColumns: '1fr 350px',
    gap: '20px',
  },
  mainContent: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
  },
  sidebar: {
    display: 'flex',
    flexDirection: 'column',
    gap: '16px',
  },
  header: {
    marginBottom: '20px',
    display: 'flex',
    alignItems: 'center',
    gap: '15px',
  },
  icon: {
    fontSize: '40px',
    color: tokens.colorBrandForeground1,
  },
  menuGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))',
    gap: '16px',
  },
  menuCard: {
    padding: '16px',
    cursor: 'pointer',
    transition: 'all 0.3s',
    ':hover': {
      transform: 'translateY(-4px)',
      boxShadow: '0 8px 16px rgba(0,0,0,0.1)',
    },
  },
  cartCard: {
    padding: '16px',
    position: 'sticky',
    top: '20px',
  },
  cartItem: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '8px 0',
    borderBottom: '1px solid #e0e0e0',
  },
  cartTotal: {
    fontSize: '20px',
    fontWeight: 'bold',
    marginTop: '12px',
    paddingTop: '12px',
    borderTop: '2px solid #667eea',
    color: '#667eea',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  formGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '6px',
  },
  label: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#333',
  },
  input: {
    padding: '8px',
    border: '1px solid #e0e0e0',
    borderRadius: '4px',
    fontSize: '13px',
    fontFamily: 'inherit',
    ':focus': {
      outline: 'none',
      borderColor: '#667eea',
    },
  },
  backButton: {
    marginBottom: '0',
  },
  priceTag: {
    fontSize: '16px',
    fontWeight: 'bold',
    color: tokens.colorBrandForeground1,
  },
  successMessage: {
    background: '#dcf5dd',
    color: '#107c10',
    padding: '12px',
    borderRadius: '6px',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    marginTop: '12px',
  },
  errorMessage: {
    background: '#fed4d4',
    color: '#a4373a',
    padding: '12px',
    borderRadius: '6px',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    marginTop: '12px',
  },
  addButton: {
    width: '100%',
    marginTop: '8px',
  },
  responsive: {
    '@media (max-width: 768px)': {
      container: {
        gridTemplateColumns: '1fr',
      },
      sidebar: {
        position: 'fixed',
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 1000,
        borderRadius: '16px 16px 0 0',
      },
    },
  },
})

interface MenuItem {
  id: string
  name: string
  description: string
  price: number
  category: string
  available: boolean
}

interface CartItem extends MenuItem {
  quantity: number
}

const Cafeteria = () => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [cart, setCart] = useState<CartItem[]>([])
  const [userName, setUserName] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [deliveryTime, setDeliveryTime] = useState('12:00-13:00')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const menu: MenuItem[] = [
    { id: '1', name: 'Almuerzo Completo', description: 'Sopa + Segundo + Jugo + Postre', price: 3.50, category: 'Menú del día', available: true },
    { id: '2', name: 'Desayuno Continental', description: 'Café + Pan + Huevos + Jugo', price: 2.00, category: 'Desayunos', available: true },
    { id: '3', name: 'Sandwich de Pollo', description: 'Pan integral con pollo, lechuga, tomate', price: 2.50, category: 'Rápidos', available: true },
    { id: '4', name: 'Ensalada César', description: 'Lechuga, pollo, queso parmesano, crutones', price: 3.00, category: 'Saludables', available: true },
    { id: '5', name: 'Hamburguesa UCE', description: 'Carne, queso, lechuga, tomate, papas', price: 4.00, category: 'Especialidades', available: true },
    { id: '6', name: 'Jugo Natural', description: 'Variedad de frutas de temporada', price: 1.50, category: 'Bebidas', available: true },
  ]

  const addToCart = (item: MenuItem) => {
    const existing = cart.find(c => c.id === item.id)
    if (existing) {
      setCart(cart.map(c => c.id === item.id ? { ...c, quantity: c.quantity + 1 } : c))
    } else {
      setCart([...cart, { ...item, quantity: 1 }])
    }
  }

  const removeFromCart = (id: string) => {
    setCart(cart.filter(c => c.id !== id))
  }

  const updateQuantity = (id: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(id)
    } else {
      setCart(cart.map(c => c.id === id ? { ...c, quantity } : c))
    }
  }

  const totalPrice = cart.reduce((sum, item) => sum + item.price * item.quantity, 0)

  const handleCheckout = async () => {
    if (!userName || !userEmail) {
      setError('Por favor completa tu nombre y email')
      return
    }

    if (cart.length === 0) {
      setError('Tu carrito está vacío')
      return
    }

    setLoading(true)
    setError('')
    setSuccess(false)

    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3001'
      await axios.post(`${apiUrl}/cafeteria/order`, {
        userName,
        userEmail,
        items: cart,
        totalPrice,
        deliveryTime,
        notes
      })

      setSuccess(true)
      setCart([])
      setUserName('')
      setUserEmail('')
      setDeliveryTime('12:00-13:00')
      setNotes('')

      setTimeout(() => {
        setSuccess(false)
        navigate('/')
      }, 2000)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Error al procesar la orden')
      console.error('Checkout error:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ padding: '20px', maxWidth: '1200px', margin: '0 auto' }}>
      <Button className={styles.backButton} onClick={() => navigate('/')}>
        ← Volver
      </Button>

      <div className={styles.header}>
        <FoodRegular className={styles.icon} />
        <div>
          <Title2>🍽️ Cafetería Universitaria</Title2>
          <Body1>Ordena tu comida - Atención: 07:00 a 19:00</Body1>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: '20px' }}>
        {/* Menu */}
        <div>
          <Title3 style={{ marginBottom: '16px' }}>Menú Disponible</Title3>
          <div className={styles.menuGrid}>
            {menu.map((item) => (
              <Card key={item.id} className={styles.menuCard}>
                <div style={{ display: 'flex', alignItems: 'start', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <div>
                    <Title3 style={{ fontSize: '16px', marginBottom: '4px' }}>{item.name}</Title3>
                    <span style={{ fontSize: '11px', background: '#f0f4ff', padding: '2px 8px', borderRadius: '4px' }}>
                      {item.category}
                    </span>
                  </div>
                </div>
                <Body1 style={{ fontSize: '13px', marginBottom: '8px', opacity: 0.8 }}>{item.description}</Body1>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '12px' }}>
                  <span className={styles.priceTag}>${item.price.toFixed(2)}</span>
                  <Button size="small" onClick={() => addToCart(item)}>
                    Agregar
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Carrito y Checkout */}
        <div>
          <Card className={styles.cartCard} style={{ height: 'fit-content' }}>
            <Title3 style={{ marginBottom: '12px' }}>🛒 Mi Carrito ({cart.length})</Title3>

            {success && (
              <div className={styles.successMessage}>
                <CheckmarkCircleRegular />
                <span>¡Orden creada exitosamente!</span>
              </div>
            )}

            {error && (
              <div className={styles.errorMessage}>
                <AlertRegular />
                <span>{error}</span>
              </div>
            )}

            {/* Cart Items */}
            {cart.length > 0 ? (
              <div style={{ marginBottom: '12px', maxHeight: '200px', overflowY: 'auto' }}>
                {cart.map((item) => (
                  <div key={item.id} className={styles.cartItem}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '12px', fontWeight: '500' }}>{item.name}</div>
                      <div style={{ fontSize: '11px', opacity: 0.7 }}>${item.price.toFixed(2)} x {item.quantity}</div>
                    </div>
                    <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                      <input
                        type="number"
                        min="1"
                        value={item.quantity}
                        onChange={(e) => updateQuantity(item.id, parseInt(e.target.value))}
                        style={{
                          width: '35px',
                          padding: '4px',
                          fontSize: '11px',
                          border: '1px solid #e0e0e0',
                          borderRadius: '4px',
                        }}
                      />
                      <Button
                        size="small"
                        appearance="subtle"
                        onClick={() => removeFromCart(item.id)}
                      >
                        <DeleteRegular />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <Body1 style={{ opacity: 0.6, textAlign: 'center', padding: '20px 0' }}>
                Tu carrito está vacío
              </Body1>
            )}

            <div className={styles.cartTotal}>
              Total: ${totalPrice.toFixed(2)}
            </div>

            {/* Checkout Form */}
            <div className={styles.form} style={{ marginTop: '12px' }}>
              <div className={styles.formGroup}>
                <label className={styles.label}>Nombre *</label>
                <input
                  type="text"
                  className={styles.input}
                  placeholder="Tu nombre"
                  value={userName}
                  onChange={(e) => setUserName(e.target.value)}
                  disabled={loading}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Email *</label>
                <input
                  type="email"
                  className={styles.input}
                  placeholder="tu@email.com"
                  value={userEmail}
                  onChange={(e) => setUserEmail(e.target.value)}
                  disabled={loading}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Hora de entrega</label>
                <select
                  className={styles.input}
                  value={deliveryTime}
                  onChange={(e) => setDeliveryTime(e.target.value)}
                  disabled={loading}
                  style={{ fontSize: '13px' }}
                >
                  <option value="07:00-08:00">Desayuno (07:00-08:00)</option>
                  <option value="12:00-13:00">Almuerzo (12:00-13:00)</option>
                  <option value="17:00-18:00">Merienda (17:00-18:00)</option>
                </select>
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Notas adicionales</label>
                <textarea
                  className={styles.input}
                  placeholder="Peticiones especiales..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  disabled={loading}
                  style={{ minHeight: '60px', resize: 'vertical', fontFamily: 'inherit' }}
                />
              </div>

              <Button
                onClick={handleCheckout}
                disabled={loading || cart.length === 0 || !userName || !userEmail}
                style={{
                  background: '#667eea',
                  color: '#fff',
                  marginTop: '12px',
                }}
              >
                {loading ? <Spinner size="tiny" /> : '✓ Proceder al Pago'}
              </Button>
            </div>
          </Card>
        </div>
      </div>

      {/* Info Card */}
      <Card style={{ padding: '16px', marginTop: '20px', backgroundColor: '#f5f5f5' }}>
        <Title3 style={{ marginBottom: '10px', fontSize: '16px' }}>ℹ️ Información</Title3>
        <Body1 style={{ fontSize: '13px', lineHeight: '1.6' }}>
          💳 Formas de pago: Efectivo, Tarjeta, Carnet
          <br />
          📍 Ubicación: Edificio Central, Planta Baja
          <br />
          📞 Contacto: ext. 1250
        </Body1>
      </Card>
    </div>
  )
}

export default Cafeteria
