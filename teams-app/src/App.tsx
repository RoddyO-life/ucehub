import { useEffect, useState } from 'react'
import { FluentProvider, webLightTheme, webDarkTheme } from '@fluentui/react-components'
import { app } from '@microsoft/teams-js'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Home from './pages/Home'
import Auth from './pages/Auth'
import CertificadosNew from './pages/CertificadosNew'
import Biblioteca from './pages/Biblioteca'
import Support from './pages/Support'
import Justifications from './pages/Justifications'
import Becas from './pages/Becas'
import Horarios from './pages/Horarios'
import CafeteriaProNew from './pages/CafeteriaProNew'
import './App.css'

function App() {
  const [teamsContext, setTeamsContext] = useState<any>(null)
  const [theme, setTheme] = useState(webLightTheme)
  const [isInTeams, setIsInTeams] = useState(false)

  useEffect(() => {
    // Inicializar Teams SDK
    const initTeams = async () => {
      try {
        await app.initialize()
        const context = await app.getContext()
        setTeamsContext(context)
        setIsInTeams(true)
        
        // Configurar tema basado en Teams
        if (context.app.theme === 'dark') {
          setTheme(webDarkTheme)
        } else {
          setTheme(webLightTheme)
        }
        
        console.log('Teams context:', context)
      } catch (error) {
        console.log('No estamos en Teams, modo standalone')
        setIsInTeams(false)
      }
    }

    initTeams()
  }, [])

  return (
    <FluentProvider theme={theme}>
      <Router>
        <Routes>
          <Route path="/" element={<Home teamsContext={teamsContext} isInTeams={isInTeams} />} />
          <Route path="/auth" element={<Auth />} />
          <Route path="/certificados" element={<CertificadosNew />} />
          <Route path="/biblioteca" element={<Biblioteca />} />
          <Route path="/support" element={<Support />} />
          <Route path="/justifications" element={<Justifications />} />
          <Route path="/becas" element={<Becas />} />
          <Route path="/horarios" element={<Horarios />} />
          <Route path="/cafeteria" element={<CafeteriaProNew />} />
        </Routes>
      </Router>
    </FluentProvider>
  )
}

export default App
