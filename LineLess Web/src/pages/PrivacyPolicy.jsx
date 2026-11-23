import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  ShieldCheck,
  Lock,
  Eye,
  FileText,
  Database,
  QrCode,
  BarChart3,
  Cookie,
  Server,
  CreditCard,
  UserCheck,
  Building2,
  Baby,
  ExternalLink,
  RefreshCw,
  Mail,
  Phone,
  MapPin,
  ChevronRight,
  ArrowUp,
  Sparkles,
  CheckCircle2,
  HelpCircle,
  Clock
} from 'lucide-react';
import { Link } from 'react-router-dom';

const sections = [
  { id: 'introduction', label: '1. Introduction', icon: ShieldCheck },
  { id: 'information-collected', label: '2. Information We Collect', icon: Database },
  { id: 'how-we-use', label: '3. How We Use Information', icon: Eye },
  { id: 'pos-order-data', label: '4. POS and Order Data', icon: FileText },
  { id: 'qr-ordering', label: '5. QR / Ordering Features', icon: QrCode },
  { id: 'analytics', label: '6. Analytics', icon: BarChart3 },
  { id: 'cookies', label: '7. Cookies & Local Storage', icon: Cookie },
  { id: 'data-security', label: '8. Data Security', icon: Lock },
  { id: 'data-retention', label: '9. Data Retention', icon: Clock },
  { id: 'data-sharing', label: '10. Data Sharing', icon: Server },
  { id: 'payment-info', label: '11. Payment Information', icon: CreditCard },
  { id: 'user-rights', label: '12. User Rights', icon: UserCheck },
  { id: 'business-responsibilities', label: '13. Business Customer Responsibilities', icon: Building2 },
  { id: 'children-privacy', label: '14. Children\'s Privacy', icon: Baby },
  { id: 'third-party-services', label: '15. Third-Party Services', icon: ExternalLink },
  { id: 'policy-changes', label: '16. Changes to This Policy', icon: RefreshCw },
  { id: 'contact-us', label: '17. Contact Us', icon: Mail },
];

