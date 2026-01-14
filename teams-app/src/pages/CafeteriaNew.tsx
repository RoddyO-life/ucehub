import { useState, useEffect } from 'react'
import {
  Button,
  Card,
  Title3,
  Body1,
  Subtitle2,
  Badge,
  tokens,
  makeStyles,
  shorthands,
  Spinner,
  Dialog,
  DialogTrigger,
  DialogSurface,
  DialogTitle,
  DialogBody,
  DialogActions,
  DialogContent,
  Input,
  Field
} from '@fluentui/react-components'
import {
  ShoppingBag24Regular,
  Add24Regular,
  Delete24Regular,
  Payment24Regular
} from '@fluentui/react-icons'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    ...shorthands.padding('24px'),
    backgroundColor: tokens.colorNeutralBackground3,
    minHeight: '100vh'
  },
  header: {
    textAlign: 'center',
    ...shorthands.padding('20px'),
    backgroundColor: tokens.colorPaletteCranberryBackground2,
    ...shorthands.borderRadius('12px'),
    color: 'white',
    marginBottom: '24px'
  },
  menuGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))',
    ...shorthands.gap('16px'),
    marginBottom: '24px'
  },
  menuCard: {
    ...shorthands.padding('16px'),
    textAlign: 'center'
  },
  itemImage: {
    fontSize: '48px',
    marginBottom: '12px'
  },
  cartSection: {
    position: 'fixed',
    bottom: '0',
    left: '0',
    right: '0',
    backgroundColor: tokens.colorNeutralBackground1,
    ...shorthands.padding('16px'),
    boxShadow: tokens.shadow16,
    zIndex: 1000
  },
  cartContent: {
    maxWidth: '1200px',
    margin: '0 auto',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center'
  }
})

interface MenuItem {
  id: string
  name: string
  price: number
  category: string
  image: string
}

interface CartItem extends MenuItem {
  quantity: number
}

