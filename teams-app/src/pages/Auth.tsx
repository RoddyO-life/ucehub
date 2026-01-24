import { useState } from 'react'
import {
  makeStyles,
  Button,
  Input,
  Title2,
  Body1,
  Spinner,
} from '@fluentui/react-components'
import axios from 'axios'

const useStyles = makeStyles({
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '100vh',
    background: 'radial-gradient(circle at top right, #1a1a1a, #020202)',
    padding: '20px',
  },
  card: {
    padding: '40px',
    maxWidth: '400px',
    width: '100%',
    background: 'rgba(20, 20, 20, 0.7)',
    backdropFilter: 'blur(10px)',
    border: '1px solid rgba(255, 184, 0, 0.2)',
    boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
    borderRadius: '16px',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
  },
  logo: {
    width: '80px',
    height: '80px',
    marginBottom: '20px',
    background: 'linear-gradient(135deg, #FFB800, #FF6B00)',
    borderRadius: '20%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: 'black',
    fontSize: '32px',
    fontWeight: 'bold',
    boxShadow: '0 0 20px rgba(255, 184, 0, 0.3)',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
    width: '100%',
    marginTop: '10px',
  },
  title: {
    textAlign: 'center',
    color: '#FFB800',
    marginBottom: '8px',
  },
  subtitle: {
    color: '#888',
    marginBottom: '24px',
    textAlign: 'center',
  },
  input: {
    '& .fui-Input__input': {
      backgroundColor: 'rgba(0, 0, 0, 0.3)',
      color: 'white',
    },
    '&:hover': {
      borderColor: '#FFB800',
    }
  },
  loginButton: {
    marginTop: '10px',
    background: 'linear-gradient(90deg, #FFB800, #FF6B00)',
    color: 'black',
    fontWeight: 'bold',
    height: '45px',
    '&:hover': {
      background: 'linear-gradient(90deg, #FF6B00, #FFB800)',
      boxShadow: '0 0 15px rgba(255, 184, 0, 0.4)',
    }
  },
  message: {
    marginTop: '20px',
    padding: '12px',
    borderRadius: '8px',
    width: '100%',
    textAlign: 'center',
    fontSize: '14px',
  }
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
      const apiUrl = import.meta.env.VITE_API_URL || '/api'
      const response = await axios.post(`${apiUrl}/auth/login`, {
        email,
        password,
      })

      localStorage.setItem('token', response.data.token)
      setMessage(`¡Bienvenido ${response.data.user.name}!`)
      window.location.href = '/'
    } catch (error: any) {
      setMessage('Error: ' + (error.response?.data?.message || error.message))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <div className={styles.logo}>U</div>
        <Title2 className={styles.title}>Welcome Back</Title2>
        <Body1 className={styles.subtitle}>UCE Hub Digital Experience</Body1>

        <form className={styles.form} onSubmit={(e) => { e.preventDefault(); handleLogin(); }}>
          <Input
            className={styles.input}
            type="email"
            placeholder="correo@uce.edu.ec"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <Input
            className={styles.input}
            type="password"
            placeholder="Contraseña"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <Button
            className={styles.loginButton}
            appearance="primary"
            type="submit"
            disabled={loading}
          >
            {loading ? <Spinner size="tiny" /> : 'Iniciar Sesión'}
          </Button>
        </form>

        {message && (
          <div 
            className={styles.message}
            style={{
              backgroundColor: message.includes('Error') ? 'rgba(255, 77, 77, 0.1)' : 'rgba(77, 255, 77, 0.1)',
              color: message.includes('Error') ? '#ff4d4d' : '#4dff4d',
              border: `1px solid ${message.includes('Error') ? 'rgba(255, 77, 77, 0.2)' : 'rgba(77, 255, 77, 0.2)'}`
            }}
          >
            {message}
          </div>
        )}
      </div>
    </div>
  )
}

export default Auth

