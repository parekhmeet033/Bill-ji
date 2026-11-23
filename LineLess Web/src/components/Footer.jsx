import { Link } from 'react-router-dom';
import logoIcon from '../assets/logo_icon.png';
import logoTitle from '../assets/logo_title.png';
import SocialIcons from './SocialIcons';
import { ArrowRight, ShieldCheck, Mail, Phone, MapPin, Sparkles } from 'lucide-react';

export default function Footer({ onOpenDemoModal }) {
  return (
    <footer className="bg-secondary text-white pt-16 pb-12 border-t border-slate-800 relative overflow-hidden text-left">
      {/* Glow Ambient Lights */}
      <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-primary/10 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-6 md:px-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10 pb-12 border-b border-slate-800">
          {/* Brand Info */}
          <div className="lg:col-span-2 space-y-4">
            <Link to="/" className="flex items-center space-x-3 group">
              <div className="flex flex-col justify-center">
                <img src={logoTitle} alt="BillJi" className="h-10 w-auto object-contain bg-white rounded-md p-1.5" />
              </div>
            </Link>

            <p className="text-slate-400 text-sm leading-relaxed max-w-sm">
              BillJi replaces fragmented tools with one complete platform combining QR Ordering, Walk-in POS, Table Management, Kitchen Display (KDS), and PIN-Protected Reports.
            </p>
          </div>

          {/* Platform Links */}
          <div className="space-y-3">
            <h4 className="text-sm font-bold uppercase tracking-wider text-white">Platform OS</h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li><Link to="/features#smart-pos" className="hover:text-primary transition-colors">Smart POS Billing</Link></li>
              <li><Link to="/features#table-layout" className="hover:text-primary transition-colors">Table Floor Layout</Link></li>
              <li><Link to="/features#kds" className="hover:text-primary transition-colors">Kitchen KDS System</Link></li>
              <li><Link to="/features#pin-security" className="hover:text-primary transition-colors">PIN Reports Security</Link></li>
              <li><Link to="/pricing" className="hover:text-primary transition-colors">SaaS Pricing Plan</Link></li>
            </ul>
          </div>

          {/* Resources */}
          <div className="space-y-3">
            <h4 className="text-sm font-bold uppercase tracking-wider text-white">Resources</h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li><Link to="/tutorial" className="hover:text-primary transition-colors">Platform Video Tutorials</Link></li>
              <li><Link to="/about" className="hover:text-primary transition-colors">About BillJi</Link></li>
              <li><Link to="/contact" className="hover:text-primary transition-colors">Contact Support</Link></li>
              <li><Link to="/privacy-policy" className="hover:text-primary transition-colors">Privacy Policy</Link></li>
              <li><button onClick={onOpenDemoModal} className="text-primary hover:underline font-bold">Book Live Demo</button></li>
            </ul>
          </div>

          {/* Contact Details */}
          <div className="space-y-3">
            <h4 className="text-sm font-bold uppercase tracking-wider text-white">We're Here</h4>
            <ul className="space-y-2.5 text-xs text-slate-400">
              <li className="flex items-start space-x-2">
                <MapPin className="w-4 h-4 text-primary shrink-0 mt-0.5" />
                <span>104, Hindva Pride, Amar Jawan Circle, Ahmedabad - 382350</span>
              </li>
              <li className="flex items-center space-x-2">
                <Mail className="w-4 h-4 text-primary shrink-0" />
                <a href="mailto:billji.support@gmail.com" className="hover:text-primary">billji.support@gmail.com</a>
              </li>
              <li className="flex items-center space-x-2">
                <Phone className="w-4 h-4 text-primary shrink-0" />
                <a href="tel:+919409111116" className="hover:text-primary">+91 94091 11116 / +91 99747 23326</a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-8 flex flex-col md:flex-row items-center justify-between text-xs text-slate-400 space-y-4 md:space-y-0">
          <div>
            © {new Date().getFullYear()} BillJi OS. All rights reserved.
          </div>

          <div className="flex items-center space-x-6">
            <Link to="/privacy-policy" className="hover:text-primary transition-colors font-medium">
              Privacy Policy
            </Link>
            <span className="text-slate-700">•</span>
            <SocialIcons />
          </div>
        </div>
      </div>
    </footer>
  );
}
