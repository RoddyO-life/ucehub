import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Button,
  Card,
  Title2,
  Body2,
  makeStyles,
  shorthands,
  Badge,
  Dialog,
  DialogTrigger,
  DialogContent,
  DialogBody,
  DialogTitle,
  DialogSurface,
  Input,
  Select,
  Spinner
} from '@fluentui/react-components'
import {
  ShoppingBag24Regular,
  Add24Regular,
  Delete24Regular,
  Checkmark24Regular,
  ArrowLeftRegular
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
    background: 'transparent',
    minHeight: '100vh',
    maxWidth: '1400px',
    margin: '0 auto',
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
  },
  header: {
    textAlign: 'center',
    padding: '30px',
    background: 'rgba(20, 20, 20, 0.4)',
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
    marginBottom: '8px',
  },
  headerSubtitle: {
    color: '#aaa',
    fontSize: '16px',
  },
  mainGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 380px',
    gap: '24px',
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
    ...shorthands.padding('20px'),
    cursor: 'pointer',
    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
    background: 'rgba(255, 255, 255, 0.03)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.05)'),
    ...shorthands.borderRadius('12px'),
    '&:hover': {
      background: 'rgba(255, 255, 255, 0.06)',
      ...shorthands.borderColor('rgba(255, 184, 0, 0.3)'),
      transform: 'translateY(-4px)'
    },
    '&.selected': {
      ...shorthands.borderColor('#FFB800'),
      background: 'rgba(255, 184, 0, 0.05)',
      boxShadow: '0 0 15px rgba(255, 184, 0, 0.1)',
    }
  },
  categorySelector: {
    display: 'flex',
    gap: '10px',
    marginBottom: '20px',
    overflowX: 'auto',
    paddingBottom: '10px',
    msOverflowStyle: 'none',
    scrollbarWidth: 'none',
    '&::-webkit-scrollbar': {
      display: 'none'
    }
  },
  categoryButton: {
    whiteSpace: 'nowrap',
    ...shorthands.borderRadius('10px'),
    ...shorthands.padding('8px', '20px'),
    '&.selected': {
        background: '#FFB800',
        color: '#000',
    }
  },
  menuGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))',
    gap: '16px'
  },
  menuItem: {
    ...shorthands.padding('16px'),
    background: 'rgba(255, 255, 255, 0.03)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.05)'),
    ...shorthands.borderRadius('12px'),
    transition: 'all 0.3s ease',
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
    '&:hover': {
      background: 'rgba(255, 255, 255, 0.06)',
      ...shorthands.borderColor('rgba(255, 184, 0, 0.3)'),
    }
  },
  itemHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  price: {
    fontSize: '20px',
    fontWeight: '800',
    color: '#FFB800'
  },
  cartSidebar: {
    background: 'rgba(15, 15, 15, 0.6)',
    backdropFilter: 'blur(16px)',
    padding: '24px',
    borderRadius: '16px',
    height: 'fit-content',
    position: 'sticky',
    top: '20px',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3)'
  },
  cartItem: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '12px',
    marginBottom: '8px',
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '8px',
    border: '1px solid rgba(255, 255, 255, 0.05)',
  },
  cartTotal: {
    display: 'flex',
    justifyContent: 'space-between',
    fontWeight: '800',
    fontSize: '20px',
    padding: '16px 0',
    borderTop: '1px solid rgba(255, 255, 255, 0.1)',
    marginTop: '16px',
    color: '#FFB800',
  },
  checkoutForm: {
    display: 'flex',
    flexDirection: 'column',
    gap: '16px'
  },
  input: {
    padding: '12px',
    background: 'rgba(255, 255, 255, 0.05)',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    borderRadius: '8px',
    color: '#fff',
  },
  checkoutButton: {
    background: 'linear-gradient(135deg, #FF9E00 0%, #FF6B00 100%)',
    color: '#000',
    fontWeight: '700',
    padding: '14px',
    borderRadius: '10px',
    border: 'none',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    '&:hover': {
        boxShadow: '0 0 20px rgba(255, 107, 0, 0.3)',
        filter: 'brightness(1.1)',
    }
  },
  backButton: {
    background: 'rgba(255, 255, 255, 0.05)',
    ...shorthands.border('1px', 'solid', 'rgba(255, 255, 255, 0.1)'),
    color: '#fff',
    ...shorthands.padding('10px', '20px'),
    ...shorthands.borderRadius('12px'),
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
      ...shorthands.borderColor('#FFB800'),
      transform: 'translateX(-5px)',
    }
  },
  successMessage: {
    textAlign: 'center',
    padding: '40px 24px',
    background: 'rgba(20, 20, 20, 0.6)',
    backdropFilter: 'blur(16px)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 184, 0, 0.2)',
    color: 'white',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '20px',
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
  const navigate = useNavigate()
  const [selectedCafeteria, setSelectedCafeteria] = useState<SelectedCafeteria>(CAFETERIAS[0])
  const [selectedCategory, setSelectedCategory] = useState('desayunos')
  const [cart, setCart] = useState<CartItem[]>([])
  const [userName, setUserName] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [paymentMethod, setPaymentMethod] = useState('cash')
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false)
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
      {/* Back Button */}
      <button className={styles.backButton} onClick={() => navigate('/')}>
        <ArrowLeftRegular /> Volver al Inicio
      </button>

      {/* Header */}
      <div className={styles.header}>
        <h1 className={styles.headerTitle}>☕ Cafetería UCE</h1>
        <p className={styles.headerSubtitle}>Selecciona tu cafetería y realiza tu pedido con rapidez</p>
      </div>

      {/* Cafeterías */}
      <div>
        <Title3 style={{ marginBottom: '16px', color: '#fff' }}>🏪 Cafeterías Disponibles</Title3>
        <div className={styles.cafeteriaGrid}>
          {CAFETERIAS.map(cafe => (
            <div
              key={cafe.id}
              className={`${styles.cafeteriaCard} ${selectedCafeteria.id === cafe.id ? 'selected' : ''}`}
              onClick={() => setSelectedCafeteria(cafe)}
            >
              <div style={{ fontSize: '32px', marginBottom: '12px' }}>{cafe.image}</div>
              <Title3 style={{ marginBottom: '4px', color: '#fff' }}>{cafe.name}</Title3>
              <Body2 style={{ color: '#aaa' }}>{cafe.location}</Body2>
              <Body2 style={{ color: '#FFB800', marginTop: '8px', fontWeight: '600' }}>
                {cafe.hours}
              </Body2>
            </div>
          ))}
        </div>
      </div>

      <div className={styles.mainGrid}>
        {/* Menu */}
        <div>
          <Title3 style={{ marginBottom: '16px', color: '#fff' }}>🍽️ Menú - {selectedCafeteria.name}</Title3>
          
          {/* Category Selector */}
          <div className={styles.categorySelector}>
            {Object.entries(MENU_CATEGORIES).map(([key, category]) => (
              <button
                key={key}
                className={`${styles.categoryButton} ${selectedCategory === key ? 'selected' : ''}`}
                style={{
                  background: selectedCategory === key ? '#FFB800' : 'rgba(255,255,255,0.05)',
                  color: selectedCategory === key ? '#000' : '#fff',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '10px 20px',
                  borderRadius: '10px',
                  transition: 'all 0.2s ease',
                  fontWeight: '600'
                }}
                onClick={() => setSelectedCategory(key)}
              >
                {category.icon} {category.name}
              </button>
            ))}
          </div>

          {/* Menu Items */}
          <div className={styles.menuGrid}>
            {currentMenu.items.map(item => (
              <div key={item.id} className={styles.menuItem}>
                <div className={styles.itemHeader}>
                  <div>
                    <Body1 style={{ color: '#fff', fontWeight: 'bold' }}>{item.name}</Body1>
                    <Body2 style={{ fontSize: '12px', color: '#888', marginTop: '4px', display: 'block' }}>
                      {item.description}
                    </Body2>
                  </div>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '16px' }}>
                  <div className={styles.price}>${item.price.toFixed(2)}</div>
                  <Button
                    icon={<Add24Regular />}
                    appearance="primary"
                    size="small"
                    style={{ background: '#FFB800', color: '#000' }}
                    onClick={() => addToCart(item)}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Cart Sidebar */}
        <div className={styles.cartSidebar}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '16px', gap: '8px' }}>
            <ShoppingBag24Regular style={{ color: '#FFB800' }} />
            <Title3 style={{ color: '#fff' }}>Carrito</Title3>
            {cart.length > 0 && <Badge appearance="filled" color="important">{getTotalItems()}</Badge>}
          </div>

          {cart.length === 0 ? (
            <Body2 style={{ color: '#666' }}>
              Tu carrito está vacío
            </Body2>
          ) : (
            <>
              <div style={{ maxHeight: '300px', overflowY: 'auto', marginBottom: '16px' }}>
                {cart.map(item => (
                  <div key={item.id} className={styles.cartItem}>
                    <div style={{ flex: 1 }}>
                      <Body1 style={{ color: '#fff', fontWeight: '600', fontSize: '14px' }}>{item.name}</Body1>
                      <Body2 style={{ color: '#FFB800' }}>${(item.price * item.quantity).toFixed(2)}</Body2>
                    </div>
                    <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                      <Button
                        size="small"
                        appearance="subtle"
                        style={{ color: '#fff' }}
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                      >
                        −
                      </Button>
                      <span style={{ minWidth: '20px', textAlign: 'center', color: '#fff' }}>{item.quantity}</span>
                      <Button
                        size="small"
                        appearance="subtle"
                        style={{ color: '#fff' }}
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                      >
                        +
                      </Button>
                      <Button
                        size="small"
                        appearance="subtle"
                        style={{ color: '#f44' }}
                        onClick={() => removeFromCart(item.id)}
                        icon={<Delete24Regular />}
                      />
                    </div>
                  </div>
                ))}
              </div>

              <div className={styles.cartTotal}>
                <span>TOTAL:</span>
                <span>${(getTotalPrice() * 1.1).toFixed(2)}</span>
              </div>

              <Dialog open={isCheckoutOpen} onOpenChange={(_, data) => setIsCheckoutOpen(data.open)}>
                <DialogTrigger disableButtonEnhancement>
                  <button className={styles.checkoutButton} style={{ width: '100%', marginTop: '12px' }}>
                    Proceder a Pagar
                  </button>
                </DialogTrigger>
                <DialogSurface style={{ background: '#111', color: '#fff', border: '1px solid #333' }}>
                  <DialogBody>
                    <DialogTitle style={{ color: '#FFB800' }}>Confirmar Pedido</DialogTitle>
                    <DialogContent>
                      <div style={{ marginBottom: '16px' }}>
                        <Title3 style={{ color: '#fff' }}>Resumen del Pedido</Title3>
                        {cart.map(item => (
                          <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', margin: '8px 0', fontSize: '14px', color: '#ccc' }}>
                            <span>{item.name} x{item.quantity}</span>
                            <span>${(item.price * item.quantity).toFixed(2)}</span>
                          </div>
                        ))}
                        <div style={{ borderTop: '1px solid #333', paddingTop: '8px', marginTop: '8px', fontWeight: 'bold' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', color: '#FFB800', fontSize: '18px' }}>
                            <span>Total:</span>
                            <span>${(getTotalPrice() * 1.1).toFixed(2)}</span>
                          </div>
                        </div>
                      </div>

                      <div className={styles.checkoutForm}>
                        <div style={{ marginBottom: '12px' }}>
                          <label style={{ fontSize: '13px', fontWeight: '600', display: 'block', marginBottom: '6px', color: '#aaa' }}>Nombre Completo *</label>
                          <input
                            className={styles.input}
                            value={userName}
                            onChange={(e) => setUserName(e.target.value)}
                            placeholder="Tu nombre"
                            style={{ width: '100%' }}
                          />
                        </div>

                        <div style={{ marginBottom: '12px' }}>
                          <label style={{ fontSize: '13px', fontWeight: '600', display: 'block', marginBottom: '6px', color: '#aaa' }}>Email *</label>
                          <input
                            type="email"
                            className={styles.input}
                            value={userEmail}
                            onChange={(e) => setUserEmail(e.target.value)}
                            placeholder="tu@email.com"
                            style={{ width: '100%' }}
                          />
                        </div>

                        <div style={{ marginBottom: '12px' }}>
                          <label style={{ fontSize: '13px', fontWeight: '600', display: 'block', marginBottom: '6px', color: '#aaa' }}>Método de Pago</label>
                          <select
                            className={styles.input}
                            value={paymentMethod}
                            onChange={(e) => setPaymentMethod(e.target.value)}
                            style={{ width: '100%', appearance: 'none' }}
                          >
                            <option value="cash">Efectivo</option>
                            <option value="card">Tarjeta</option>
                            <option value="transfer">Transferencia</option>
                          </select>
                        </div>
                      </div>
                    </DialogContent>
                    <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', marginTop: '24px' }}>
                      <Button appearance="subtle" style={{ color: '#fff' }} onClick={() => setIsCheckoutOpen(false)}>
                        Cancelar
                      </Button>
                      <button
                        className={styles.checkoutButton}
                        onClick={handleCheckout}
                        disabled={isProcessing || !userName || !userEmail}
                        style={{ padding: '8px 24px' }}
                      >
                        {isProcessing ? 'Procesando...' : 'Confirmar Pedido'}
                      </button>
                    </div>
                  </DialogBody>
                </DialogSurface>
              </Dialog>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
