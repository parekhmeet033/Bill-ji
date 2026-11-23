import { useState, lazy, Suspense } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import ScrollToTop from './components/ScrollToTop';
import BookDemoModal from './components/BookDemoModal';
import Home from './pages/Home';
import Features from './pages/Features';
import Pricing from './pages/Pricing';
import About from './pages/About';
import Tutorial from './pages/Tutorial';
import Contact from './pages/Contact';
import PrivacyPolicy from './pages/PrivacyPolicy';
import Login from './pages/Login';
import { AuthProvider } from './app/auth/AuthContext';

const AppRoutes = lazy(() => import('./app/AppRoutes'));

// Marketing site chrome (navbar + footer + modals) around the public pages.
function MarketingLayout() {
  const [isDemoModalOpen, setIsDemoModalOpen] = useState(false);
  const openDemoModal = () => setIsDemoModalOpen(true);
  const closeDemoModal = () => setIsDemoModalOpen(false);

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <Navbar onOpenDemoModal={openDemoModal} />
      <BookDemoModal isOpen={isDemoModalOpen} onClose={closeDemoModal} />
      <main className="flex-grow pb-0 pt-24">
        <Routes>
          <Route path="/" element={<Home onOpenDemoModal={openDemoModal} />} />
          <Route path="/features" element={<Features onOpenDemoModal={openDemoModal} />} />
          <Route path="/pricing" element={<Pricing onOpenDemoModal={openDemoModal} />} />
          <Route path="/about" element={<About onOpenDemoModal={openDemoModal} />} />
          <Route path="/tutorial" element={<Tutorial onOpenDemoModal={openDemoModal} />} />
          <Route path="/contact" element={<Contact onOpenDemoModal={openDemoModal} />} />
          <Route path="/privacy-policy" element={<PrivacyPolicy onOpenDemoModal={openDemoModal} />} />
        </Routes>
      </main>
      <Footer onOpenDemoModal={openDemoModal} />
    </div>
  );
}

function App() {
  return (
    <Router>
      <ScrollToTop />
      <AuthProvider>
        <Suspense fallback={<div className="flex min-h-screen items-center justify-center font-sans text-slate-500">Loading...</div>}>
          <Routes>
            {/* Vendor login + web app (no marketing chrome) */}
            <Route path="/login" element={<Login />} />
            <Route path="/app/*" element={<AppRoutes />} />
            {/* Everything else is the marketing site */}
            <Route path="/*" element={<MarketingLayout />} />
          </Routes>
        </Suspense>
      </AuthProvider>
    </Router>
  );
}

export default App;
