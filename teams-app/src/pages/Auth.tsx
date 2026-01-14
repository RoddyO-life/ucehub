import { useState } from 'react'
import {
  makeStyles,
  Button,
  Input,
  Card,
  Title2,
  Body1,
  tokens,
  Spinner,
} from '@fluentui/react-components'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '100vh',
    backgroundColor: tokens.colorNeutralBackground2,
  },
  card: {
    padding: '40px',
    maxWidth: '400px',
    width: '100%',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
    marginTop: '20px',
  },
  title: {
    textAlign: 'center',
    color: tokens.colorBrandForeground1,
  },
})

const Auth = () => {
  const styles = useStyles()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  const handleLogin = async () => {
    setLoading(true)
    setMessage('')

    try {
      const apiUrl = import.meta.env.VITE_API_URL
      const response = await axios.post(`${apiUrl}/auth/login`, {
        email,
        password,
      })

      setMessage(`¡Bienvenido ${response.data.user.name}!`)
      console.log('Login response:', response.data)
    } catch (error: any) {
      setMessage('Error al iniciar sesión: ' + (error.response?.data?.message || error.message))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.container}>
      <Card className={styles.card}>
        <Title2 className={styles.title}>🎓 UCEHub Login</Title2>
        <Body1 style={{ textAlign: 'center', marginTop: '10px' }}>
          Inicia sesión con tu cuenta UCE
        </Body1>

        <form className={styles.form} onSubmit={(e) => { e.preventDefault(); handleLogin(); }}>
          <Input
            type="email"
            placeholder="correo@uce.edu.ec"
            value={email}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEmail(e.target.value)}
            required
          />
          <Input
            type="password"
            placeholder="Contraseña"
            value={password}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setPassword(e.target.value)}
            required
          />
          <Button
            appearance="primary"
            type="submit"
            disabled={loading}
            style={{ width: '100%' }}
          >
            {loading ? <Spinner size="tiny" /> : 'Iniciar Sesión'}
          </Button>
        </form>

        {message && (
          <Body1
            style={{
              marginTop: '20px',
              padding: '10px',
              borderRadius: '4px',
              backgroundColor: message.includes('Error') ? '#f8d7da' : '#d4edda',
              color: message.includes('Error') ? '#721c24' : '#155724',
            }}
          >
            {message}
          </Body1>
        )}
      </Card>
    </div>
  )
}

export default Auth
