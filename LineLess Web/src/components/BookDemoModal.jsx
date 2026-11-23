import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Calendar, User, Phone, Building2, CheckCircle2, Sparkles, ArrowRight, Mail, Loader2, AlertCircle } from 'lucide-react';
import {
  getTodayDateString,
  validateEmail,
  validateMobile,
  validateBookingDate,
  sanitizeMobileInput,
  validateRequired
} from '../utils/validation';
import { WEB3FORMS_ACCESS_KEY } from '../pages/Contact';

export default function BookDemoModal({ isOpen, onClose }) {
  const todayStr = getTodayDateString();
  const [submitted, setSubmitted] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState('');

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    restaurantName: '',
    type: 'Cloud Kitchen',
    preferredDate: todayStr,
  });

  const [errors, setErrors] = useState({
    name: '',
    email: '',
    phone: '',
    restaurantName: '',
    preferredDate: '',
  });

  if (!isOpen) return null;

  // Single field validation helper for real-time updates
  const validateField = (name, value) => {
    let err = null;
    if (name === 'name') {
      err = validateRequired(value, 'Your Name');
    } else if (name === 'email') {
      err = validateEmail(value);
    } else if (name === 'phone') {
      err = validateMobile(value);
    } else if (name === 'restaurantName') {
      err = validateRequired(value, 'Restaurant / Business Name');
    } else if (name === 'preferredDate') {
      err = validateBookingDate(value);
    }
    return err || '';
  };

  const handleInputChange = (field, rawValue) => {
    let val = rawValue;
    if (field === 'phone') {
      val = sanitizeMobileInput(rawValue);
    }

    setFormData(prev => ({ ...prev, [field]: val }));

    // Instant real-time validation feedback
    const fieldErr = validateField(field, val);
    setErrors(prev => ({ ...prev, [field]: fieldErr }));
    if (serverError) setServerError('');
  };

  const validateAll = () => {
    const newErrors = {
      name: validateRequired(formData.name, 'Your Name') || '',
      email: validateEmail(formData.email) || '',
      phone: validateMobile(formData.phone) || '',
      restaurantName: validateRequired(formData.restaurantName, 'Restaurant / Business Name') || '',
      preferredDate: validateBookingDate(formData.preferredDate) || '',
    };
    setErrors(newErrors);
    return !Object.values(newErrors).some(err => err !== '');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setServerError('');

    if (!validateAll()) {
      return;
    }

    setIsSubmitting(true);

    // 1. Best-effort server-side validation (does not deliver the email; only
    //    lets the backend reject bad input). Offline/network errors fall through
    //    to the email send below so a booking is never silently dropped.
    try {
      const response = await fetch('/api/book-demo', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json'
        },
        body: JSON.stringify({
          name: formData.name.trim(),
          email: formData.email.trim(),
          phone: formData.phone.trim(),
          restaurantName: formData.restaurantName.trim(),
          type: formData.type,
          preferredDate: formData.preferredDate.trim(),
        })
      });

      if (response.status === 400) {
        const result = await response.json().catch(() => ({}));
        if (result.errors) {
          setErrors(prev => ({ ...prev, ...result.errors }));
        }
        setServerError(result.message || 'Please correct the highlighted fields.');
        setIsSubmitting(false);
        return;
      }
    } catch (err) {
      console.warn('Backend validation endpoint unreachable, sending email directly:', err);
    }

    // 2. Deliver the booking email. This runs on every valid submission — the
    //    previous code never emailed demo bookings at all (success just closed
    //    the form), which is why no demo emails were arriving.
    try {
      const web3Res = await fetch('https://api.web3forms.com/submit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json'
        },
        body: JSON.stringify({
          access_key: WEB3FORMS_ACCESS_KEY,
          subject: `BillJi Demo Booking - ${formData.restaurantName}`,
          from_name: 'BillJi Website',
          name: formData.name.trim(),
          email: formData.email.trim(),
          phone: formData.phone.trim(),
          restaurantName: formData.restaurantName.trim(),
          businessType: formData.type,
          preferredDate: formData.preferredDate.trim(),
        })
      });
      const web3Data = await web3Res.json().catch(() => ({ success: false }));
      if (web3Data.success) {
        setSubmitted(true);
      } else {
        setServerError('Could not book your demo right now. Please try again or email billji.support@gmail.com.');
      }
    } catch (err) {
      setServerError('Network error while sending. Please check your connection and try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleReset = () => {
    setSubmitted(false);
    setFormData({
      name: '',
      email: '',
      phone: '',
      restaurantName: '',
      type: 'Cloud Kitchen',
      preferredDate: todayStr,
    });
    setErrors({
      name: '',
      email: '',
      phone: '',
      restaurantName: '',
      preferredDate: '',
    });
    setServerError('');
    onClose();
  };

  const hasFormErrors = Object.values(errors).some(err => err !== '');

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-slate-900/60 backdrop-blur-md"
          />

          {/* Modal Card */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="relative w-full max-w-xl bg-white rounded-3xl shadow-2xl border border-slate-100 overflow-hidden z-10 my-auto max-h-[92vh] flex flex-col"
          >
            {/* Top Gradient Banner */}
            <div className="bg-gradient-to-r from-secondary via-secondary-light to-primary-900 text-white p-6 md:p-8 relative">
              <button
                onClick={onClose}
                className="absolute top-6 right-6 p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
                aria-label="Close"
              >
                <X className="w-5 h-5" />
              </button>
              <div className="inline-flex items-center space-x-2 bg-primary/20 border border-primary/30 text-primary-light px-3 py-1 rounded-full text-xs font-semibold mb-3">
                <Sparkles className="w-3.5 h-3.5 text-primary-light" />
                <span>BillJi Restaurant OS</span>
              </div>
              <h3 className="text-2xl md:text-3xl font-black text-white leading-tight">
                Book a Live 1-on-1 Demo
              </h3>
              <p className="text-slate-300 text-sm mt-2">
                See how BillJi automates POS, Table Management, KDS, and Secure Reports in 15 minutes.
              </p>
            </div>

            {/* Form or Confirmation */}
            <div className="p-6 md:p-8 overflow-y-auto flex-1">
              {submitted ? (
                <div className="text-center py-6 space-y-4">
                  <div className="w-16 h-16 bg-primary-50 text-primary rounded-full flex items-center justify-center mx-auto shadow-inner">
                    <CheckCircle2 className="w-10 h-10" />
                  </div>
                  <h4 className="text-2xl font-bold text-secondary">Demo Request Submitted!</h4>
                  <p className="text-slate-600 text-sm max-w-md mx-auto leading-relaxed">
                    Thank you <span className="font-semibold text-secondary">{formData.name || 'Partner'}</span>! Our restaurant automation specialist from BillJi will contact you at <span className="font-semibold text-secondary">{formData.phone}</span> ({formData.email}) on <span className="font-semibold text-secondary">{formData.preferredDate}</span> to confirm your session.
                  </p>
                  <button
                    onClick={handleReset}
                    className="mt-4 bg-primary hover:bg-primary-dark text-white font-bold px-8 py-3 rounded-full transition-all duration-300 shadow-md hover:shadow-primary/30"
                  >
                    Done
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4 text-left" noValidate>
                  {serverError && (
                    <div className="p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start space-x-2">
                      <AlertCircle className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />
                      <span>{serverError}</span>
                    </div>
                  )}

                  {/* Name */}
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                      Your Name *
                    </label>
                    <div className="relative">
                      <User className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        placeholder="e.g. Prashant Kareliya"
                        value={formData.name}
                        onChange={(e) => handleInputChange('name', e.target.value)}
                        className={`w-full pl-11 pr-4 py-3 border rounded-2xl text-sm focus:outline-none transition-all ${
                          errors.name ? 'border-red-500 bg-red-50/10 focus:border-red-500' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                        }`}
                      />
                    </div>
                    {errors.name && <p className="text-red-500 text-xs font-semibold mt-1">{errors.name}</p>}
                  </div>

                  {/* Grid for Email & Mobile Number */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Email */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                        Email Address *
                      </label>
                      <div className="relative">
                        <Mail className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                        <input
                          type="email"
                          placeholder="e.g. name@restaurant.com"
                          value={formData.email}
                          onChange={(e) => handleInputChange('email', e.target.value)}
                          className={`w-full pl-11 pr-4 py-3 border rounded-2xl text-sm focus:outline-none transition-all ${
                            errors.email ? 'border-red-500 bg-red-50/10 focus:border-red-500' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                          }`}
                        />
                      </div>
                      {errors.email && <p className="text-red-500 text-xs font-semibold mt-1">{errors.email}</p>}
                    </div>

                    {/* Mobile Number */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                        Mobile Number *
                      </label>
                      <div className="relative">
                        <Phone className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                        <input
                          type="tel"
                          maxLength={10}
                          placeholder="e.g. 9876543210"
                          value={formData.phone}
                          onChange={(e) => handleInputChange('phone', e.target.value)}
                          className={`w-full pl-11 pr-4 py-3 border rounded-2xl text-sm focus:outline-none transition-all ${
                            errors.phone ? 'border-red-500 bg-red-50/10 focus:border-red-500' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                          }`}
                        />
                      </div>
                      {errors.phone && <p className="text-red-500 text-xs font-semibold mt-1">{errors.phone}</p>}
                    </div>
                  </div>

                  {/* Restaurant Name */}
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                      Restaurant / Business Name *
                    </label>
                    <div className="relative">
                      <Building2 className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        placeholder="e.g. Brew Haven Café"
                        value={formData.restaurantName}
                        onChange={(e) => handleInputChange('restaurantName', e.target.value)}
                        className={`w-full pl-11 pr-4 py-3 border rounded-2xl text-sm focus:outline-none transition-all ${
                          errors.restaurantName ? 'border-red-500 bg-red-50/10 focus:border-red-500' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                        }`}
                      />
                    </div>
                    {errors.restaurantName && <p className="text-red-500 text-xs font-semibold mt-1">{errors.restaurantName}</p>}
                  </div>

                  {/* Grid for Business Type & Date */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                        Business Type
                      </label>
                      <select
                        value={formData.type}
                        onChange={(e) => handleInputChange('type', e.target.value)}
                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl text-sm focus:outline-none focus:border-primary focus:bg-white transition-colors"
                      >
                        <option value="Cloud Kitchen">Cloud Kitchen</option>
                        <option value="Fast Casual Restaurant">Fast Casual Restaurant</option>
                        <option value="Dine-in Food Court">Dine-in Food Court</option>
                        <option value="Café / Coffee Shop">Café / Coffee Shop</option>
                        <option value="Multi-Outlet Chain">Multi-Outlet Chain</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                        Preferred Date *
                      </label>
                      <div className="relative">
                        <Calendar className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                        <input
                          type="date"
                          min={todayStr}
                          value={formData.preferredDate}
                          onChange={(e) => handleInputChange('preferredDate', e.target.value)}
                          className={`w-full pl-11 pr-4 py-3 border rounded-2xl text-sm focus:outline-none transition-all ${
                            errors.preferredDate ? 'border-red-500 bg-red-50/10 focus:border-red-500' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                          }`}
                        />
                      </div>
                      {errors.preferredDate && <p className="text-red-500 text-xs font-semibold mt-1">{errors.preferredDate}</p>}
                    </div>
                  </div>

                  <div className="pt-3">
                    <button
                      type="submit"
                      disabled={isSubmitting || hasFormErrors}
                      className={`w-full bg-primary hover:bg-primary-dark text-white font-bold py-3.5 rounded-2xl shadow-lg hover:shadow-primary/30 transition-all duration-300 flex items-center justify-center space-x-2 text-base ${
                        isSubmitting || hasFormErrors ? 'opacity-60 cursor-not-allowed' : 'hover:scale-[1.01]'
                      }`}
                    >
                      {isSubmitting ? (
                        <>
                          <Loader2 className="w-5 h-5 animate-spin" />
                          <span>Booking Demo...</span>
                        </>
                      ) : (
                        <>
                          <span>Confirm Book Demo</span>
                          <ArrowRight className="w-5 h-5" />
                        </>
                      )}
                    </button>
                  </div>
                  <p className="text-[11px] text-center text-slate-400 pt-1">
                    🔒 Zero commitment. Free setup assistance provided.
                  </p>
                </form>
              )}
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
