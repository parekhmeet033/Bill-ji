import React from 'react';
import {
  QrCode,
  Store,
  Grid3X3,
  RefreshCw,
  ChefHat,
  UtensilsCrossed,
  BellRing,
  CreditCard,
  ShieldCheck
} from 'lucide-react';

const workflowSteps = [
  { title: 'Customer QR Order', desc: 'Scan & order in browser', icon: QrCode, color: 'from-green-500 to-emerald-600' },
  { title: 'Walk-in POS', desc: 'Instant counter billing', icon: Store, color: 'from-blue-500 to-indigo-600' },
  { title: 'Table Orders', desc: 'Running floor tabs', icon: Grid3X3, color: 'from-amber-500 to-orange-600' },
  { title: 'Unified Engine', desc: 'Real-time order sync', icon: RefreshCw, color: 'from-purple-500 to-violet-600' },
  { title: 'Kitchen KDS', desc: 'Automatic item grouping', icon: ChefHat, color: 'from-pink-500 to-rose-600' },
  { title: 'Food Prep', desc: 'Faster kitchen throughput', icon: UtensilsCrossed, color: 'from-red-500 to-orange-500' },
  { title: 'Order Ready', desc: 'Token sound alert call', icon: BellRing, color: 'from-emerald-500 to-teal-600' },
  { title: 'Payment', desc: 'UPI, Cash & Digital', icon: CreditCard, color: 'from-cyan-500 to-blue-600' },
  { title: 'Secure Reports', desc: 'PIN protected analytics', icon: ShieldCheck, color: 'from-slate-800 to-slate-950' }
];

export default function WorkflowSection() {
  return (
    <section className="py-16 md:py-24 bg-slate-950 text-white relative overflow-hidden">
      {/* Subtle Background Glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-primary/10 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-12 text-center relative z-10">
        <span className="text-[11px] sm:text-xs font-bold uppercase tracking-widest text-primary-light bg-primary/20 px-3.5 py-1.5 rounded-full border border-primary/30 inline-block mb-3">
          End-To-End Automation Pipeline
        </span>
        <h2 className="text-2xl sm:text-4xl md:text-5xl font-black mb-10 md:mb-16 tracking-tight">
          Unified Restaurant Operating Workflow
        </h2>

        {/* Desktop View: Full horizontal line across 1 row for larger screens (lg+) */}
        <div className="hidden lg:flex items-center justify-between space-x-2">
          {workflowSteps.map((step, idx) => (
            <React.Fragment key={idx}>
              <div className="flex flex-col items-center text-center space-y-2 group flex-1">
                <div className={`w-12 h-12 xl:w-14 xl:h-14 rounded-2xl bg-gradient-to-br ${step.color} flex items-center justify-center shadow-lg group-hover:scale-110 transition-all duration-300`}>
                  <step.icon className="w-6 h-6 xl:w-7 xl:h-7 text-white" />
                </div>
                <span className="text-xs font-bold text-white max-w-[90px] leading-tight">{step.title}</span>
                <span className="text-[9px] text-slate-400 max-w-[90px]">{step.desc}</span>
              </div>

              {idx < workflowSteps.length - 1 && (
                <div className="h-[2px] flex-1 bg-gradient-to-r from-primary to-primary-light opacity-60 animate-pulse mx-0.5" />
              )}
            </React.Fragment>
          ))}
        </div>

        {/* Mobile & Tablet View: 3 x 3 Grid layout per row for mobile devices (< lg) */}
        <div className="grid lg:hidden grid-cols-3 gap-y-7 gap-x-2 sm:gap-x-4 max-w-md sm:max-w-xl mx-auto">
          {workflowSteps.map((step, idx) => (
            <div key={idx} className="flex flex-col items-center text-center group relative p-1 rounded-xl hover:bg-slate-900/60 transition-colors">
              <div className="relative mb-2">
                <div className={`w-12 h-12 sm:w-14 sm:h-14 rounded-2xl bg-gradient-to-br ${step.color} flex items-center justify-center shadow-lg group-hover:scale-105 transition-transform mx-auto`}>
                  <step.icon className="w-6 h-6 sm:w-7 sm:h-7 text-white" />
                </div>
                <span className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-slate-900 border border-slate-700 text-[10px] font-extrabold text-primary-light flex items-center justify-center shadow">
                  {idx + 1}
                </span>
              </div>
              <span className="text-[11px] sm:text-xs font-bold text-white leading-tight max-w-[95px]">{step.title}</span>
              <span className="text-[9px] text-slate-400 mt-1 leading-tight max-w-[95px]">{step.desc}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
