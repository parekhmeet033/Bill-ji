import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Headphones,
  Globe,
  Phone,
  Mail,
  MapPin,
  ChevronRight,
  Clock,
  User,
  Smartphone,
  AlignLeft,
  Send,
  CheckCircle2,
  X
} from 'lucide-react';

const WEBSITE = 'https://bill-ji.com/';
const PHONE_1 = '+919974723326';
const PHONE_2 = '+919409111116';
const EMAIL = 'billji.support@gmail.com';
const ADDRESS = 'Hindva Pride, 104, Amar Jawan Cir, nr. Sankalp School Road, Nikol, Ahmedabad, Gujarat 382350';
const MAPS_URL = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(ADDRESS)}`;
const WHATSAPP_URL = 'https://wa.me/919974723326';
const FB_URL = 'https://www.facebook.com/profile.php?id=61596494626375';
const INSTA_URL = 'https://www.instagram.com/billji.official/?hl=en';
const LINKEDIN_URL = 'https://www.linkedin.com/company/goal-scripture/';

// Vector Brand Icons
function WhatsAppIcon({ className = 'h-5 w-5' }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12.031 2C6.511 2 2.02 6.491 2.02 12.012c0 1.954.563 3.864 1.632 5.518L2 22l4.629-1.611A9.972 9.972 0 0 0 12.031 22C17.55 22 22.04 17.509 22.04 11.988 22.04 6.467 17.55 2 12.031 2zm0 18.232c-1.677 0-3.32-.451-4.757-1.306l-.341-.202-2.756.959.979-2.686-.222-.353a8.163 8.163 0 0 1-1.258-4.632c0-4.529 3.684-8.213 8.213-8.213 4.529 0 8.213 3.684 8.213 8.213 0 4.53-3.684 8.22-8.213 8.22zm4.512-6.173c-.247-.123-1.464-.722-1.691-.805-.227-.082-.392-.123-.556.124-.165.247-.638.805-.783.97-.144.165-.289.185-.536.062-.247-.123-1.042-.384-1.986-1.226-.735-.655-1.232-1.465-1.376-1.712-.144-.247-.015-.381.108-.504.111-.111.247-.288.371-.432.124-.144.165-.247.247-.412.082-.165.041-.309-.021-.432-.062-.124-.556-1.339-.762-1.833-.2-.482-.404-.417-.556-.425l-.474-.008c-.165 0-.433.062-.659.309s-.866.845-.866 2.06c0 1.215.886 2.39 1.01 2.555.124.165 1.745 2.664 4.227 3.736.591.255 1.052.408 1.411.522.593.188 1.133.161 1.56.097.477-.071 1.464-.598 1.67-1.175.206-.577.206-1.072.144-1.175-.062-.103-.227-.165-.474-.288z" />
    </svg>
  );
}

function FacebookIcon({ className = 'h-6 w-6' }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="#1877F2">
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
    </svg>
  );
}

function InstagramIcon({ className = 'h-6 w-6' }) {
  return (
    <svg className={className} viewBox="0 0 24 24">
      <radialGradient id="rg-support-app" cx="0.2" cy="1" r="1">
        <stop offset="0%" stopColor="#ffd521" />
        <stop offset="25%" stopColor="#f50000" />
        <stop offset="60%" stopColor="#c50077" />
        <stop offset="100%" stopColor="#7a0099" />
      </radialGradient>
      <path
        fill="url(#rg-support-app)"
        d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"
      />
    </svg>
  );
}

function LinkedInIcon({ className = 'h-6 w-6' }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="#0A66C2">
      <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
    </svg>
  );
}

export default function SupportPage() {
  const navigate = useNavigate();

  // Form state
  const [name, setName] = useState('');
  const [mobile, setMobile] = useState('');
  const [email, setEmail] = useState('');
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Call chooser modal state
  const [showCallModal, setShowCallModal] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name.trim() || !mobile.trim() || !email.trim() || !message.trim()) {
      alert('Please fill in all required fields.');
      return;
    }
    setSubmitting(true);
    setTimeout(() => {
      setSubmitting(false);
      setSubmitted(true);
      setName('');
      setMobile('');
      setEmail('');
      setSubject('');
      setMessage('');
      setTimeout(() => setSubmitted(false), 5000);
    }, 500);
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-[#0B1120] text-slate-900 dark:text-slate-100 antialiased font-sans transition-colors">
      {/* Top Container with Centered Constraint */}
      <div className="mx-auto max-w-md sm:max-w-lg lg:max-w-xl">
        {/* Curved Branded Orange Header (matching exact mobile design) */}
        <div className="relative overflow-hidden rounded-b-[2.2rem] sm:rounded-b-[2.5rem] bg-gradient-to-br from-[#FE701A] to-[#FF8A3D] px-5 pb-8 pt-5 text-white shadow-lg">
          {/* Large Translucent Headset Watermark in Top-Right */}
          <Headphones
            aria-hidden="true"
            className="pointer-events-none absolute -right-3 -top-2 h-28 w-28 text-white/20 select-none stroke-[1.5] sm:h-36 sm:w-36"
          />

          {/* Top Back Navigation Bar */}
          <div className="relative z-10 flex items-center">
            <button
              type="button"
              onClick={() => navigate('/app/settings')}
              aria-label="Back to Settings"
              className="flex h-9 w-9 items-center justify-center rounded-full text-white transition-transform hover:scale-110 active:scale-95 focus:outline-none"
            >
              <ArrowLeft className="h-6 w-6 stroke-[2.5]" />
            </button>
          </div>

          {/* Header Title & Subtitle */}
          <div className="relative z-10 mt-3 px-1">
            <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">
              Contact &amp; Support
            </h1>
            <p className="mt-1 text-sm font-medium text-white/90">
              We&apos;re here to help you!
            </p>
          </div>
        </div>

        {/* Content Section */}
        <div className="space-y-6 px-4 py-6">
          {/* 1. Contact Information Card */}
          <div className="overflow-hidden rounded-3xl border border-slate-200/80 bg-white shadow-sm dark:border-slate-800/80 dark:bg-[#161F30]">
            <div className="divide-y divide-slate-100 dark:divide-slate-800/80">
              {/* Website */}
              <a
                href={WEBSITE}
                target="_blank"
                rel="noopener noreferrer"
                className="group flex items-center justify-between p-4 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-orange-500/10 text-primary dark:bg-orange-500/15">
                    <Globe className="h-5 w-5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-slate-400 dark:text-slate-400">Website</p>
                    <p className="truncate text-sm font-semibold text-slate-800 dark:text-white">
                      {WEBSITE}
                    </p>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 dark:text-slate-500 transition-transform group-hover:translate-x-0.5" />
              </a>

              {/* Phone 1 */}
              <a
                href={`tel:${PHONE_1}`}
                className="group flex items-center justify-between p-4 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-orange-500/10 text-primary dark:bg-orange-500/15">
                    <Phone className="h-5 w-5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-slate-400 dark:text-slate-400">Phone</p>
                    <p className="truncate text-sm font-semibold text-slate-800 dark:text-white">
                      {PHONE_1}
                    </p>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 dark:text-slate-500 transition-transform group-hover:translate-x-0.5" />
              </a>

              {/* Phone 2 */}
              <a
                href={`tel:${PHONE_2}`}
                className="group flex items-center justify-between p-4 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-orange-500/10 text-primary dark:bg-orange-500/15">
                    <Phone className="h-5 w-5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-slate-400 dark:text-slate-400">Phone</p>
                    <p className="truncate text-sm font-semibold text-slate-800 dark:text-white">
                      {PHONE_2}
                    </p>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 dark:text-slate-500 transition-transform group-hover:translate-x-0.5" />
              </a>

              {/* Email */}
              <a
                href={`mailto:${EMAIL}`}
                className="group flex items-center justify-between p-4 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-orange-500/10 text-primary dark:bg-orange-500/15">
                    <Mail className="h-5 w-5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-slate-400 dark:text-slate-400">Email</p>
                    <p className="truncate text-sm font-semibold text-slate-800 dark:text-white">
                      {EMAIL}
                    </p>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 dark:text-slate-500 transition-transform group-hover:translate-x-0.5" />
              </a>

              {/* Address */}
              <a
                href={MAPS_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group flex items-start justify-between p-4 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50"
              >
                <div className="flex items-start gap-3.5 min-w-0">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-orange-500/10 text-primary dark:bg-orange-500/15 mt-0.5">
                    <MapPin className="h-5 w-5" />
                  </div>
                  <div className="min-w-0 pr-2">
                    <p className="text-xs font-medium text-slate-400 dark:text-slate-400">Address</p>
                    <p className="text-sm font-semibold leading-relaxed text-slate-800 dark:text-white">
                      {ADDRESS}
                    </p>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 dark:text-slate-500 transition-transform group-hover:translate-x-0.5 mt-2" />
              </a>
            </div>
          </div>

          {/* 2. Quick Actions */}
          <div>
            <h2 className="mb-3 px-1 text-[15px] font-bold text-slate-900 dark:text-white">Quick Actions</h2>
            <div className="grid grid-cols-4 gap-2.5 sm:gap-3 text-center">
              {/* Call Now */}
              <button
                type="button"
                onClick={() => setShowCallModal(true)}
                className="group flex flex-col items-center justify-center rounded-2xl border border-slate-200/80 bg-white p-3 shadow-sm transition-all hover:scale-[1.02] active:scale-95 dark:border-slate-800/80 dark:bg-[#161F30]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-500 dark:bg-emerald-500/15">
                  <Phone className="h-5 w-5" />
                </div>
                <span className="mt-2 text-xs font-bold text-slate-800 dark:text-slate-200">Call Now</span>
              </button>

              {/* WhatsApp */}
              <a
                href={WHATSAPP_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group flex flex-col items-center justify-center rounded-2xl border border-slate-200/80 bg-white p-3 shadow-sm transition-all hover:scale-[1.02] active:scale-95 dark:border-slate-800/80 dark:bg-[#161F30]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#25D366]/10 text-[#25D366] dark:bg-[#25D366]/15">
                  <WhatsAppIcon className="h-5 w-5" />
                </div>
                <span className="mt-2 text-xs font-bold text-slate-800 dark:text-slate-200">WhatsApp</span>
              </a>

              {/* Send Email */}
              <a
                href={`mailto:${EMAIL}`}
                className="group flex flex-col items-center justify-center rounded-2xl border border-slate-200/80 bg-white p-3 shadow-sm transition-all hover:scale-[1.02] active:scale-95 dark:border-slate-800/80 dark:bg-[#161F30]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-sky-500/10 text-sky-500 dark:bg-sky-500/15">
                  <Mail className="h-5 w-5" />
                </div>
                <span className="mt-2 text-xs font-bold text-slate-800 dark:text-slate-200">Send Email</span>
              </a>

              {/* Get Direction */}
              <a
                href={MAPS_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group flex flex-col items-center justify-center rounded-2xl border border-slate-200/80 bg-white p-3 shadow-sm transition-all hover:scale-[1.02] active:scale-95 dark:border-slate-800/80 dark:bg-[#161F30]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-purple-500/10 text-purple-500 dark:bg-purple-500/15">
                  <MapPin className="h-5 w-5" />
                </div>
                <span className="mt-2 text-xs font-bold text-slate-800 dark:text-slate-200">Get Direction</span>
              </a>
            </div>
          </div>

          {/* 3. Support Hours & Need Help Side-by-Side */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
            {/* Support Hours */}
            <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800/80 dark:bg-[#161F30]">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-500/10 text-sky-500 dark:bg-sky-500/15">
                <Clock className="h-5 w-5" />
              </div>
              <h3 className="mt-3 text-sm font-bold text-slate-900 dark:text-white">Support Hours</h3>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">Monday - Saturday</p>
              <p className="text-xs font-medium text-slate-400 dark:text-slate-500">10:00 AM - 7:00 PM</p>
            </div>

            {/* Need Help? */}
            <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800/80 dark:bg-[#161F30]">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-500/10 text-purple-500 dark:bg-purple-500/15">
                <Headphones className="h-5 w-5" />
              </div>
              <h3 className="mt-3 text-sm font-bold text-slate-900 dark:text-white">Need Help?</h3>
              <p className="mt-1 text-xs leading-relaxed text-slate-500 dark:text-slate-400">
                Our support team typically responds within 24 hours.
              </p>
            </div>
          </div>

          {/* 4. Send Us a Message */}
          <div className="rounded-3xl border border-slate-200/80 bg-white p-5 sm:p-6 shadow-sm dark:border-slate-800/80 dark:bg-[#161F30]">
            <h2 className="mb-4 text-base sm:text-lg font-bold text-slate-900 dark:text-white">
              Send Us a Message
            </h2>

            {submitted && (
              <div className="mb-4 flex items-center gap-2.5 rounded-2xl border border-emerald-500/30 bg-emerald-50 p-3.5 text-xs font-semibold text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400">
                <CheckCircle2 className="h-4 w-4 shrink-0" />
                <span>Thank you! Your message has been sent successfully. We will get back to you shortly.</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-3.5">
              {/* Name & Mobile side by side */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="relative">
                  <User className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Your Name"
                    className="w-full rounded-2xl border border-slate-200 bg-slate-50/70 py-3 pl-10 pr-3.5 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition-colors focus:border-primary focus:bg-white dark:border-slate-800 dark:bg-[#0B1120] dark:text-white dark:placeholder:text-slate-500 dark:focus:border-primary dark:focus:bg-[#080d19]"
                  />
                </div>

                <div className="relative">
                  <Smartphone className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                  <input
                    type="tel"
                    required
                    value={mobile}
                    onChange={(e) => setMobile(e.target.value)}
                    placeholder="Mobile Nu..."
                    className="w-full rounded-2xl border border-slate-200 bg-slate-50/70 py-3 pl-10 pr-3.5 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition-colors focus:border-primary focus:bg-white dark:border-slate-800 dark:bg-[#0B1120] dark:text-white dark:placeholder:text-slate-500 dark:focus:border-primary dark:focus:bg-[#080d19]"
                  />
                </div>
              </div>

              {/* Email Address */}
              <div className="relative">
                <Mail className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email Address"
                  className="w-full rounded-2xl border border-slate-200 bg-slate-50/70 py-3 pl-10 pr-3.5 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition-colors focus:border-primary focus:bg-white dark:border-slate-800 dark:bg-[#0B1120] dark:text-white dark:placeholder:text-slate-500 dark:focus:border-primary dark:focus:bg-[#080d19]"
                />
              </div>

              {/* Subject */}
              <div className="relative">
                <AlignLeft className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={subject}
                  onChange={(e) => setSubject(e.target.value)}
                  placeholder="Subject"
                  className="w-full rounded-2xl border border-slate-200 bg-slate-50/70 py-3 pl-10 pr-3.5 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition-colors focus:border-primary focus:bg-white dark:border-slate-800 dark:bg-[#0B1120] dark:text-white dark:placeholder:text-slate-500 dark:focus:border-primary dark:focus:bg-[#080d19]"
                />
              </div>

              {/* Message Textarea */}
              <div>
                <textarea
                  required
                  rows={4}
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Type your message here..."
                  className="w-full resize-none rounded-2xl border border-slate-200 bg-slate-50/70 p-3.5 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition-colors focus:border-primary focus:bg-white dark:border-slate-800 dark:bg-[#0B1120] dark:text-white dark:placeholder:text-slate-500 dark:focus:border-primary dark:focus:bg-[#080d19]"
                />
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={submitting}
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-primary py-3.5 text-sm font-bold text-white shadow-lg shadow-orange-500/25 transition-all hover:bg-orange-600 active:scale-[0.99] disabled:opacity-60"
              >
                <Send className="h-4 w-4 rotate-45" />
                <span>{submitting ? 'Sending...' : 'Submit Message'}</span>
              </button>
            </form>
          </div>

          {/* 5. Follow Us */}
          <div className="flex items-center justify-between px-2 pt-1 pb-4">
            <span className="text-sm font-bold text-slate-800 dark:text-slate-200">Follow Us</span>
            <div className="flex items-center gap-3.5">
              <a
                href={FB_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="transition-transform hover:scale-110 active:scale-95"
                title="Facebook"
              >
                <FacebookIcon className="h-6 w-6" />
              </a>
              <a
                href={INSTA_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="transition-transform hover:scale-110 active:scale-95"
                title="Instagram"
              >
                <InstagramIcon className="h-6 w-6" />
              </a>
              <a
                href={LINKEDIN_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="transition-transform hover:scale-110 active:scale-95"
                title="LinkedIn"
              >
                <LinkedInIcon className="h-6 w-6" />
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Call Chooser Dialog */}
      {showCallModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"
            onClick={() => setShowCallModal(false)}
          />
          <div className="relative z-10 w-full max-w-sm rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-[#161F30]">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3 dark:border-slate-800">
              <h3 className="text-base font-bold text-slate-900 dark:text-white">Select Number to Call</h3>
              <button
                type="button"
                onClick={() => setShowCallModal(false)}
                className="rounded-full bg-slate-100 p-1.5 text-slate-500 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:hover:text-white"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            <div className="mt-4 space-y-2.5">
              {[
                { number: PHONE_1, label: 'Primary Support' },
                { number: PHONE_2, label: 'Alternative Support' }
              ].map((item) => (
                <a
                  key={item.number}
                  href={`tel:${item.number}`}
                  onClick={() => setShowCallModal(false)}
                  className="flex items-center justify-between rounded-2xl border border-slate-100 bg-slate-50 p-3.5 transition-colors hover:border-primary hover:bg-white dark:border-slate-800 dark:bg-[#0B1120] dark:hover:border-primary"
                >
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-500 dark:bg-emerald-500/15">
                      <Phone className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-xs text-slate-400">{item.label}</p>
                      <p className="text-sm font-bold text-slate-900 dark:text-white">{item.number}</p>
                    </div>
                  </div>
                  <ChevronRight className="h-4 w-4 text-slate-400 dark:text-slate-500" />
                </a>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
