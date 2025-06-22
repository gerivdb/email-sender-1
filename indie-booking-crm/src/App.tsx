import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { Layout } from './components/layout/Layout'
import { Dashboard } from './components/dashboard/Dashboard'
import { Contacts } from './components/contacts/Contacts'
import { Deals } from './components/deals/Deals'
import { TourPlanner } from './components/tour-planner/TourPlanner'
import { Calendar } from './components/calendar/Calendar'
import { Finance } from './components/finance/Finance'
import { MediaPR } from './components/media-pr/MediaPR'
import { Analytics } from './components/analytics/Analytics'
import { Settings } from './components/settings/Settings'

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/contacts" element={<Contacts />} />
          <Route path="/deals" element={<Deals />} />
          <Route path="/tour-planner" element={<TourPlanner />} />
          <Route path="/calendar" element={<Calendar />} />
          <Route path="/finance" element={<Finance />} />
          <Route path="/media-pr" element={<MediaPR />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  )
}

export default App
