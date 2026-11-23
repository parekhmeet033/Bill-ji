import { useState, useEffect } from 'react';
import { NavLink, Link, useLocation } from 'react-router-dom';
import { Menu, X, ArrowRight, ChevronDown, UserCheck, Store, LogIn, Sparkles } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import logoIcon from '../assets/logo_icon.png';
import logoTitle from '../assets/logo_title.png';

export default function Navbar({ onOpenDemoModal }) {
  const [isOpen, setIsOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [tutorialDropdown, setTutorialDropdown] = useState(false);
  const location = useLocation();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 10);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => {
    setIsOpen(false);
    setTutorialDropdown(false);
  }, [location.pathname]);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-40 transition-all duration-300 ${
        scrolled
          ? 'bg-white/85 backdrop-blur-md shadow-lg border-b border-slate-100 py-3'
          : 'bg-white/50 backdrop-blur-sm py-4'
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 md:px-12 flex items-center justify-between">
        {/* Logo */}
        <Link to="/" className="flex items-center space-x-3 group">
          <div className="flex flex-col justify-center text-left">
            <img
              src={logoTitle}
              alt="BillJi"
              className="h-9 md:h-11 w-auto object-contain self-start group-hover:scale-[1.02] transition-transform duration-300"
            />
          </div>
        </Link>

        {/* Center Nav Links */}
        <div className="hidden lg:flex items-center space-x-7">
          <NavLink
            to="/"
            className={({ isActive }) =>
              `font-medium text-sm transition-colors py-2 ${
                isActive ? 'text-primary font-bold' : 'text-slate-600 hover:text-primary'
              }`
            }
          >
            Home
          </NavLink>

          <NavLink
            to="/features"
            className={({ isActive }) =>
              `font-medium text-sm transition-colors py-2 ${
                isActive ? 'text-primary font-bold' : 'text-slate-600 hover:text-primary'
              }`
            }
          >
            Features
          </NavLink>

          <NavLink
            to="/pricing"
            className={({ isActive }) =>
              `font-medium text-sm transition-colors py-2 ${
                isActive ? 'text-primary font-bold' : 'text-slate-600 hover:text-primary'
              }`
            }
          >
            Pricing
          </NavLink>

          <NavLink
            to="/tutorial"
            className={({ isActive }) =>
              `font-medium text-sm transition-colors py-2 ${
                isActive ? 'text-primary font-bold' : 'text-slate-600 hover:text-primary'
              }`
            }
          >
            Tutorials
          </NavLink>

          <NavLink
            to="/about"
            className={({ isActive }) =>
              `font-medium text-sm transition-colors py-2 ${
                isActive ? 'text-primary font-bold' : 'text-slate-600 hover:text-primary'
              }`
            }
          >
            About
          </NavLink>

          <NavLink
            to="/contact"
            className={({ isActive }) =>
              `font-medium text-sm transition-colors py-2 ${
                isActive ? 'text-primary font-bold' : 'text-slate-600 hover:text-primary'
              }`
            }
          >
            Contact
          </NavLink>
        </div>

        {/* Right Actions */}
        <div className="hidden lg:flex items-center space-x-3">
          <Link
            to="/login"
            className="flex items-center space-x-2 border border-slate-200 text-secondary hover:border-primary hover:text-primary px-5 py-2.5 rounded-full font-bold text-sm transition-all duration-300"
          >
            <LogIn className="w-4 h-4" />
            <span>Login</span>
          </Link>
          <button
            onClick={onOpenDemoModal}
            className="group relative flex items-center space-x-2 bg-primary hover:bg-primary-dark text-white px-5 py-2.5 rounded-full font-bold text-sm transition-all duration-300 shadow-md hover:shadow-primary/30 hover:scale-105"
          >
            <Sparkles className="w-4 h-4 text-primary-light" />
            <span>Book Demo</span>
            <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          </button>
        </div>

        {/* Mobile Hamburger */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="lg:hidden p-2 rounded-xl text-slate-700 hover:bg-slate-100 transition-colors"
          aria-label="Toggle menu"
        >
          {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
      </div>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="absolute top-full left-0 right-0 bg-white border-b border-slate-100 shadow-2xl py-6 px-6 flex flex-col space-y-3 lg:hidden text-left"
          >
            <NavLink to="/" className="text-base font-semibold px-4 py-2 rounded-xl text-slate-700 hover:bg-slate-50">
              Home
            </NavLink>
            <NavLink to="/features" className="text-base font-semibold px-4 py-2 rounded-xl text-slate-700 hover:bg-slate-50">
              Features
            </NavLink>
            <NavLink to="/pricing" className="text-base font-semibold px-4 py-2 rounded-xl text-slate-700 hover:bg-slate-50">
              Pricing
            </NavLink>
            <NavLink to="/tutorial" className="text-base font-semibold px-4 py-2 rounded-xl text-slate-700 hover:bg-slate-50">
              Tutorials
            </NavLink>
            <NavLink to="/about" className="text-base font-semibold px-4 py-2 rounded-xl text-slate-700 hover:bg-slate-50">
              About
            </NavLink>
            <NavLink to="/contact" className="text-base font-semibold px-4 py-2 rounded-xl text-slate-700 hover:bg-slate-50">
              Contact
            </NavLink>

            <div className="pt-4 border-t border-slate-100 flex flex-col space-y-2">
              <Link
                to="/login"
                className="w-full flex items-center justify-center space-x-2 border border-slate-200 text-secondary py-3 rounded-full font-bold transition-all"
              >
                <LogIn className="w-4 h-4" />
                <span>Login</span>
              </Link>
              <button
                onClick={() => { setIsOpen(false); onOpenDemoModal(); }}
                className="w-full flex items-center justify-center space-x-2 bg-primary hover:bg-primary-dark text-white py-3 rounded-full font-bold transition-all shadow-md"
              >
                <span>Book Demo</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
}
