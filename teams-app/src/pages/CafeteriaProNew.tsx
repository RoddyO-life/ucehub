import { useState } from 'react'
import {
  Button,
  Card,
  Title2,
  Body2,
  makeStyles,
  Badge,
  Dialog,
  DialogTrigger,
  DialogContent,
  DialogBody,
  DialogTitle,
  Input,
  Select,
  Spinner
} from '@fluentui/react-components'
import {
  ShoppingBag24Regular,
  Add24Regular,
  Delete24Regular,
  Checkmark24Regular
} from '@fluentui/react-icons'
import axios from 'axios'
import { CAFETERIAS, MENU_CATEGORIES, PAYMENT_METHODS } from '../utils/constants'

const Title3 = ({ children, ...props }: any) => (
  <div style={{ fontSize: '20px', fontWeight: '600', ...props.style }} {...props}>{children}</div>
)

const Body1 = ({ children, ...props }: any) => (
  <div style={{ fontSize: '14px', ...props.style }} {...props}>{children}</div>
)

const useStyles = makeStyles({
  container: {
    padding: '24px',
    backgroundColor: '#f5f5f5',
    minHeight: '100vh',
    maxWidth: '1400px',
    margin: '0 auto'
  },
  header: {
    textAlign: 'center',
    padding: '20px',
    backgroundColor: '#667eea',
    borderRadius: '12px',
    color: 'white',
    marginBottom: '24px'
  },
  mainGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 350px',
    gap: '20px',
    '@media (max-width: 1024px)': {
      gridTemplateColumns: '1fr'
    }
  },
  cafeteriaGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
    gap: '16px',
    marginBottom: '24px'
  },
  cafeteriaCard: {
    padding: '16px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    '&:hover': {
      boxShadow: '0 8px 16px rgba(0,0,0,0.12)',
      transform: 'translateY(-4px)'
    },
    border: '2px solid #e0e0e0',
    '&.selected': {
      backgroundColor: '#f0f0f0'
    }
  },
  categorySelector: {
    display: 'flex',
    gap: '8px',
    marginBottom: '16px',
    overflowX: 'auto',
    paddingBottom: '8px'
  },
  categoryButton: {
    whiteSpace: 'nowrap',
    minWidth: '100px'
  },
  menuGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))',
    gap: '16px'
  },
  menuItem: {
    padding: '12px',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    transition: 'all 0.2s ease',
    '&:hover': {
      backgroundColor: '#f5f5f5'
    }
  },
  itemHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '8px'
  },
  price: {
    fontSize: '18px',
    fontWeight: '700',
    color: '#667eea'
  },
  cartSidebar: {
    backgroundColor: '#ffffff',
    padding: '16px',
    borderRadius: '12px',
    height: 'fit-content',
    position: 'sticky',
    top: '20px',
    boxShadow: '0 4px 8px rgba(0,0,0,0.08)'
  },
  cartItem: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '8px',
    marginBottom: '8px',
    backgroundColor: '#f5f5f5',
    borderRadius: '4px',
    fontSize: '12px'
  },
  cartTotal: {
    display: 'flex',
    justifyContent: 'space-between',
    fontWeight: 'bold',
    padding: '12px',
    borderTop: '2px solid #e0e0e0',
    marginTop: '12px',
    marginBottom: '12px'
  },
  checkoutForm: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px'
  },
  receiptContent: {
    fontFamily: 'monospace',
    fontSize: '12px',
    lineHeight: '1.6',
    padding: '16px',
    backgroundColor: '#f5f5f5',
    borderRadius: '8px',
    maxHeight: '400px',
    overflowY: 'auto'
  },
  successMessage: {
    textAlign: 'center',
    padding: '24px',
    backgroundColor: '#90EE90',
    borderRadius: '12px',
    color: 'white'
  }
})

interface CartItem {
  id: number
  name: string
  price: number
  quantity: number
}

interface SelectedCafeteria {
  id: number
  name: string
}

