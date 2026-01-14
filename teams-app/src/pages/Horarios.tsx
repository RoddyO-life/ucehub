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
  CalendarRegular,
  ClockRegular,
  LocationRegular
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
    display: 'flex',
    gap: '15px',
    marginBottom: '20px',
    flexWrap: 'wrap',
  },
  schedule: {
    display: 'flex',
    flexDirection: 'column',
    gap: '15px',
  },
  dayCard: {
    padding: '20px',
  },
  classItem: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '15px',
    backgroundColor: tokens.colorNeutralBackground2,
    borderRadius: '8px',
    marginBottom: '10px',
  },
  classInfo: {
    display: 'flex',
    flexDirection: 'column',
    gap: '5px',
  },
  classTime: {
    display: 'flex',
    alignItems: 'center',
    gap: '5px',
    color: tokens.colorBrandForeground1,
  },
  backButton: {
    marginBottom: '20px',
  },
})

const Horarios = () => {
  const styles = useStyles()
  const navigate = useNavigate()
  const [selectedSemestre, setSelectedSemestre] = useState('actual')

  const horario = {
    Lunes: [
      { materia: 'Cálculo Diferencial', hora: '07:00 - 09:00', aula: 'Lab 301', profesor: 'Dr. García' },
      { materia: 'Programación I', hora: '09:00 - 11:00', aula: 'Lab 205', profesor: 'Ing. Martínez' },
      { materia: 'Física I', hora: '14:00 - 16:00', aula: 'Aula 102', profesor: 'Dr. López' },
    ],
    Martes: [
      { materia: 'Álgebra Lineal', hora: '07:00 - 09:00', aula: 'Aula 304', profesor: 'Dra. Rodríguez' },
      { materia: 'Química General', hora: '10:00 - 12:00', aula: 'Lab Química', profesor: 'Lic. Torres' },
    ],
    Miércoles: [
      { materia: 'Cálculo Diferencial', hora: '07:00 - 09:00', aula: 'Lab 301', profesor: 'Dr. García' },
      { materia: 'Programación I', hora: '09:00 - 11:00', aula: 'Lab 205', profesor: 'Ing. Martínez' },
      { materia: 'Inglés I', hora: '15:00 - 17:00', aula: 'Aula 201', profesor: 'Prof. Smith' },
    ],
    Jueves: [
      { materia: 'Álgebra Lineal', hora: '07:00 - 09:00', aula: 'Aula 304', profesor: 'Dra. Rodríguez' },
      { materia: 'Física I', hora: '14:00 - 16:00', aula: 'Aula 102', profesor: 'Dr. López' },
    ],
    Viernes: [
      { materia: 'Programación I (Lab)', hora: '08:00 - 12:00', aula: 'Lab 205', profesor: 'Ing. Martínez' },
      { materia: 'Tutoría Académica', hora: '14:00 - 15:00', aula: 'Aula 150', profesor: 'Coordinador' },
    ],
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
        <CalendarRegular className={styles.icon} />
        <div>
          <Title2>Horario de Clases</Title2>
          <Body1>Consulta tu horario semanal de clases</Body1>
        </div>
      </div>

      <div className={styles.filters}>
        <Dropdown
          placeholder="Selecciona semestre"
          value={selectedSemestre}
          onOptionSelect={(_: any, data: any) => setSelectedSemestre(data.optionValue as string)}
        >
          <Option value="actual">Semestre Actual (2025-1)</Option>
          <Option value="anterior">Semestre Anterior (2024-2)</Option>
        </Dropdown>
      </div>

      <div className={styles.schedule}>
        {Object.entries(horario).map(([dia, clases]) => (
          <Card key={dia} className={styles.dayCard}>
            <Title3 style={{ marginBottom: '15px' }}>{dia}</Title3>
            {clases.map((clase, idx) => (
              <div key={idx} className={styles.classItem}>
                <div className={styles.classInfo}>
                  <Title3>{clase.materia}</Title3>
                  <div className={styles.classTime}>
                    <ClockRegular />
                    <Body1>{clase.hora}</Body1>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                    <LocationRegular />
                    <Body1>{clase.aula}</Body1>
                  </div>
                  <Body1 style={{ color: tokens.colorNeutralForeground3 }}>
                    {clase.profesor}
                  </Body1>
                </div>
                <Badge color="informative">Presencial</Badge>
              </div>
            ))}
          </Card>
        ))}
      </div>
    </div>
  )
}

export default Horarios