export default function PrivacyPolicy({ onOpenDemoModal }) {
  const [activeSection, setActiveSection] = useState('introduction');
  const [showScrollTop, setShowScrollTop] = useState(false);

  useEffect(() => {
    // SEO Meta updates
    document.title = 'Privacy Policy | BillJi';

    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) {
      metaDescription.setAttribute(
        'content',
        'Read the BillJi Privacy Policy to understand how we collect, use, protect and manage information when you use our services.'
      );
    }
  }, []);

  useEffect(() => {
    const handleScroll = () => {
      setShowScrollTop(window.scrollY > 400);

      // Highlight active section based on scroll position
      const scrollPosition = window.scrollY + 200;
      for (const section of sections) {
        const el = document.getElementById(section.id);
        if (el) {
          const top = el.offsetTop;
          const height = el.offsetHeight;
          if (scrollPosition >= top && scrollPosition < top + height) {
            setActiveSection(section.id);
            break;
          }
        }
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const scrollToSection = (id) => {
    setActiveSection(id);
    const element = document.getElementById(id);
    if (element) {
      const yOffset = -110;
      const y = element.getBoundingClientRect().top + window.pageYOffset + yOffset;
      window.scrollTo({ top: y, behavior: 'smooth' });
    }
  };

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <div className="bg-slate-50/50 min-h-screen pt-8 pb-24 text-left">
      {/* Background Ambient Glow */}
      <div className="max-w-7xl mx-auto px-6 md:px-12 relative">
        <div className="absolute top-0 right-1/4 w-[600px] h-[350px] bg-primary/10 rounded-full blur-3xl -z-10 pointer-events-none" />

        {/* Hero Header */}
        <div className="max-w-4xl mx-auto text-center pt-6 pb-12">
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center space-x-2 bg-primary/10 border border-primary/20 text-primary px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest mb-4"
          >
            <ShieldCheck className="w-4 h-4 text-primary" />
            <span>Trust & Transparency</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-4xl md:text-5xl lg:text-6xl font-black text-secondary tracking-tight mb-4"
          >
            Privacy Policy
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="text-lg md:text-xl text-slate-600 max-w-2xl mx-auto leading-relaxed mb-6 text-center"
          >
            <span className="block">Your privacy matters to us.</span>
            <span className="block mt-2">Learn how BillJi collects, uses, protects and manages your information.</span>
          </motion.p>

          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="inline-flex items-center space-x-3 bg-white px-5 py-2 rounded-full border border-slate-200 shadow-sm text-xs font-semibold text-slate-500"
          >
            <span className="flex h-2 w-2 rounded-full bg-primary animate-pulse" />
            <span>Last Updated: August 19, 2026</span>
            <span className="text-slate-300">•</span>
            <span>Version 1.2</span>
          </motion.div>
        </div>

        {/* Mobile Quick Dropdown Navigation */}
        <div className="lg:hidden mb-8 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
          <label htmlFor="mobile-toc" className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">
            Jump to Section:
          </label>
          <select
            id="mobile-toc"
            value={activeSection}
            onChange={(e) => scrollToSection(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 text-secondary text-sm font-semibold rounded-xl p-3 focus:outline-none focus:ring-2 focus:ring-primary"
          >
            {sections.map((sec) => (
              <option key={sec.id} value={sec.id}>
                {sec.label}
              </option>
            ))}
          </select>
        </div>

        {/* Layout Grid: Sticky Sidebar + Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
          {/* Desktop Sticky Table of Contents Sidebar */}
          <aside className="hidden lg:block lg:col-span-4 sticky top-28 space-y-6">
            <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-lg shadow-slate-100">
              <h3 className="text-xs font-black uppercase tracking-wider text-slate-400 mb-4 px-2">
                Table of Contents
              </h3>
              <nav className="space-y-1 max-h-[calc(100vh-220px)] overflow-y-auto pr-1">
                {sections.map((sec) => {
                  const Icon = sec.icon;
                  const isActive = activeSection === sec.id;
                  return (
                    <button
                      key={sec.id}
                      onClick={() => scrollToSection(sec.id)}
                      className={`w-full flex items-center justify-between text-xs font-semibold px-3.5 py-2.5 rounded-xl transition-all duration-200 text-left ${
                        isActive
                          ? 'bg-primary text-white shadow-md shadow-primary/20 font-bold scale-[1.02]'
                          : 'text-slate-600 hover:bg-slate-100 hover:text-secondary'
                      }`}
                    >
                      <div className="flex items-center space-x-2.5 truncate">
                        <Icon className={`w-4 h-4 shrink-0 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                        <span className="truncate">{sec.label}</span>
                      </div>
                      <ChevronRight className={`w-3.5 h-3.5 shrink-0 ${isActive ? 'text-white' : 'opacity-0'}`} />
                    </button>
                  );
                })}
              </nav>
            </div>

            {/* Support Callout Box */}
            <div className="bg-gradient-to-br from-secondary to-slate-900 text-white p-6 rounded-3xl shadow-xl relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-primary/20 rounded-full blur-xl pointer-events-none" />
              <HelpCircle className="w-8 h-8 text-primary mb-3" />
              <h4 className="font-bold text-sm mb-1">Have Privacy Questions?</h4>
              <p className="text-slate-300 text-xs leading-relaxed mb-4">
                BillJi privacy team is here to assist you with data requests.
              </p>
              <a
                href="mailto:billji.support@gmail.com"
                className="inline-flex items-center space-x-2 bg-primary hover:bg-primary-dark text-white text-xs font-bold px-4 py-2 rounded-full transition-all"
              >
                <Mail className="w-3.5 h-3.5" />
                <span>Contact Privacy Desk</span>
              </a>
            </div>
          </aside>

          {/* Main Privacy Policy Article Content */}
          <main className="lg:col-span-8 bg-white p-6 md:p-12 rounded-3xl border border-slate-200/80 shadow-lg shadow-slate-100 space-y-14">

            {/* 1. Introduction */}
            <section id="introduction" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <ShieldCheck className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 01</span>
                  <h2 className="text-2xl font-bold text-secondary">1. Introduction</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi respects user privacy and is deeply committed to protecting personal and business information. This Privacy Policy outlines our standards, practices, and procedures regarding data handling across our cloud-based platform, mobile interfaces, QR menus, and Walk-in POS billing operations.
              </p>

              <div className="bg-slate-50 border border-slate-200 rounded-2xl p-5 space-y-3">
                <h4 className="text-sm font-bold text-secondary flex items-center space-x-2">
                  <Sparkles className="w-4 h-4 text-primary" />
                  <span>This Privacy Policy Explains:</span>
                </h4>
                <ul className="grid grid-cols-1 md:grid-cols-2 gap-2.5 text-xs text-slate-700 font-medium">
                  <li className="flex items-center space-x-2">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
                    <span>What information BillJi collects</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
                    <span>Why information is collected</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
                    <span>How collected data is used</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
                    <span>How stored data is protected</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
                    <span>When data may be shared</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
                    <span>How users can manage their data</span>
                  </li>
                </ul>
              </div>
            </section>

            {/* 2. Information We Collect */}
            <section id="information-collected" className="scroll-mt-32 space-y-6">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Database className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 02</span>
                  <h2 className="text-2xl font-bold text-secondary">2. Information We Collect</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi collects information necessary to deliver, optimize, and secure our smart QR ordering and POS system. We collect data depending on how users interact with our platform.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                {/* Personal Information */}
                <div className="bg-slate-50 p-5 rounded-2xl border border-slate-200/80 space-y-2">
                  <h3 className="font-bold text-secondary text-base flex items-center space-x-2">
                    <span className="w-2 h-2 rounded-full bg-primary" />
                    <span>Personal Information</span>
                  </h3>
                  <p className="text-xs text-slate-500 leading-relaxed">
                    Collected during user account creation, demo bookings, or customer support inquiries:
                  </p>
                  <ul className="text-xs text-slate-600 space-y-1.5 list-disc list-inside pt-1">
                    <li>Full Name & Business Contact Name</li>
                    <li>Email address & Mobile Phone Number</li>
                    <li>Business & Shop Contact details</li>
                    <li>Account Login Credentials</li>
                  </ul>
                </div>

                {/* Order Information */}
                <div className="bg-slate-50 p-5 rounded-2xl border border-slate-200/80 space-y-2">
                  <h3 className="font-bold text-secondary text-base flex items-center space-x-2">
                    <span className="w-2 h-2 rounded-full bg-primary" />
                    <span>Order Information</span>
                  </h3>
                  <p className="text-xs text-slate-500 leading-relaxed">
                    Processed when customers place QR orders or merchants create POS orders:
                  </p>
                  <ul className="text-xs text-slate-600 space-y-1.5 list-disc list-inside pt-1">
                    <li>Order details, item line items & quantities</li>
                    <li>Order amounts, taxes & billing totals</li>
                    <li>Order timestamp, status & table number</li>
                    <li>Customer name & phone (where required for pickup)</li>
                  </ul>
                </div>

                {/* Business Information */}
                <div className="bg-slate-50 p-5 rounded-2xl border border-slate-200/80 space-y-2">
                  <h3 className="font-bold text-secondary text-base flex items-center space-x-2">
                    <span className="w-2 h-2 rounded-full bg-primary" />
                    <span>Business Information</span>
                  </h3>
                  <p className="text-xs text-slate-500 leading-relaxed">
                    Information entered by restaurant and shop owners using BillJi OS:
                  </p>
                  <ul className="text-xs text-slate-600 space-y-1.5 list-disc list-inside pt-1">
                    <li>Restaurant/Shop name & address</li>
                    <li>Menu items, pricing & category taxonomy</li>
                    <li>POS configuration & floor table layout</li>
                    <li>Sales summary history & report settings</li>
                  </ul>
                </div>

                {/* Technical Information */}
                <div className="bg-slate-50 p-5 rounded-2xl border border-slate-200/80 space-y-2">
                  <h3 className="font-bold text-secondary text-base flex items-center space-x-2">
                    <span className="w-2 h-2 rounded-full bg-primary" />
                    <span>Technical Information</span>
                  </h3>
                  <p className="text-xs text-slate-500 leading-relaxed">
                    Automatically logged when accessing the BillJi web platform:
                  </p>
                  <ul className="text-xs text-slate-600 space-y-1.5 list-disc list-inside pt-1">
                    <li>IP address & approximate location</li>
                    <li>Browser type, device model & OS version</li>
                    <li>Page view metrics & interaction duration</li>
                    <li>System crash logs & performance diagnostics</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* 3. How We Use Information */}
            <section id="how-we-use" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Eye className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 03</span>
                  <h2 className="text-2xl font-bold text-secondary">3. How We Use Information</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                We use the information we collect strictly for operational, support, security, and product development purposes. BillJi does not sell user data for advertising or unsolicited marketing.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
                {[
                  'Providing BillJi POS and QR Ordering services',
                  'Creating and managing merchant accounts and subscriptions',
                  'Processing live customer orders and KDS ticket routing',
                  'Facilitating Walk-in POS billing and receipt generation',
                  'Delivering responsive customer support and technical assistance',
                  'Monitoring platform performance, stability, and uptime',
                  'Detecting, preventing, and addressing fraud or security vulnerabilities',
                  'Sending vital system notices, updates, and transactional alerts'
                ].map((item, idx) => (
                  <div key={idx} className="flex items-start space-x-3 p-3.5 bg-slate-50 rounded-xl border border-slate-100">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0 mt-0.5" />
                    <span className="text-xs font-semibold text-slate-700">{item}</span>
                  </div>
                ))}
              </div>
            </section>

            {/* 4. POS and Order Data */}
            <section id="pos-order-data" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <FileText className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 04</span>
                  <h2 className="text-2xl font-bold text-secondary">4. POS and Order Data</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                Because BillJi includes a comprehensive Point of Sale (POS) and order management platform, merchant subscribers may input, manage, and process commercial data regarding:
              </p>

              <ul className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs font-medium text-slate-700">
                <li className="p-3 bg-slate-50 rounded-xl border border-slate-200/80">• Restaurant customers and dining guests</li>
                <li className="p-3 bg-slate-50 rounded-xl border border-slate-200/80">• Active and past order transaction records</li>
                <li className="p-3 bg-slate-50 rounded-xl border border-slate-200/80">• Product catalog, inventory & menu pricing</li>
                <li className="p-3 bg-slate-50 rounded-xl border border-slate-200/80">• Table floor layout assignment & KDS history</li>
              </ul>

              <div className="bg-amber-50/80 border border-amber-200 p-4 rounded-2xl text-xs text-amber-900 space-y-1">
                <p className="font-bold">Important Data Ownership Notice:</p>
                <p className="text-amber-800 leading-relaxed">
                  BillJi processes merchant POS and customer order data solely as a technology provider. Business users retain ownership of their customer lists and order history, and are responsible for ensuring all data entered into the system is collected and handled in accordance with applicable laws.
                </p>
              </div>
            </section>

            {/* 5. QR / Ordering Features */}
            <section id="qr-ordering" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <QrCode className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 05</span>
                  <h2 className="text-2xl font-bold text-secondary">5. QR / Ordering Features</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                When end-customers scan BillJi QR codes at restaurant tables or takeaway counters, information submitted through the QR menu interface is processed exclusively for:
              </p>

              <div className="space-y-2.5 text-xs text-slate-700">
                <div className="flex items-start space-x-3 p-3 bg-slate-50 rounded-xl border border-slate-100">
                  <span className="w-5 h-5 bg-primary text-white rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">1</span>
                  <p><strong>Identifying Order Location:</strong> Mapping the scanned QR code to the specific table, token number, or outlet counter.</p>
                </div>
                <div className="flex items-start space-x-3 p-3 bg-slate-50 rounded-xl border border-slate-100">
                  <span className="w-5 h-5 bg-primary text-white rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">2</span>
                  <p><strong>Order Dispatching:</strong> Instant routing of selected menu items to the kitchen display screen (KDS) and billing counter.</p>
                </div>
                <div className="flex items-start space-x-3 p-3 bg-slate-50 rounded-xl border border-slate-100">
                  <span className="w-5 h-5 bg-primary text-white rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">3</span>
                  <p><strong>Live Order Tracking:</strong> Providing live status updates to the customer's browser without requiring app downloads.</p>
                </div>
              </div>
            </section>

            {/* 6. Analytics */}
            <section id="analytics" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <BarChart3 className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 06</span>
                  <h2 className="text-2xl font-bold text-secondary">6. Analytics</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi collects anonymized or aggregated usage analytics to evaluate website traffic, optimize feature responsiveness, and diagnose platform performance issues.
              </p>

              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200/80 text-xs text-slate-600 leading-relaxed space-y-2">
                <p><strong>Analytical focus areas include:</strong></p>
                <ul className="list-disc list-inside space-y-1">
                  <li>System load, API response times, and server health</li>
                  <li>Frequency of feature usage (e.g., KDS views, PIN verifications)</li>
                  <li>User navigation patterns and browser compatibility optimization</li>
                </ul>
              </div>
            </section>

            {/* 7. Cookies */}
            <section id="cookies" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Cookie className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 07</span>
                  <h2 className="text-2xl font-bold text-secondary">7. Cookies & Local Storage</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                We use cookies, session tokens, and local browser storage essential to maintain web application security and provide a smooth user experience.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 space-y-1">
                  <h4 className="font-bold text-secondary">Session Cookies</h4>
                  <p className="text-slate-500">Required to keep merchant dashboard sessions authenticated while navigating between screens.</p>
                </div>
                <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 space-y-1">
                  <h4 className="font-bold text-secondary">Preference Cookies</h4>
                  <p className="text-slate-500">Remembers selected preferences such as active branch or KDS filter settings.</p>
                </div>
                <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 space-y-1">
                  <h4 className="font-bold text-secondary">Security Tokens</h4>
                  <p className="text-slate-500">Protects administrative endpoints and PIN-protected reports against CSRF attacks.</p>
                </div>
              </div>
            </section>

            {/* 8. Data Security */}
            <section id="data-security" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Lock className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 08</span>
                  <h2 className="text-2xl font-bold text-secondary">8. Data Security</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi employs technical, administrative, and physical safeguards designed to protect personal and business data against unauthorized access, loss, alteration, or disclosure.
              </p>

              <div className="bg-slate-900 text-white p-6 rounded-2xl space-y-3">
                <h4 className="text-sm font-bold text-primary flex items-center space-x-2">
                  <ShieldCheck className="w-4 h-4 text-primary" />
                  <span>Security Safeguards Implemented:</span>
                </h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs text-slate-300">
                  <div className="flex items-center space-x-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    <span>HTTPS / SSL Encrypted Web Communication</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    <span>Owner-Only 6-Digit PIN Protected Reports</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    <span>Restricted Database Access Controls</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    <span>Continuous System Auditing & Monitoring</span>
                  </div>
                </div>
                <p className="text-[11px] text-slate-400 pt-2 border-t border-slate-800">
                  <em>Note: While we adhere to industry-standard data protection methods, no digital transmission or electronic storage method can be guaranteed to be 100% immune from security risks.</em>
                </p>
              </div>
            </section>

            {/* 9. Data Retention */}
            <section id="data-retention" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Clock className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 09</span>
                  <h2 className="text-2xl font-bold text-secondary">9. Data Retention</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                We retain collected information for as long as active user accounts are maintained, or as reasonably required to fulfil the purposes outlined in this policy.
              </p>

              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200/80 text-xs text-slate-600 space-y-2">
                <p>Data retention duration depends on:</p>
                <ul className="list-disc list-inside space-y-1 text-slate-700">
                  <li>Active merchant subscription status and operational support needs</li>
                  <li>Fulfillment of sales tax accounting and statutory bookkeeping rules</li>
                  <li>Resolution of billing disputes or enforcement of service agreements</li>
                </ul>
              </div>
            </section>

            {/* 10. Data Sharing */}
            <section id="data-sharing" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Server className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 10</span>
                  <h2 className="text-2xl font-bold text-secondary">10. Data Sharing & Third Parties</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi does not sell, rent, or trade personal data to third parties for monetary gain. Information may be shared only with trusted infrastructure providers or when legally mandated.
              </p>

              <div className="space-y-3 text-xs text-slate-700">
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80 space-y-1">
                  <h4 className="font-bold text-secondary">Infrastructure & Cloud Hosting Providers</h4>
                  <p className="text-slate-500">Secure cloud servers utilized to store database records, maintain KDS sockets, and serve web assets.</p>
                </div>
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80 space-y-1">
                  <h4 className="font-bold text-secondary">Communication Providers</h4>
                  <p className="text-slate-500">Email and SMS gateway services utilized strictly for sending order updates, demo confirmations, or OTP verifications.</p>
                </div>
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80 space-y-1">
                  <h4 className="font-bold text-secondary">Legal Compliance</h4>
                  <p className="text-slate-500">When required by applicable court order, law enforcement request, or statutory regulation.</p>
                </div>
              </div>
            </section>

            {/* 11. Payment Information */}
            <section id="payment-info" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <CreditCard className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 11</span>
                  <h2 className="text-2xl font-bold text-secondary">11. Payment Information</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                Where digital payments are enabled on BillJi, transactions are processed via secure third-party payment gateways.
              </p>

              <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-2xl text-xs text-emerald-950 space-y-2">
                <p className="font-bold flex items-center space-x-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" />
                  <span>Secure Payment Processing Guarantee:</span>
                </p>
                <p className="leading-relaxed text-emerald-900">
                  BillJi servers do not store sensitive payment card details, full card numbers, CVV security codes, or banking PINs. Payment gateways manage payment authorization under PCI-DSS compliance standards.
                </p>
              </div>
            </section>

            {/* 12. User Rights */}
            <section id="user-rights" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <UserCheck className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 12</span>
                  <h2 className="text-2xl font-bold text-secondary">12. User Rights</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                Depending on applicable jurisdiction and privacy laws, users and subscribers enjoy specific rights regarding their personal data:
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80">
                  <strong className="text-secondary block mb-1">Right of Access:</strong>
                  <span className="text-slate-500">Request a copy of the personal information BillJi holds about you.</span>
                </div>
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80">
                  <strong className="text-secondary block mb-1">Right to Correction:</strong>
                  <span className="text-slate-500">Request updates or corrections to inaccurate account details.</span>
                </div>
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80">
                  <strong className="text-secondary block mb-1">Right to Deletion:</strong>
                  <span className="text-slate-500">Request account deletion, subject to legitimate accounting retention duties.</span>
                </div>
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/80">
                  <strong className="text-secondary block mb-1">Withdrawal of Consent:</strong>
                  <span className="text-slate-500">Opt out of optional non-essential communications at any time.</span>
                </div>
              </div>
            </section>

            {/* 13. Business Customer Responsibilities */}
            <section id="business-responsibilities" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Building2 className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 13</span>
                  <h2 className="text-2xl font-bold text-secondary">13. Business Customer Responsibilities</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                Restaurant and business owners using BillJi OS serve as independent data controllers for their own customer records.
              </p>

              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200/80 text-xs text-slate-600 space-y-2">
                <p><strong>Merchant Subscribers agree to:</strong></p>
                <ul className="list-disc list-inside space-y-1.5 text-slate-700">
                  <li>Enter accurate menu, business details, and billing settings</li>
                  <li>Use customer contact information exclusively for legitimate order execution</li>
                  <li>Maintain secure administrative passwords and PIN codes</li>
                  <li>Provide appropriate privacy notices to their dining guests where legally required</li>
                </ul>
              </div>
            </section>

            {/* 14. Children's Privacy */}
            <section id="children-privacy" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Baby className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 14</span>
                  <h2 className="text-2xl font-bold text-secondary">14. Children's Privacy</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi services are not intentionally directed to or designed for children under the age of 18 (or applicable legal majority). We do not knowingly collect personal data from minors. If you believe a minor has provided us with personal information, please contact our support team to remove the records.
              </p>
            </section>

            {/* 15. Third-Party Services */}
            <section id="third-party-services" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <ExternalLink className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 15</span>
                  <h2 className="text-2xl font-bold text-secondary">15. Third-Party Services & Links</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                The BillJi website or platform may contain links or integrations to external third-party services. BillJi is not responsible for the privacy practices, policies, or content of third-party websites outside our control.
              </p>
            </section>

            {/* 16. Changes to Policy */}
            <section id="policy-changes" className="scroll-mt-32 space-y-4">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <RefreshCw className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 16</span>
                  <h2 className="text-2xl font-bold text-secondary">16. Changes to This Privacy Policy</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                BillJi may update this Privacy Policy from time to time to reflect system updates, security enhancements, or legal modifications.
              </p>

              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200/80 text-xs text-slate-600 space-y-1.5">
                <p>When changes occur:</p>
                <ul className="list-disc list-inside space-y-1 text-slate-700">
                  <li>The updated policy will be posted on this page with a revised "Last Updated" date.</li>
                  <li>Material policy revisions will be communicated through site notices or email notifications.</li>
                </ul>
              </div>
            </section>

            {/* 17. Contact Us */}
            <section id="contact-us" className="scroll-mt-32 space-y-6">
              <div className="flex items-center space-x-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 bg-primary/10 text-primary rounded-2xl flex items-center justify-center font-bold shrink-0">
                  <Mail className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-bold text-primary uppercase tracking-wider">Section 17</span>
                  <h2 className="text-2xl font-bold text-secondary">17. Contact Us</h2>
                </div>
              </div>

              <p className="text-slate-600 leading-relaxed text-sm md:text-base">
                If you have questions, feedback, or data privacy requests concerning this policy, please reach out to our privacy team at BillJi:
              </p>

              {/* Company Info Box */}
              <div className="bg-slate-900 text-white p-6 md:p-8 rounded-3xl space-y-6 shadow-xl relative overflow-hidden">
                <div className="absolute bottom-0 right-0 w-64 h-64 bg-primary/10 rounded-full blur-3xl pointer-events-none" />

                <div className="border-b border-slate-800 pb-4">
                  <h3 className="text-lg font-bold text-white">BillJi</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-xs">
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2 text-primary font-bold">
                      <Mail className="w-4 h-4" />
                      <span>Email Support</span>
                    </div>
                    <p className="text-slate-300">
                      <a href="mailto:billji.support@gmail.com" className="hover:text-primary transition-colors block">
                        billji.support@gmail.com
                      </a>
                    </p>
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center space-x-2 text-primary font-bold">
                      <Phone className="w-4 h-4" />
                      <span>Phone Line</span>
                    </div>
                    <p className="text-slate-300">
                      +91 94091 11116<br />
                      +91 99747 23326<br />
                      Mon - Sat (9:00 AM - 7:00 PM IST)
                    </p>
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center space-x-2 text-primary font-bold">
                      <MapPin className="w-4 h-4" />
                      <span>We Are Here</span>
                    </div>
                    <p className="text-slate-300 leading-relaxed">
                      104, Hindva Pride, Near Sankalp International School, Amar Jawan Circle, Ahmedabad - 382350, India
                    </p>
                  </div>
                </div>

                <div className="pt-4 border-t border-slate-800 flex flex-wrap items-center justify-between gap-4">
                  <button
                    onClick={onOpenDemoModal}
                    className="bg-primary hover:bg-primary-dark text-white font-bold text-xs px-6 py-2.5 rounded-full transition-all shadow-md"
                  >
                    Book Product Demo
                  </button>
                </div>
              </div>
            </section>

          </main>
        </div>
      </div>

      {/* Floating Back to Top Button */}
      {showScrollTop && (
        <button
          onClick={scrollToTop}
          aria-label="Scroll to top"
          className="fixed bottom-8 right-8 z-30 bg-primary hover:bg-primary-dark text-white p-3.5 rounded-full shadow-2xl transition-all duration-300 hover:scale-110 flex items-center justify-center border border-white/20"
        >
          <ArrowUp className="w-5 h-5" />
        </button>
      )}
    </div>
  );
}
