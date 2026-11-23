import { motion } from 'framer-motion';
import { CheckCircle2, Zap, Sparkles, ArrowRight, ShieldCheck } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Pricing({ onOpenDemoModal }) {
  const planFeatures = [
    'Scan-to-Order Unlimited QR Menu',
    'Smart POS System for Walk-in Billing',
    'Digital Table Management & Floor Layout',
    'Smart Kitchen Display System (KDS)',
    'Automatic Similar Order Item Grouping',
    '6-Digit PIN Protected Reports & Analytics',
    'Real-time Sales Summary & Token Tracking',
    'Product Availability One-Click Controls',
    '24/7 Customer Support'
  ];

  return (
    <div className="bg-white min-h-screen pt-12 pb-24 text-left">
      {/* Glow Background */}
      <div className="max-w-7xl mx-auto px-6 md:px-12 relative">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[500px] h-[300px] bg-primary/10 rounded-full blur-3xl -z-10" />

        {/* Page Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
          <span className="inline-flex items-center space-x-2 bg-primary/10 border border-primary/20 text-primary px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest">
            <Zap className="w-3.5 h-3.5 fill-primary" />
            <span>Simple All-In-One Plan</span>
          </span>
          <h1 className="text-4xl md:text-6xl font-black text-secondary leading-tight">
            One Flat Price. Full Restaurant OS.
          </h1>
          <p className="text-slate-600 text-lg md:text-xl">
            No complex tiers. Get complete access to QR Ordering, Smart POS, Table Layout, KDS, and Secure PIN Reports for one simple annual price.
          </p>
        </div>

        {/* Single ₹11,111 / Year Pricing Card */}
        <div className="max-w-2xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="bg-white rounded-3xl p-8 md:p-12 border-2 border-primary shadow-2xl shadow-primary/10 ring-2 ring-primary/20 relative overflow-hidden"
          >
            {/* Top Badge */}
            <div className="absolute top-0 right-0 bg-primary text-white text-xs font-black uppercase tracking-wider px-6 py-2 rounded-bl-2xl shadow-md flex items-center space-x-1.5">
              <Sparkles className="w-4 h-4 text-primary-light" />
              <span>Full Access Plan</span>
            </div>

            <div className="mb-8">
              <span className="text-xs font-bold uppercase tracking-widest text-slate-400 bg-slate-100 px-3 py-1 rounded-full">
                BillJi Restaurant OS
              </span>
              <h2 className="text-3xl font-black text-secondary mt-3">Annual Unlimited Plan</h2>
              <p className="text-slate-500 text-sm mt-1">
                Everything your snack outlet, cloud kitchen, or restaurant needs.
              </p>
            </div>

            {/* Price Box */}
            <div className="bg-slate-50 p-6 rounded-2xl border border-slate-200 mb-8 flex flex-col sm:flex-row sm:items-baseline justify-between">
              <div>
                <div className="flex items-baseline space-x-2">
                  <span className="text-5xl font-black text-secondary">₹11,111</span>
                  <span className="text-slate-600 font-bold text-lg">/ 1 Year</span>
                </div>
                <span className="text-xs text-primary font-bold mt-1 block">
                  Just ₹926 / month • Billed annually
                </span>
              </div>
              <div className="mt-3 sm:mt-0 text-left sm:text-right">
                <span className="text-xs font-bold text-emerald-600 bg-emerald-100 px-3 py-1 rounded-full">
                  100% Free Updates Included
                </span>
              </div>
            </div>

            {/* Special Discount Note */}
            <div className="mb-8 flex items-center space-x-2 bg-primary/10 border border-primary/20 text-primary text-sm font-bold px-4 py-3 rounded-2xl">
              <Sparkles className="w-4 h-4 fill-primary shrink-0" />
              <span>Special discount for the first 100 customers.</span>
            </div>

            {/* Features Checklist */}
            <div className="space-y-4 mb-10">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400 block mb-2">
                What’s Included in ₹11,111 / Year:
              </span>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
                {planFeatures.map((feat, idx) => (
                  <div key={idx} className="flex items-start space-x-3 text-sm text-slate-700">
                    <CheckCircle2 className="w-5 h-5 text-primary shrink-0 mt-0.5" />
                    <span className="font-medium">{feat}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Call to Action Button */}
            <button
              onClick={onOpenDemoModal}
              className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-4 rounded-full shadow-xl hover:shadow-primary/30 transition-all duration-300 hover:scale-[1.02] flex items-center justify-center space-x-2 text-lg"
            >
              <span>Book Demo & Get Started</span>
              <ArrowRight className="w-5 h-5" />
            </button>
          </motion.div>
        </div>

        {/* Security & Guarantee Note */}
        <div className="mt-12 text-center text-xs text-slate-500 flex items-center justify-center space-x-2">
          <ShieldCheck className="w-4 h-4 text-primary" />
          <span>Zero hidden charges. Setup and onboarding supported.</span>
        </div>
      </div>
    </div>
  );
}