export default function Cafeteria() {
  const styles = useStyles()
  const [menu, setMenu] = useState<MenuItem[]>([])
  const [cart, setCart] = useState<CartItem[]>([])
  const [loading, setLoading] = useState(true)
  const [orderDialogOpen, setOrderDialogOpen] = useState(false)
  const [userName, setUserName] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [paymentMethod, setPaymentMethod] = useState('cash')
  const [submitting, setSubmitting] = useState(false)

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001'

  useEffect(() => {
    loadMenu()
  }, [])

  const loadMenu = async () => {
    try {
      const response = await axios.get(`${API_URL}/cafeteria/menu`)
      setMenu(response.data.data)
    } catch (error) {
      console.error('Error loading menu:', error)
    } finally {
      setLoading(false)
    }
  }

  const addToCart = (item: MenuItem) => {
    const existingItem = cart.find(i => i.id === item.id)
    if (existingItem) {
      setCart(cart.map(i => 
        i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
      ))
    } else {
      setCart([...cart, { ...item, quantity: 1 }])
    }
  }



  const clearCart = () => {
    setCart([])
  }

  const getTotalPrice = () => {
    return cart.reduce((sum, item) => sum + (item.price * item.quantity), 0)
  }

  const getTotalItems = () => {
    return cart.reduce((sum, item) => sum + item.quantity, 0)
  }

  const handleSubmitOrder = async () => {
    if (!userName || !userEmail) {
      alert('Por favor ingresa tu nombre y email')
      return
    }

    setSubmitting(true)
    try {
      const orderData = {
        items: cart,
        total: getTotalPrice(),
        userName,
        userEmail,
        paymentMethod
      }

      const response = await axios.post(`${API_URL}/api/cafeteria/order`, orderData)
      
      alert(`¡Pedido realizado con éxito! ID: ${response.data.data.orderId}\n\nRecibirás una confirmación en ${userEmail}`)
      clearCart()
      setOrderDialogOpen(false)
      setUserName('')
      setUserEmail('')
    } catch (error) {
      console.error('Error submitting order:', error)
      alert('Error al realizar el pedido. Por favor intenta nuevamente.')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '40px' }}>
        <Spinner size="large" label="Cargando menú..." />
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <Title3 style={{ marginBottom: '8px' }}>☕ Cafetería UCE</Title3>
        <Subtitle2>Realiza tu pedido online</Subtitle2>
      </div>

      <div className={styles.menuGrid}>
        {menu.map((item) => (
          <Card key={item.id} className={styles.menuCard}>
            <div className={styles.itemImage}>{item.image}</div>
            <Subtitle2>{item.name}</Subtitle2>
            <Badge appearance="tint">{item.category}</Badge>
            <Title3 style={{ margin: '12px 0', color: tokens.colorBrandForeground1 }}>
              ${item.price.toFixed(2)}
            </Title3>
            <Button
              appearance="primary"
              icon={<Add24Regular />}
              onClick={() => addToCart(item)}
              style={{ width: '100%' }}
            >
              Agregar al carrito
            </Button>
          </Card>
        ))}
      </div>

      {cart.length > 0 && (
        <div className={styles.cartSection}>
          <div className={styles.cartContent}>
            <div>
              <Body1 style={{ fontWeight: 600 }}>
                <ShoppingBag24Regular /> {getTotalItems()} productos
              </Body1>
              <Title3 style={{ color: tokens.colorBrandForeground1 }}>
                Total: ${getTotalPrice().toFixed(2)}
              </Title3>
            </div>
            <div style={{ display: 'flex', gap: '12px' }}>
              <Button icon={<Delete24Regular />} onClick={clearCart}>
                Limpiar
              </Button>
              
              <Dialog open={orderDialogOpen} onOpenChange={(_, data) => setOrderDialogOpen(data.open)}>
                <DialogTrigger disableButtonEnhancement>
                  <Button appearance="primary" icon={<Payment24Regular />}>
                    Realizar Pedido
                  </Button>
                </DialogTrigger>
                <DialogSurface>
                  <DialogBody>
                    <DialogTitle>Confirmar Pedido</DialogTitle>
                    <DialogContent>
                      <div style={{ marginBottom: '16px' }}>
                        <Subtitle2>Resumen del Pedido:</Subtitle2>
                        {cart.map(item => (
                          <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', margin: '8px 0' }}>
                            <span>{item.name} x{item.quantity}</span>
                            <span>${(item.price * item.quantity).toFixed(2)}</span>
                          </div>
                        ))}
                        <div style={{ borderTop: '1px solid #ccc', paddingTop: '8px', marginTop: '8px', fontWeight: 'bold' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                            <span>Total:</span>
                            <span>${getTotalPrice().toFixed(2)}</span>
                          </div>
                        </div>
                      </div>

                      <Field label="Nombre completo" required>
                        <Input
                          value={userName}
                          onChange={(_, data) => setUserName(data.value)}
                          placeholder="Tu nombre"
                        />
                      </Field>

                      <Field label="Email" required style={{ marginTop: '12px' }}>
                        <Input
                          value={userEmail}
                          onChange={(_, data) => setUserEmail(data.value)}
                          placeholder="tu@email.com"
                          type="email"
                        />
                      </Field>

                      <Field label="Método de pago" style={{ marginTop: '12px' }}>
                        <select
                          value={paymentMethod}
                          onChange={(e) => setPaymentMethod(e.target.value)}
                          style={{ width: '100%', padding: '8px', borderRadius: '4px', border: '1px solid #ccc' }}
                        >
                          <option value="cash">Efectivo</option>
                          <option value="card">Tarjeta</option>
                          <option value="transfer">Transferencia</option>
                        </select>
                      </Field>
                    </DialogContent>
                    <DialogActions>
                      <Button appearance="secondary" onClick={() => setOrderDialogOpen(false)}>
                        Cancelar
                      </Button>
                      <Button
                        appearance="primary"
                        onClick={handleSubmitOrder}
                        disabled={submitting}
                      >
                        {submitting ? <Spinner size="tiny" /> : 'Confirmar Pedido'}
                      </Button>
                    </DialogActions>
                  </DialogBody>
                </DialogSurface>
              </Dialog>
            </div>
          </div>
        </div>
      )}

      <div style={{ height: cart.length > 0 ? '100px' : '0' }} />
    </div>
  )
}