export default function CafeteriaNew() {
  const styles = useStyles()
  const [selectedCafeteria, setSelectedCafeteria] = useState<SelectedCafeteria>(CAFETERIAS[0])
  const [selectedCategory, setSelectedCategory] = useState('desayunos')
  const [cart, setCart] = useState<CartItem[]>([])
  const [userName, setUserName] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [paymentMethod, setPaymentMethod] = useState('cash')
  const [isCheckoutOpen] = useState(false)
  const [isProcessing, setIsProcessing] = useState(false)
  const [orderComplete, setOrderComplete] = useState(false)
  const [orderId, setOrderId] = useState('')

  const API_URL = import.meta.env.VITE_API_URL || 
                 import.meta.env.VITE_BACKEND_URL ||
                 'http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com' ||
                 'http://localhost:3001'

  const currentMenu = MENU_CATEGORIES[selectedCategory as keyof typeof MENU_CATEGORIES]

  const addToCart = (item: any) => {
    const existingItem = cart.find(i => i.id === item.id)
    if (existingItem) {
      setCart(cart.map(i => 
        i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
      ))
    } else {
      setCart([...cart, { ...item, quantity: 1 }])
    }
  }

  const removeFromCart = (itemId: number) => {
    setCart(cart.filter(i => i.id !== itemId))
  }

  const updateQuantity = (itemId: number, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(itemId)
    } else {
      setCart(cart.map(i => 
        i.id === itemId ? { ...i, quantity } : i
      ))
    }
  }

  const getTotalPrice = () => {
    return cart.reduce((sum, item) => sum + (item.price * item.quantity), 0)
  }

  const getTotalItems = () => {
    return cart.reduce((sum, item) => sum + item.quantity, 0)
  }

  const generateReceipt = () => {
    const total = getTotalPrice()
    const date = new Date().toLocaleString()
    
    return `
╔════════════════════════════════════════╗
║        RECIBO DE COMPRA UCEHUB         ║
╠════════════════════════════════════════╣
║ Cafetería: ${selectedCafeteria.name.padEnd(30)}
║ Cliente: ${userName.padEnd(33)}
║ Email: ${userEmail.padEnd(35)}
║ Fecha: ${date}
╠════════════════════════════════════════╣
║ ITEMS ORDENADOS:                       ║
${cart.map(item => 
  `║ ${item.name.padEnd(28)} x${item.quantity.toString().padStart(2)}  $${(item.price * item.quantity).toFixed(2).padStart(6)}`
).join('\n')}
╠════════════════════════════════════════╣
║ RESUMEN:                               ║
║ Subtotal: $${getTotalPrice().toFixed(2).padStart(28)}
║ Tax (10%): $${(getTotalPrice() * 0.1).toFixed(2).padStart(27)}
║ TOTAL: $${(getTotalPrice() * 1.1).toFixed(2).padStart(31)}
║ Método: ${paymentMethod.padEnd(31)}
╠════════════════════════════════════════╣
║ Orden ID: ${orderId}
║ Estado: Confirmada
║ ¡Gracias por su compra!
╚════════════════════════════════════════╝
    `.trim()
  }

  const handleCheckout = async () => {
    if (!userName || !userEmail) {
      alert('Por favor completa nombre y email')
      return
    }

    if (cart.length === 0) {
      alert('El carrito está vacío')
      return
    }

    setIsProcessing(true)
    try {
      const orderData = {
        items: cart.map(item => ({
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          price: item.price
        })),
        total: getTotalPrice() * 1.1,
        userName,
        userEmail,
        paymentMethod
      }

      const response = await axios.post(`${API_URL}/cafeteria/order`, orderData)
      
      if (response.data.success) {
        const newOrderId = response.data.data.orderId
        setOrderId(newOrderId)
        setOrderComplete(true)
        
        // Clear form
        setCart([])
        setUserName('')
        setUserEmail('')
        
        // Close checkout dialog
        // Checkout closed
        
        // Show success for 5 seconds
        setTimeout(() => {
          setOrderComplete(false)
          setOrderId('')
        }, 5000)
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Error al procesar la orden')
    } finally {
      setIsProcessing(false)
    }
  }

  if (orderComplete) {
    return (
      <div className={styles.container}>
        <div className={styles.successMessage}>
          <Checkmark24Regular style={{ fontSize: '64px', marginBottom: '16px' }} />
          <Title2>¡Orden Confirmada!</Title2>
          <Body1 style={{ marginTop: '12px' }}>Orden ID: {orderId}</Body1>
          <Body1>Recibirás la factura en tu email y Teams</Body1>
        </div>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      {/* Header */}
      <div className={styles.header}>
        <Title2 style={{ color: 'white', marginBottom: '8px' }}>☕ Cafetería UCE</Title2>
        <Body1 style={{ color: 'rgba(255,255,255,0.8)' }}>Selecciona tu cafetería y realiza tu pedido</Body1>
      </div>

      {/* Cafeterías */}
      <div>
        <Title3 style={{ marginBottom: '12px' }}>🏪 Cafeterías Disponibles</Title3>
        <div className={styles.cafeteriaGrid}>
          {CAFETERIAS.map(cafe => (
            <Card
              key={cafe.id}
              className={`${styles.cafeteriaCard} ${selectedCafeteria.id === cafe.id ? 'selected' : ''}`}
              onClick={() => setSelectedCafeteria(cafe)}
              style={{
                borderColor: selectedCafeteria.id === cafe.id ? '#667eea' : undefined
              }}
            >
              <Body1 style={{ fontSize: '24px', marginBottom: '8px' }}>{cafe.image}</Body1>
              <Title3 style={{ marginBottom: '4px' }}>{cafe.name}</Title3>
              <Body2>{cafe.location}</Body2>
              <Body2 style={{ color: '#666666', marginTop: '8px' }}>
                {cafe.hours}
              </Body2>
            </Card>
          ))}
        </div>
      </div>

      <div className={styles.mainGrid}>
        {/* Menu */}
        <div>
          <Title3 style={{ marginBottom: '12px' }}>🍽️ Menú</Title3>
          
          {/* Category Selector */}
          <div className={styles.categorySelector}>
            {Object.entries(MENU_CATEGORIES).map(([key, category]) => (
              <Button
                key={key}
                className={styles.categoryButton}
                appearance={selectedCategory === key ? 'primary' : 'outline'}
                onClick={() => setSelectedCategory(key)}
              >
                {category.icon} {category.name}
              </Button>
            ))}
          </div>

          {/* Menu Items */}
          <div className={styles.menuGrid}>
            {currentMenu.items.map(item => (
              <Card key={item.id} className={styles.menuItem}>
                <div className={styles.itemHeader}>
                  <div>
                    <Body1><strong>{item.name}</strong></Body1>
                    <Body2 style={{ fontSize: '12px', color: '#666666', marginTop: '4px' }}>
                      {item.description}
                    </Body2>
                  </div>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '12px' }}>
                  <div className={styles.price}>${item.price.toFixed(2)}</div>
                  <Button
                    icon={<Add24Regular />}
                    appearance="primary"
                    size="small"
                    onClick={() => addToCart(item)}
                  />
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Cart Sidebar */}
        <div className={styles.cartSidebar}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '16px', gap: '8px' }}>
            <ShoppingBag24Regular />
            <Title3>Carrito</Title3>
            {cart.length > 0 && <Badge>{getTotalItems()}</Badge>}
          </div>

          {cart.length === 0 ? (
            <Body2 style={{ color: '#666666' }}>
              Tu carrito está vacío
            </Body2>
          ) : (
            <>
              {cart.map(item => (
                <div key={item.id} className={styles.cartItem}>
                  <div>
                    <div><strong>{item.name}</strong></div>
                    <div>${(item.price * item.quantity).toFixed(2)}</div>
                  </div>
                  <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                    <Button
                      size="small"
                      appearance="subtle"
                      onClick={() => updateQuantity(item.id, item.quantity - 1)}
                    >
                      −
                    </Button>
                    <span style={{ minWidth: '20px', textAlign: 'center' }}>{item.quantity}</span>
                    <Button
                      size="small"
                      appearance="subtle"
                      onClick={() => updateQuantity(item.id, item.quantity + 1)}
                    >
                      +
                    </Button>
                    <Button
                      size="small"
                      appearance="subtle"
                      onClick={() => removeFromCart(item.id)}
                      icon={<Delete24Regular />}
                    />
                  </div>
                </div>
              ))}

              <div className={styles.cartTotal}>
                <span>Subtotal:</span>
                <span>${getTotalPrice().toFixed(2)}</span>
              </div>

              <div className={styles.cartTotal} style={{ borderTop: 'none', marginTop: '0', marginBottom: '0' }}>
                <span>Impuesto (10%):</span>
                <span>${(getTotalPrice() * 0.1).toFixed(2)}</span>
              </div>

              <div className={styles.cartTotal} style={{ fontSize: '16px' }}>
                <span>TOTAL:</span>
                <span>${(getTotalPrice() * 1.1).toFixed(2)}</span>
              </div>

              <Button
                appearance="primary"
                onClick={handleCheckout}
                style={{
                  width: '100%',
                  marginTop: '12px',
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  color: 'white',
                  border: 'none',
                }}
              >
                Proceder a Pagar
              </Button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
