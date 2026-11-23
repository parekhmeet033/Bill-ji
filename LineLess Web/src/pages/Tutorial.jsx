import { useState } from 'react';
import { motion } from 'framer-motion';
import { QrCode, ShoppingBag, UserCheck, CheckCircle2, Store, ToggleLeft, BarChart3, Settings, ShieldCheck, ArrowRight } from 'lucide-react';

// Import tutorial screenshot assets
import tutorialQr from '../assets/tutorial_qr.png';
import tutorialCustMenu from '../assets/tutorial_cust_menu.png';
import tutorialCustDetails from '../assets/tutorial_cust_details.png';
import tutorialCustConfirmed from '../assets/tutorial_cust_confirmed.png';
import tutorialCustOrderslip from '../assets/tutorial_cust_orderslip.png';
import tutorialDashboard from '../assets/tutorial_dashboard.png';
import tutorialMenu from '../assets/tutorial_menu.png';
import tutorialReports from '../assets/tutorial_reports.png';
import tutorialSettings from '../assets/tutorial_settings.png';
import tutorialLogin from '../assets/tutorial_login.png';

export default function Tutorial({ onOpenDemoModal }) {
  const [activeTab, setActiveTab] = useState('customer');

  const customerSteps = [
    {
      step: 'Step 1',
      title: 'Scan Shop QR Code',
      hindi: 'Bas QR Scan Karo.',
      desc: 'Walk up to the counter or table and scan the unique QR code on the display stand using your native phone camera. No app download required.',
      image: tutorialQr,
      badge: 'Zero App Installation'
    },
    {
      step: 'Step 2',
      title: 'Browse Visual Menu',
      hindi: 'Menu dekho aur items select karo.',
      desc: 'Explore menu categories like Pizza, Burgers, Beverages, and Desserts with live prices and item descriptions directly in your phone browser.',
      image: tutorialCustMenu,
      badge: 'Fast Menu Load'
    },
    {
      step: 'Step 3',
      title: 'Enter Customer Details',
      hindi: 'Apni details enter karo.',
      desc: 'Enter your name and mobile number for instant token receipt and SMS notifications when your order is ready for pickup.',
      image: tutorialCustDetails,
      badge: 'Quick Checkout'
    },
    {
      step: 'Step 4',
      title: 'Order Confirmed',
      hindi: 'Order submit ho gaya!',
      desc: 'Your order is instantly transmitted to the kitchen crew dashboard and sound alert system. Relax comfortably at your seat.',
      image: tutorialCustConfirmed,
      badge: 'Instant Kitchen Sync'
    },
    {
      step: 'Step 5',
      title: 'Live Order Slip & Token Tracking',
      hindi: 'Token number track karo.',
      desc: 'Track your live order token status in real time. Collect your freshly prepared food only when your token number is called.',
      image: tutorialCustOrderslip,
      badge: 'Real-time Token'
    }
  ];

  const ownerSteps = [
    {
      step: 'Step 1',
      title: 'Master Admin Login',
      hindi: 'Dashboard login karo.',
      desc: 'Login securely to your BillJi Shop Master Account from any smartphone, tablet, or laptop browser to manage counter operations.',
      image: tutorialLogin,
      badge: 'Cloud Access'
    },
    {
      step: 'Step 2',
      title: 'Real-Time Sales Dashboard',
      hindi: 'Active orders aur revenue dekho.',
      desc: 'Monitor active customer tokens, today total revenue, total orders served, and GO POS button for walk-in billing.',
      image: tutorialDashboard,
      badge: 'Live Overview'
    },
    {
      step: 'Step 3',
      title: 'Product Availability Control',
      hindi: 'Item in-stock / sold-out toggle karo.',
      desc: 'Toggle product availability in one click from the admin dashboard to prevent customers from ordering sold-out menu items.',
      image: tutorialMenu,
      badge: 'Instant Toggle'
    },
    {
      step: 'Step 4',
      title: 'Sales Reports & Analytics',
      hindi: 'Daily closing reports dekho.',
      desc: 'Review daily revenue charts, token volume logs, and export closing sales summaries to track business growth.',
      image: tutorialReports,
      badge: 'PIN Secured'
    },
    {
      step: 'Step 5',
      title: 'Shop Master Switch & Settings',
      hindi: 'Emergency shop pause switch.',
      desc: 'Temporarily pause incoming customer QR orders during peak rush or closing hours using the master shop switch.',
      image: tutorialSettings,
      badge: 'Master Control'
    }
  ];

  const steps = activeTab === 'customer' ? customerSteps : ownerSteps;

  return (
    <div className="bg-white min-h-screen pt-12 pb-24 text-left">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* Page Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4 mb-14">
          <span className="inline-flex items-center space-x-2 bg-primary/10 border border-primary/20 text-primary px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest">
            <QrCode className="w-3.5 h-3.5" />
            <span>Visual Step-By-Step Guides</span>
          </span>
          <h1 className="text-4xl md:text-6xl font-black text-secondary leading-tight">
            How BillJi System Works
          </h1>
          <p className="text-slate-600 text-lg md:text-xl">
            See how easy it is for customers to scan and order, and for shop owners to manage kitchen tokens and sales.
          </p>

          {/* Customer / Owner Tab Buttons */}
          <div className="pt-6 flex justify-center">
            <div className="bg-slate-100 p-1.5 rounded-full border border-slate-200 flex items-center space-x-2">
              <button
                onClick={() => setActiveTab('customer')}
                className={`flex items-center space-x-2 px-6 py-3 rounded-full font-bold text-sm transition-all duration-300 ${
                  activeTab === 'customer'
                    ? 'bg-primary text-white shadow-lg shadow-primary/20 scale-[1.02]'
                    : 'text-slate-600 hover:text-secondary'
                }`}
              >
                <UserCheck className="w-4 h-4" />
                <span>Customer Ordering Guide</span>
              </button>

              <button
                onClick={() => setActiveTab('owner')}
                className={`flex items-center space-x-2 px-6 py-3 rounded-full font-bold text-sm transition-all duration-300 ${
                  activeTab === 'owner'
                    ? 'bg-secondary text-white shadow-lg shadow-secondary/20 scale-[1.02]'
                    : 'text-slate-600 hover:text-secondary'
                }`}
              >
                <Store className="w-4 h-4" />
                <span>Shop Owner Master Guide</span>
              </button>
            </div>
          </div>
        </div>

        {/* Visual Screenshot Step Cards */}
        <div className="space-y-16">
          {steps.map((item, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className={`bg-slate-50 rounded-3xl p-6 md:p-10 border border-slate-200/80 shadow-lg grid grid-cols-1 lg:grid-cols-12 gap-8 items-center ${
                idx % 2 === 1 ? 'lg:flex-row-reverse' : ''
              }`}
            >
              {/* Image Preview (Uniform Mobile Frame with Centered Padded Image) */}
              <div className={`lg:col-span-6 flex justify-center ${idx % 2 === 1 ? 'order-1 lg:order-2' : ''}`}>
                <div className="relative bg-black rounded-[2.6rem] sm:rounded-[3rem] shadow-2xl border-[5px] sm:border-[6px] border-black ring-1 ring-slate-700/60 w-[240px] sm:w-[270px] h-[521px] sm:h-[586px] overflow-hidden group shrink-0">
                  {item.image === tutorialQr ? (
                    /* Step 1 — QR code with live scanning animation */
                    <div className="absolute inset-0 bg-slate-900 flex items-center justify-center p-6">
                      <div className="relative w-[80%] aspect-square rounded-2xl overflow-hidden bg-white shadow-xl">
                        <img src={item.image} alt={item.title} className="w-full h-full object-contain object-center p-2" />
                        {/* Moving scan laser */}
                        <motion.div
                          aria-hidden="true"
                          initial={{ top: '4%' }}
                          animate={{ top: ['4%', '92%', '4%'] }}
                          transition={{ duration: 2.6, repeat: Infinity, ease: 'easeInOut' }}
                          className="absolute left-1.5 right-1.5 h-[3px] rounded-full bg-primary shadow-[0_0_14px_4px_rgba(254,112,26,0.85)]"
                        />
                        {/* Scanner corner brackets */}
                        <span className="absolute top-1.5 left-1.5 w-5 h-5 border-t-2 border-l-2 border-primary rounded-tl-lg" />
                        <span className="absolute top-1.5 right-1.5 w-5 h-5 border-t-2 border-r-2 border-primary rounded-tr-lg" />
                        <span className="absolute bottom-1.5 left-1.5 w-5 h-5 border-b-2 border-l-2 border-primary rounded-bl-lg" />
                        <span className="absolute bottom-1.5 right-1.5 w-5 h-5 border-b-2 border-r-2 border-primary rounded-br-lg" />
                      </div>
                    </div>
                  ) : (
                    /* Full app screenshot — object-contain so the entire image is always visible (never cropped) */
                    <img
                      src={item.image}
                      alt={item.title}
                      className="absolute inset-0 w-full h-full object-contain object-top group-hover:scale-[1.02] transition-transform duration-300"
                    />
                  )}

                  {/* iPhone Dynamic Island */}
                  <div className="absolute top-2.5 left-1/2 -translate-x-1/2 w-[64px] h-[20px] bg-black rounded-full z-30 shadow-md" />
                  {/* iPhone Home Indicator */}
                  <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-24 h-1 bg-white/70 rounded-full z-30" />
                </div>
              </div>

              {/* Step Details Text */}
              <div className={`lg:col-span-6 space-y-4 text-left ${idx % 2 === 1 ? 'order-2 lg:order-1' : ''}`}>
                <div className="flex flex-wrap items-center gap-2">
                  <div className="inline-flex items-center space-x-2 text-primary font-bold text-xs uppercase tracking-wider bg-primary/10 px-3.5 py-1 rounded-full">
                    <span>{item.step}</span>
                  </div>
                  <span className="inline-flex items-center bg-secondary text-white text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-wider shadow-sm ring-1 ring-white/10">
                    {item.badge}
                  </span>
                </div>

                <h3 className="text-2xl md:text-3xl font-black text-secondary">
                  {item.title}
                </h3>
                <p className="text-sm font-semibold text-primary italic">
                  "{item.hindi}"
                </p>

                <p className="text-slate-600 text-base leading-relaxed">
                  {item.desc}
                </p>

                <div className="pt-2 flex items-center space-x-2 text-xs font-bold text-secondary">
                  <CheckCircle2 className="w-4 h-4 text-primary" />
                  <span>Verified BillJi Workflow</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Bottom CTA Banner */}
        <div className="mt-20 bg-secondary text-white p-10 md:p-14 rounded-3xl shadow-2xl text-center max-w-4xl mx-auto space-y-6">
          <h3 className="text-3xl font-black">Ready to Setup BillJi at Your Counter?</h3>
          <p className="text-slate-400 text-base max-w-xl mx-auto">
            Get your custom shop QR stand and master dashboard ready in less than 24 hours with full BillJi setup assistance.
          </p>
          <button
            onClick={onOpenDemoModal}
            className="bg-primary hover:bg-primary-dark text-white font-bold px-8 py-3.5 rounded-full shadow-lg hover:shadow-primary/30 transition-all hover:scale-105 inline-flex items-center space-x-2"
          >
            <span>Request Free Demo & QR Kit</span>
            <ArrowRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
