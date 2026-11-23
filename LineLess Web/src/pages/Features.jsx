import { useState } from 'react';
import { motion } from 'framer-motion';
import {
  QrCode,
  Store,
  Grid3X3,
  ChefHat,
  BarChart3,
  Lock,
  Cloud,
  RefreshCw,
  ArrowRight,
  CheckCircle2,
  ShieldCheck,
  Sparkles,
  Search,
  Eye,
  X,
  CreditCard,
  UtensilsCrossed,
  BellRing
} from 'lucide-react';
import WorkflowSection from '../components/WorkflowSection';

export default function Features({ onOpenDemoModal }) {
  // Feature 1: POS Interactive State Simulation
  const [posCart, setPosCart] = useState({
    'Margherita Pizza': { qty: 1, price: 199 },
  });

  const updatePosQty = (name, price, delta) => {
    const current = posCart[name] ? posCart[name].qty : 0;
    const newQty = Math.max(0, current + delta);
    const newCart = { ...posCart };
    if (newQty === 0) {
      delete newCart[name];
    } else {
      newCart[name] = { qty: newQty, price };
    }
    setPosCart(newCart);
  };

  const calculatePosTotal = () => {
    return Object.values(posCart).reduce((acc, item) => acc + item.qty * item.price, 0);
  };

  // Feature 4: PIN Verification Interactive State
  const [enteredPin, setEnteredPin] = useState(['1', '2', '3', '4', '', '']);
  const [pinVerified, setPinVerified] = useState(false);

  const handleKeypadPress = (val) => {
    if (val === 'backspace') {
      const idx = enteredPin.findLastIndex(d => d !== '');
      if (idx !== -1) {
        const next = [...enteredPin];
        next[idx] = '';
        setEnteredPin(next);
        setPinVerified(false);
      }
    } else if (val === 'clear') {
      setEnteredPin(['', '', '', '', '', '']);
      setPinVerified(false);
    } else {
      const idx = enteredPin.findIndex(d => d === '');
      if (idx !== -1) {
        const next = [...enteredPin];
        next[idx] = val;
        setEnteredPin(next);
        if (idx === 5) setPinVerified(true);
      }
    }
  };


  // Why BillJi Feature Grid
  const whyFeatures = [
    { icon: QrCode, title: 'QR Menu', tag: 'Digital Ordering', desc: 'No customer app required. Scans load full menu in under 2 seconds.' },
    { icon: Store, title: 'Smart POS', tag: 'Offline Billing', desc: 'One-click GO POS button on dashboard for fast walk-in customer checkout.' },
    { icon: Grid3X3, title: 'Table Management', tag: 'Floor Layout', desc: 'Live table occupancy, running bills, and floor layout sync.' },
    { icon: ChefHat, title: 'Kitchen Display (KDS)', tag: 'Grouped Orders', desc: 'Automatically groups identical dishes across tokens to cook 3x faster.' },
    { icon: BarChart3, title: 'Sales Analytics', tag: 'Business Insights', desc: 'Track daily revenue, token counts, and category performance.' },
    { icon: Lock, title: 'PIN Security', tag: 'Secure Reports', desc: 'Restricts reports and sales data behind a master 6-digit owner PIN.' },
    { icon: Cloud, title: 'Cloud Dashboard', tag: 'Access Anywhere', desc: 'Monitor your restaurant remotely from mobile, tablet, or PC.' },
    { icon: RefreshCw, title: 'Realtime Sync', tag: 'Instant Updates', desc: 'Menu availability and item toggles update instantly across all screens.' }
  ];

  return (
    <div className="bg-white min-h-screen pt-12 pb-24 text-left">
      {/* Page Header */}
      <div className="max-w-7xl mx-auto px-6 md:px-12 text-center relative mb-16">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[500px] h-[300px] bg-primary/10 rounded-full blur-3xl -z-10" />

        <span className="inline-flex items-center space-x-2 bg-primary/10 border border-primary/20 text-primary px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest mb-4">
          <Sparkles className="w-3.5 h-3.5 fill-primary" />
          <span>Complete Platform Features</span>
        </span>
        <h1 className="text-4xl md:text-6xl font-black text-secondary leading-tight">
          Everything Your Restaurant Needs To Run Fast
        </h1>
        <p className="text-slate-600 text-lg md:text-xl max-w-3xl mx-auto mt-4">
          Explore our Smart POS System, Table Floor Management, Kitchen Display System (KDS), and PIN Protected Business Security.
        </p>
      </div>

      {/* Feature 1 – Smart POS System */}
      <section id="smart-pos" className="py-20 bg-slate-50/70 border-t border-b border-slate-100 scroll-mt-28">
        <div className="max-w-7xl mx-auto px-6 md:px-12">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Description */}
            <div className="lg:col-span-5 space-y-6">
              <span className="text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-4 py-1.5 rounded-full">
                Feature 1 – Smart POS System
              </span>

              <h2 className="text-3xl md:text-5xl font-black text-secondary leading-tight">
                Smart POS for Walk-in Customers
              </h2>

              <p className="text-slate-600 text-base leading-relaxed">
                Restaurant owners can generate a secure POS link directly from the Settings page. Once enabled, a <span className="font-bold text-secondary">GO POS</span> button automatically appears on the top-right corner of the dashboard. When clicked, it opens the restaurant’s own POS interface where staff can instantly take offline customer orders.
              </p>

              <div className="bg-white p-4 rounded-2xl border border-slate-200 space-y-2 text-sm text-slate-700 shadow-sm">
                <div className="flex items-center space-x-2 text-primary font-bold">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Fast Counter Billing Workflow</span>
                </div>
                <p className="text-xs text-slate-500">
                  Customer Name and Mobile Number remain optional for lightning-fast bill checkout during peak rush hours.
                </p>
              </div>

              {/* Workflow Flow Pills */}
              <div className="flex flex-wrap gap-2 pt-2">
                <span className="bg-slate-200/60 text-slate-700 text-xs font-semibold px-3 py-1.5 rounded-xl flex items-center space-x-1">
                  <span>Settings</span>
                  <ArrowRight className="w-3 h-3 text-slate-400" />
                </span>
                <span className="bg-primary/10 text-primary text-xs font-bold px-3 py-1.5 rounded-xl flex items-center space-x-1">
                  <span>GO POS Button</span>
                  <ArrowRight className="w-3 h-3 text-primary" />
                </span>
                <span className="bg-slate-900 text-white text-xs font-bold px-3 py-1.5 rounded-xl">
                  Instant Billing
                </span>
              </div>
            </div>

            {/* Right Interactive POS Device Mockup */}
            <div className="lg:col-span-7 flex justify-center">
              <div className="w-full max-w-md bg-white rounded-[2.5rem] p-5 shadow-2xl border-4 border-slate-900 relative overflow-hidden pointer-events-none select-none">
                <div className="w-32 h-4 bg-slate-900 rounded-b-2xl mx-auto mb-4" />

                <div className="flex justify-between items-center pb-3 border-b border-slate-100">
                  <span className="text-base font-black text-secondary">POS System</span>
                  <span className="text-xs font-bold text-primary bg-primary/10 px-2.5 py-1 rounded-full">
                    Cloud Terminal
                  </span>
                </div>

                <div className="my-3 relative">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    readOnly
                    placeholder="Search food items..."
                    className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs"
                  />
                </div>

                <div className="grid grid-cols-12 gap-3 min-h-[320px]">
                  <div className="col-span-4 bg-slate-50 p-2 rounded-2xl border border-slate-100 space-y-2 text-xs">
                    <div className="bg-primary text-white p-2 rounded-xl font-bold flex justify-between">
                      <span>All</span>
                      <span className="opacity-80">13</span>
                    </div>
                    <div className="p-2 rounded-xl hover:bg-slate-200 text-slate-700 font-medium cursor-pointer">
                      Pizza <span className="text-[10px] text-slate-400">(6)</span>
                    </div>
                    <div className="p-2 rounded-xl hover:bg-slate-200 text-slate-700 font-medium cursor-pointer">
                      Burgers <span className="text-[10px] text-slate-400">(3)</span>
                    </div>
                    <div className="p-2 rounded-xl hover:bg-slate-200 text-slate-700 font-medium cursor-pointer">
                      Beverages <span className="text-[10px] text-slate-400">(3)</span>
                    </div>
                  </div>

                  <div className="col-span-8 space-y-2 max-h-[320px] overflow-y-auto pr-1">
                    {[
                      { name: 'Margherita Pizza', price: 199, unit: 'PER PCS' },
                      { name: 'Veg Cheese Burger', price: 120, unit: 'PER NOS' },
                      { name: 'Cappuccino', price: 110, unit: 'PER CUP' },
                      { name: 'Cold Coffee', price: 130, unit: 'PER GLASS' },
                      { name: 'French Fries', price: 90, unit: 'PER NOS' },
                    ].map((item, idx) => {
                      const qty = posCart[item.name]?.qty || 0;
                      return (
                        <div key={idx} className="bg-white p-2.5 rounded-xl border border-slate-200 flex justify-between items-center shadow-sm">
                          <div>
                            <div className="text-xs font-bold text-secondary">{item.name}</div>
                            <div className="text-[11px] font-extrabold text-green-600">₹{item.price}.00 <span className="text-[9px] text-slate-400 font-normal">{item.unit}</span></div>
                          </div>
                          <div className="flex items-center space-x-1">
                            {qty > 0 && (
                              <button
                                onClick={() => updatePosQty(item.name, item.price, -1)}
                                className="w-6 h-6 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 flex items-center justify-center font-bold"
                              >
                                -
                              </button>
                            )}
                            {qty > 0 && <span className="text-xs font-bold px-1">{qty}</span>}
                            <button
                              onClick={() => updatePosQty(item.name, item.price, 1)}
                              className="bg-amber-500 hover:bg-amber-600 text-white px-2.5 py-1 rounded-lg text-xs font-bold"
                            >
                              {qty > 0 ? '+' : 'Add'}
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-slate-100 flex justify-between items-center bg-slate-50 p-3 rounded-2xl">
                  <div>
                    <span className="text-[10px] text-slate-400 font-bold uppercase block">Total Amount</span>
                    <span className="text-lg font-black text-secondary">₹ {calculatePosTotal()}.00</span>
                  </div>
                  <button
                    onClick={() => alert(`Order Placed Successfully! Total: ₹${calculatePosTotal()}`)}
                    className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-5 py-2.5 rounded-xl text-xs shadow-md flex items-center space-x-1.5"
                  >
                    <span>Place Order</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature 2 – Smart Table Management */}
      <section id="table-layout" className="py-20 bg-white scroll-mt-28">
        <div className="max-w-7xl mx-auto px-6 md:px-12">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Device Mockup */}
            <div className="lg:col-span-7 order-2 lg:order-1 flex justify-center">
              <div className="w-full max-w-md bg-slate-50 rounded-[2.5rem] p-5 shadow-2xl border-4 border-slate-900 relative text-left pointer-events-none select-none">
                <div className="flex justify-between items-center pb-4">
                  <div>
                    <span className="text-xs text-slate-400 font-medium">Welcome Back,</span>
                    <h3 className="text-lg font-black text-secondary">Brew Haven Café</h3>
                  </div>
                  <button className="bg-primary/10 border border-primary/30 text-primary font-bold px-3 py-1.5 rounded-xl text-xs flex items-center space-x-1">
                    <Store className="w-3.5 h-3.5" />
                    <span>GO POS</span>
                  </button>
                </div>

                <div className="grid grid-cols-3 gap-2.5 mb-5">
                  <div className="bg-white p-3 rounded-2xl border border-slate-200">
                    <span className="text-[10px] text-slate-400 font-bold uppercase block">Total Tables</span>
                    <span className="text-lg font-black text-secondary">5</span>
                  </div>
                  <div className="bg-white p-3 rounded-2xl border border-slate-200">
                    <span className="text-[10px] text-slate-400 font-bold uppercase block">Occupied</span>
                    <span className="text-lg font-black text-amber-600">1</span>
                  </div>
                  <div className="bg-white p-3 rounded-2xl border border-slate-200">
                    <span className="text-[10px] text-slate-400 font-bold uppercase block">Live Amount</span>
                    <span className="text-lg font-black text-emerald-600">₹40</span>
                  </div>
                </div>

                <div className="bg-white p-4 rounded-2xl border border-slate-200">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-xs font-bold text-secondary uppercase">Floor Layout</span>
                    <span className="text-xs font-semibold text-primary">View All</span>
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="bg-emerald-50 border-2 border-emerald-500 p-3 rounded-2xl cursor-pointer relative shadow-[0_0_15px_rgba(16,185,129,0.25)] animate-pulse">
                      <div className="flex justify-between text-emerald-600 mb-1">
                        <Grid3X3 className="w-4 h-4" />
                        <Eye className="w-3.5 h-3.5" />
                      </div>
                      <span className="text-xs font-bold text-emerald-700 block">Table 1</span>
                      <span className="text-[10px] font-bold text-emerald-600 block">Occupied</span>
                      <span className="text-xs font-black text-secondary block mt-1">₹40</span>
                    </div>

                    {[2, 3, 4, 5].map((tbl) => (
                      <div
                        key={tbl}
                        className="bg-slate-50 border border-slate-200 p-3 rounded-2xl cursor-pointer hover:border-slate-400 transition-all text-slate-400"
                      >
                        <Grid3X3 className="w-4 h-4 mb-1" />
                        <span className="text-xs font-bold text-slate-700 block">Table {tbl}</span>
                        <span className="text-[10px]">Empty</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Right Description */}
            <div className="lg:col-span-5 order-1 lg:order-2 space-y-6">
              <span className="text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-4 py-1.5 rounded-full">
                Feature 2 – Smart Table Management
              </span>

              <h2 className="text-3xl md:text-5xl font-black text-secondary leading-tight">
                Manage Every Table Digitally
              </h2>

              <p className="text-slate-600 text-base leading-relaxed">
                Restaurant owners can create tables, monitor occupancy, assign orders, continue running orders, and view the entire restaurant floor layout in real time.
              </p>

              <ul className="space-y-3">
                {[
                  'Live Table Occupancy Monitoring',
                  'Instant Running Order Tab Assignment',
                  'Real-time Floor Layout & Revenue Totals',
                  'Dine-in Customer Bill Details Preview'
                ].map((item, i) => (
                  <li key={i} className="flex items-center space-x-3 text-slate-700 font-medium">
                    <CheckCircle2 className="w-5 h-5 text-primary shrink-0" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Feature 3 – Kitchen Display System (KDS) */}
      <section id="kds" className="py-20 bg-slate-900 text-white scroll-mt-28">
        <div className="max-w-7xl mx-auto px-6 md:px-12">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Description */}
            <div className="lg:col-span-5 space-y-6">
              <span className="text-xs font-bold uppercase tracking-widest text-primary-light bg-primary/20 px-4 py-1.5 rounded-full border border-primary/30">
                Feature 3 – Smart KDS System
              </span>

              <h2 className="text-3xl md:text-5xl font-black text-white leading-tight">
                Smart Kitchen Display System (KDS)
              </h2>

              <p className="text-slate-300 text-base leading-relaxed">
                Restaurants often receive multiple orders containing the same dishes. Instead of showing duplicate tickets, BillJi automatically groups similar items together.
              </p>

              <div className="bg-slate-800 p-5 rounded-2xl border border-slate-700 space-y-2">
                <div className="text-xs text-primary-light font-bold uppercase tracking-wider">Grouped Order Example</div>
                <div className="text-lg font-bold text-white">Margherita Pizza — Total Quantity: 4 NOS</div>
                <div className="text-xs text-slate-400 space-y-1 pt-1">
                  <div>• Token #2 (Qty: 1) — Walk-in Customer</div>
                  <div>• Token #3 (Qty: 1) — Customer: Rahul</div>
                  <div>• Token #3 (Qty: 1) — Customer: Rahul</div>
                  <div>• Token #5 (Qty: 1) — Walk-in Customer</div>
                </div>
              </div>

              <div className="flex items-center space-x-2 text-xs font-bold text-slate-400 pt-2">
                <span className="text-white bg-slate-800 px-3 py-1.5 rounded-xl">Orders</span>
                <ArrowRight className="w-3.5 h-3.5 text-primary" />
                <span className="text-white bg-slate-800 px-3 py-1.5 rounded-xl">Grouped Together</span>
                <ArrowRight className="w-3.5 h-3.5 text-primary" />
                <span className="text-primary-light bg-primary/20 border border-primary/30 px-3 py-1.5 rounded-xl">Prepared 3x Faster</span>
              </div>
            </div>

            {/* Right Tablet Mockup */}
            <div className="lg:col-span-7 flex justify-center">
              <div className="w-full max-w-lg bg-slate-800 rounded-3xl p-5 shadow-2xl border border-slate-700 relative text-left pointer-events-none select-none">
                <div className="grid grid-cols-2 gap-3 opacity-40 mb-3">
                  <div className="bg-slate-700 p-3 rounded-2xl">
                    <span className="text-xs font-bold text-white">Garlic Bread</span>
                    <div className="text-sm font-black text-primary-light mt-1">1 Plate</div>
                  </div>
                  <div className="bg-slate-700 p-3 rounded-2xl">
                    <span className="text-xs font-bold text-white">Veg Pasta</span>
                    <div className="text-sm font-black text-primary-light mt-1">1 Plate</div>
                  </div>
                </div>

                <div className="bg-white text-secondary rounded-2xl p-5 shadow-2xl border border-slate-100 relative">
                  <div className="flex justify-between items-start pb-3 border-b border-slate-100">
                    <div>
                      <h4 className="text-xl font-black text-secondary">Margherita Pizza</h4>
                      <span className="text-xs font-bold text-primary">Total Quantity: 4 NOS</span>
                    </div>
                    <X className="w-5 h-5 text-slate-400 cursor-pointer" />
                  </div>

                  <div className="mt-3">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-2">
                      Orders Containing This Item
                    </span>

                    <div className="space-y-2 text-xs">
                      <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 flex justify-between items-center">
                        <div className="flex items-center space-x-2">
                          <span className="bg-blue-600 text-white font-bold text-[10px] px-2 py-0.5 rounded-md">TOKEN #2</span>
                          <span className="font-bold">Qty: 1</span>
                        </div>
                        <span className="text-slate-400 text-[10px]">03:06 PM • Walk-in Customer</span>
                      </div>

                      <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 flex justify-between items-center">
                        <div className="flex items-center space-x-2">
                          <span className="bg-blue-600 text-white font-bold text-[10px] px-2 py-0.5 rounded-md">TOKEN #3</span>
                          <span className="font-bold">Qty: 1</span>
                        </div>
                        <span className="text-slate-400 text-[10px]">03:06 PM • Customer: Rahul</span>
                      </div>

                      <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 flex justify-between items-center">
                        <div className="flex items-center space-x-2">
                          <span className="bg-blue-600 text-white font-bold text-[10px] px-2 py-0.5 rounded-md">TOKEN #3</span>
                          <span className="font-bold">Qty: 1</span>
                        </div>
                        <span className="text-slate-400 text-[10px]">03:06 PM • Customer: Rahul</span>
                      </div>

                      <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 flex justify-between items-center">
                        <div className="flex items-center space-x-2">
                          <span className="bg-blue-600 text-white font-bold text-[10px] px-2 py-0.5 rounded-md">TOKEN #5</span>
                          <span className="font-bold">Qty: 1</span>
                        </div>
                        <span className="text-slate-400 text-[10px]">03:07 PM • Walk-in Customer</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature 4 – Reports Security */}
      <section id="pin-security" className="py-20 bg-white scroll-mt-28">
        <div className="max-w-7xl mx-auto px-6 md:px-12">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Mobile Device Mockup */}
            <div className="lg:col-span-6 order-2 lg:order-1 flex justify-center">
              <div className="w-full max-w-sm bg-slate-50 rounded-[2.5rem] p-6 shadow-2xl border-4 border-slate-900 relative text-center">
                <div className="w-14 h-14 bg-primary/10 text-primary rounded-2xl flex items-center justify-center mx-auto mb-3">
                  <Lock className="w-7 h-7" />
                </div>
                <h3 className="text-xl font-black text-secondary">Security Verification</h3>
                <p className="text-xs text-slate-500 mt-1 mb-5">
                  Access to reports is restricted. Please enter your security PIN.
                </p>

                <div className="flex justify-center space-x-2 mb-6">
                  {enteredPin.map((digit, i) => (
                    <div
                      key={i}
                      className={`w-9 h-11 rounded-xl border-2 flex items-center justify-center text-lg font-bold ${digit
                          ? 'border-primary bg-primary/10 text-secondary'
                          : 'border-slate-200 bg-white'
                        }`}
                    >
                      {digit ? '•' : ''}
                    </div>
                  ))}
                </div>

                <button
                  onClick={() => alert(pinVerified ? 'Security Verified!' : 'Please enter 6-digit PIN')}
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-2xl text-xs uppercase tracking-wider shadow-md mb-6"
                >
                  Verify PIN
                </button>

                <div className="bg-slate-200/60 p-3 rounded-2xl grid grid-cols-3 gap-2 text-sm font-bold text-slate-700">
                  {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'].map((k) => (
                    <button
                      key={k}
                      onClick={() => {
                        if (k === '⌫') handleKeypadPress('backspace');
                        else if (k === 'C') handleKeypadPress('clear');
                        else handleKeypadPress(k);
                      }}
                      className="bg-white py-2.5 rounded-xl hover:bg-slate-100 active:scale-95 transition-all shadow-sm"
                    >
                      {k}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Right Description */}
            <div className="lg:col-span-6 order-1 lg:order-2 space-y-6">
              <span className="text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-4 py-1.5 rounded-full">
                Feature 4 – Business Data Security
              </span>

              <h2 className="text-3xl md:text-5xl font-black text-secondary leading-tight">
                Protect Your Business Reports
              </h2>

              <p className="text-slate-600 text-base leading-relaxed">
                Many restaurants keep the Kitchen Display System running inside the kitchen all day. To prevent unauthorized staff from accessing business revenue data, BillJi protects Analytics and Reports using a secure 6-digit PIN.
              </p>

              <div className="grid grid-cols-2 gap-4 pt-2">
                {[
                  { title: 'PIN Protected Reports', desc: 'Restricts revenue views' },
                  { title: 'Owner-Only Access', desc: 'Master password override' },
                  { title: 'Secure Analytics', desc: 'Encrypted daily logs' },
                  { title: 'Sales Protection', desc: 'Prevents kitchen peek' }
                ].map((f, idx) => (
                  <div key={idx} className="bg-slate-50 p-4 rounded-2xl border border-slate-100">
                    <div className="flex items-center space-x-2 text-primary font-bold text-sm mb-1">
                      <ShieldCheck className="w-4 h-4" />
                      <span>{f.title}</span>
                    </div>
                    <span className="text-xs text-slate-500">{f.desc}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Unified Pipeline */}
      <WorkflowSection />

      {/* Why BillJi Feature Grid */}
      <section className="py-20 bg-slate-50/70 border-t border-slate-100">
        <div className="max-w-7xl mx-auto px-6 md:px-12 text-center">
          <span className="text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-4 py-1.5 rounded-full">
            Complete Capabilities
          </span>
          <h2 className="text-3xl md:text-5xl font-black text-secondary mt-3 mb-16">
            Why Restaurants Run On Bill<span className="text-primary">Ji</span>
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 text-left">
            {whyFeatures.map((feat, idx) => (
              <div
                key={idx}
                className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm hover:shadow-xl transition-all duration-300 hover:-translate-y-1.5 flex flex-col justify-between"
              >
                <div>
                  <div className="flex justify-between items-center mb-4">
                    <div className="w-10 h-10 bg-primary/10 text-primary rounded-xl flex items-center justify-center">
                      <feat.icon className="w-5 h-5" />
                    </div>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 bg-slate-100 px-2.5 py-1 rounded-full">
                      {feat.tag}
                    </span>
                  </div>
                  <h3 className="text-lg font-bold text-secondary mb-2">{feat.title}</h3>
                  <p className="text-slate-500 text-xs leading-relaxed">{feat.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Bottom CTA Banner */}
      <div className="max-w-4xl mx-auto px-6 text-center pt-10">
        <div className="bg-secondary text-white p-10 md:p-14 rounded-3xl shadow-2xl space-y-6">
          <h2 className="text-3xl md:text-4xl font-black">Ready to Upgrade Your Restaurant Counter?</h2>
          <p className="text-slate-400 text-base max-w-xl mx-auto">
            Get complete access to QR Ordering, Smart POS, Table Layout, Kitchen KDS, and PIN Protected Reports.
          </p>
          <button
            onClick={onOpenDemoModal}
            className="bg-primary hover:bg-primary-dark text-white font-bold px-10 py-4 rounded-full shadow-xl hover:shadow-primary/30 transition-all hover:scale-105 inline-block text-lg"
          >
            Book Free Demo
          </button>
        </div>
      </div>
    </div>
  );
}
