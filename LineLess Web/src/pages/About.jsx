import { motion } from 'framer-motion';
import { ShieldCheck, Zap, Globe, Layers, MapPin, Mail, Phone, ArrowRight, Award } from 'lucide-react';
import { Link } from 'react-router-dom';
import logoIcon from '../assets/logo_icon.png';
import logoTitle from '../assets/logo_title.png';

export default function About({ onOpenDemoModal }) {
  const values = [
    {
      icon: Zap,
      title: 'Zero Friction Ordering',
      desc: 'We believe customers should never have to download heavy apps or stand in long tiring queues just to buy food.'
    },
    {
      icon: Layers,
      title: 'Complete Operating System',
      desc: 'BillJi combines QR ordering, offline POS billing, table floor layout, KDS, and secure reports into one platform.'
    },
    {
      icon: ShieldCheck,
      title: 'Security & Control',
      desc: 'Protecting restaurant business revenue with owner-only 6-digit PIN verification for sensitive analytics.'
    },
    {
      icon: Globe,
      title: 'Built for Scale',
      desc: 'Designed to support single-outlet cafés, cloud kitchens, and multi-outlet franchises.'
    }
  ];

  return (
    <div className="bg-white min-h-screen pt-12 pb-24">
      {/* Background Ambient Gradient */}
      <div className="max-w-7xl mx-auto px-6 md:px-12 relative">
        <div className="absolute top-0 right-0 w-[500px] h-[300px] bg-primary/10 rounded-full blur-3xl -z-10" />

        {/* Hero Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-24">
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.7 }}
            className="space-y-6 text-left"
          >
            <h1 className="text-4xl md:text-6xl font-black text-secondary leading-tight">
              Reinventing How Food Outlets Serve Customers.
            </h1>

            <p className="text-slate-600 text-lg leading-relaxed">
              BillJi was founded with a singular mission: to eliminate physical checkout queues, speed up food preparation in kitchens, and provide restaurant owners with a complete digital operating system.
            </p>

            <div className="flex flex-wrap gap-4 pt-2">
              <button
                onClick={onOpenDemoModal}
                className="bg-primary hover:bg-primary-dark text-white font-bold px-8 py-3.5 rounded-full shadow-lg hover:shadow-primary/30 transition-all hover:scale-105 flex items-center space-x-2"
              >
                <span>Book Product Demo</span>
                <ArrowRight className="w-4 h-4" />
              </button>
              <Link
                to="/contact"
                className="border-2 border-slate-200 hover:border-slate-800 text-secondary font-bold px-8 py-3.5 rounded-full transition-all hover:scale-105"
              >
                Contact Our Team
              </Link>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.7 }}
            className="bg-slate-900 text-white p-8 md:p-12 rounded-3xl shadow-2xl relative overflow-hidden"
          >
            <div className="flex items-center space-x-3 mb-6">
              <img src={logoIcon} alt="BillJi Icon" className="h-12 w-auto" />
              <img src={logoTitle} alt="BillJi Title" className="h-6 w-auto brightness-0 invert" />
            </div>

            <h3 className="text-2xl font-bold mb-4 text-primary">The BillJi Philosophy</h3>
            <p className="text-slate-300 text-sm leading-relaxed mb-6">
              Traditional POS hardware is bloated, expensive, and disconnected from customer QR ordering. BillJi unifies QR Menu scanning, Walk-in POS billing, Table management, Kitchen Displays (KDS), and PIN-protected analytics into one cloud platform.
            </p>

            <div className="grid grid-cols-2 gap-4 pt-4 border-t border-slate-800 text-left">
              <div>
                <span className="block text-3xl font-black text-white">3x</span>
                <span className="text-xs text-slate-400">Order Throughput</span>
              </div>
              <div>
                <span className="block text-3xl font-black text-white">0 Secs</span>
                <span className="text-xs text-slate-400">Queue Waiting Time</span>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Core Values Grid */}
        <div className="mb-24">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <span className="text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-4 py-1.5 rounded-full">
              Our Core Pillars
            </span>
            <h2 className="text-3xl md:text-4xl font-black text-secondary mt-3">
              Why Restaurants Trust BillJi OS
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 text-left">
            {values.map((v, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: idx * 0.1 }}
                className="bg-slate-50 p-8 rounded-3xl border border-slate-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1"
              >
                <div className="w-12 h-12 bg-primary/10 text-primary rounded-2xl flex items-center justify-center mb-6">
                  <v.icon className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold text-secondary mb-3">{v.title}</h3>
                <p className="text-slate-500 text-sm leading-relaxed">{v.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>

        {/* BillJi Company Info */}
        <div className="bg-slate-50 p-8 md:p-12 rounded-3xl border border-slate-100 text-left grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="space-y-3">
            <div className="flex items-center space-x-2 text-primary font-bold text-sm">
              <MapPin className="w-4 h-4" />
              <span>Headquarters</span>
            </div>
            <p className="text-slate-700 text-sm leading-relaxed">
              BillJi<br />
              104, Hindva Pride, Near Sankalp International School, Amar Jawan Circle, Ahmedabad - 382350, India
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex items-center space-x-2 text-primary font-bold text-sm">
              <Mail className="w-4 h-4" />
              <span>Email Support</span>
            </div>
            <p className="text-slate-700 text-sm">
              billji.support@gmail.com
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex items-center space-x-2 text-primary font-bold text-sm">
              <Phone className="w-4 h-4" />
              <span>Phone & Sales</span>
            </div>
            <p className="text-slate-700 text-sm">
              +91 99747 23326<br />
              Mon - Sat (9:00 AM - 7:00 PM)
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
