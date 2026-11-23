import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Phone,
  Mail,
  MapPin,
  Clock,
  Send,
  CheckCircle,
  Calendar,
  Loader2,
  AlertCircle
} from 'lucide-react';
import { FacebookIcon, TwitterIcon, InstagramIcon, LinkedinIcon } from '../components/SocialIcons';
import {
  getTodayDateString,
  validateEmail,
  validateMobile,
  validateBookingDate,
  sanitizeMobileInput,
  validateRequired
} from '../utils/validation';

// Shared across the public lead forms (Contact + Book Demo). Registered to the
// inbox that receives leads on web3forms.com — verify it points at the right one.
export const WEB3FORMS_ACCESS_KEY = "56308917-1802-444e-8afe-3377bed88a24";

export default function Contact() {
  const todayStr = getTodayDateString();

  const [formData, setFormData] = useState({
    name: '',
    businessName: '',
    mobile: '',
    email: '',
    preferredDate: todayStr,
    city: '',
    message: ''
  });

  const [errors, setErrors] = useState({
    name: '',
    businessName: '',
    mobile: '',
    email: '',
    preferredDate: '',
    city: '',
    message: ''
  });

  const [submitted, setSubmitted] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [serverError, setServerError] = useState('');

  const validateField = (name, value) => {
    let err = null;
    if (name === 'name') err = validateRequired(value, 'Full Name');
    else if (name === 'businessName') err = validateRequired(value, 'Business Name');
    else if (name === 'mobile') err = validateMobile(value);
    else if (name === 'email') err = validateEmail(value);
    else if (name === 'preferredDate') err = validateBookingDate(value);
    else if (name === 'city') err = validateRequired(value, 'City');
    else if (name === 'message') err = validateRequired(value, 'Message Details');
    return err || '';
  };

  const handleInputChange = (e) => {
    const { name, value: rawValue } = e.target;
    let value = rawValue;

    if (name === 'mobile') {
      value = sanitizeMobileInput(rawValue);
    }

    setFormData(prev => ({
      ...prev,
      [name]: value
    }));

    // Real-time validation
    const fieldErr = validateField(name, value);
    setErrors(prev => ({ ...prev, [name]: fieldErr }));
    if (serverError) setServerError('');
  };

  const validateAll = () => {
    const newErrors = {
      name: validateRequired(formData.name, 'Full Name') || '',
      businessName: validateRequired(formData.businessName, 'Business Name') || '',
      mobile: validateMobile(formData.mobile) || '',
      email: validateEmail(formData.email) || '',
      preferredDate: validateBookingDate(formData.preferredDate) || '',
      city: validateRequired(formData.city, 'City') || '',
      message: validateRequired(formData.message, 'Message Details') || '',
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

    setIsSending(true);

    // 1. Best-effort server-side validation. This does NOT deliver the email;
    //    it only lets the backend reject invalid input. A network/offline error
    //    here must not block the actual email send below.
    try {
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json"
        },
        body: JSON.stringify({
          name: formData.name.trim(),
          email: formData.email.trim(),
          businessName: formData.businessName.trim(),
          mobile: formData.mobile.trim(),
          preferredDate: formData.preferredDate.trim(),
          city: formData.city.trim(),
          message: formData.message.trim(),
          subject: `BillJi Contact Request - ${formData.businessName}`
        })
      });

      if (response.status === 400) {
        const result = await response.json().catch(() => ({}));
        if (result.errors) {
          setErrors(prev => ({ ...prev, ...result.errors }));
        }
        setServerError(result.message || "Please correct the highlighted fields.");
        setIsSending(false);
        return;
      }
    } catch (err) {
      // Backend is optional for delivery — continue to send the email.
      console.warn("Backend validation endpoint unreachable, sending email directly:", err);
    }

    // 2. Deliver the email. Web3Forms is the actual mail transport; this runs on
    //    every valid submission (the previous code only sent it when /api threw,
    //    so in production — where /api succeeds — no email was ever sent).
    try {
      const web3Res = await fetch("https://api.web3forms.com/submit", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json"
        },
        body: JSON.stringify({
          access_key: WEB3FORMS_ACCESS_KEY,
          subject: `BillJi Contact Request - ${formData.businessName}`,
          from_name: "BillJi Website",
          name: formData.name.trim(),
          email: formData.email.trim(),
          businessName: formData.businessName.trim(),
          mobile: formData.mobile.trim(),
          preferredDate: formData.preferredDate.trim() || "—",
          city: formData.city.trim(),
          message: formData.message.trim()
        })
      });
      const web3Data = await web3Res.json().catch(() => ({ success: false }));
      if (web3Data.success) {
        setSubmitted(true);
      } else {
        setServerError("Could not send your message right now. Please try again or email billji.support@gmail.com.");
      }
    } catch (err) {
      setServerError("Network error while sending. Please check your connection and try again.");
    } finally {
      setIsSending(false);
    }
  };

  const hasFormErrors = Object.values(errors).some(err => err !== '');

  return (
    <div className="bg-white py-16 min-h-[85vh] relative overflow-hidden">
      {/* Decorative gradient bubbles */}
      <div className="absolute top-[20%] left-[-10%] w-[350px] h-[350px] rounded-full bg-primary-100/30 blur-3xl pointer-events-none" />
      <div className="absolute bottom-[10%] right-[-15%] w-[450px] h-[450px] rounded-full bg-slate-100 blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-6 md:px-12 relative z-10">
        {/* Title */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <span className="text-xs font-bold uppercase tracking-widest text-primary bg-primary/10 px-4 py-1.5 rounded-full">
            Contact Us
          </span>
          <h1 className="text-4xl md:text-5xl font-black text-secondary mt-4">
            Request A Free Demo
          </h1>
          <p className="text-slate-600 mt-4 text-base md:text-lg">
            Tell us about your food business, and our tech team will show you how to implement QR ordering in less than 24 hours.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-8 lg:gap-12 items-stretch">
          {/* Left Side: Contact Form Card */}
          <div className="md:col-span-7 bg-white p-8 md:p-10 rounded-3xl shadow-xl border border-slate-100">
            <AnimatePresence mode="wait">
              {!submitted ? (
                <motion.form
                  key="form"
                  initial={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  onSubmit={handleSubmit}
                  className="space-y-6"
                  noValidate
                >
                  <h3 className="text-2xl font-bold text-secondary text-left">Your Information</h3>

                  {serverError && (
                    <div className="p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start space-x-2 text-left">
                      <AlertCircle className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />
                      <span>{serverError}</span>
                    </div>
                  )}

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-left">
                    {/* Name */}
                    <div>
                      <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Full Name *</label>
                      <input
                        type="text"
                        name="name"
                        value={formData.name}
                        onChange={handleInputChange}
                        className={`w-full text-sm p-3.5 border rounded-2xl focus:outline-none transition-all ${errors.name ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                          }`}
                        placeholder="e.g. Raj Patel"
                      />
                      {errors.name && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.name}</p>}
                    </div>

                    {/* Business Name */}
                    <div>
                      <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Business Name *</label>
                      <input
                        type="text"
                        name="businessName"
                        value={formData.businessName}
                        onChange={handleInputChange}
                        className={`w-full text-sm p-3.5 border rounded-2xl focus:outline-none transition-all ${errors.businessName ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                          }`}
                        placeholder="e.g. Brew Haven Café"
                      />
                      {errors.businessName && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.businessName}</p>}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-left">
                    {/* Mobile Number */}
                    <div>
                      <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Mobile Number *</label>
                      <input
                        type="tel"
                        name="mobile"
                        maxLength={10}
                        value={formData.mobile}
                        onChange={handleInputChange}
                        className={`w-full text-sm p-3.5 border rounded-2xl focus:outline-none transition-all ${errors.mobile ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                          }`}
                        placeholder="e.g. 9974723326"
                      />
                      {errors.mobile && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.mobile}</p>}
                    </div>

                    {/* Email Address */}
                    <div>
                      <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Email Address *</label>
                      <input
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleInputChange}
                        className={`w-full text-sm p-3.5 border rounded-2xl focus:outline-none transition-all ${errors.email ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                          }`}
                        placeholder="e.g. info@shop.com"
                      />
                      {errors.email && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.email}</p>}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-left">
                    {/* Preferred Date */}
                    <div>
                      <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Preferred Demo Date *</label>
                      <div className="relative">
                        <Calendar className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                        <input
                          type="date"
                          name="preferredDate"
                          min={todayStr}
                          value={formData.preferredDate}
                          onChange={handleInputChange}
                          className={`w-full text-sm pl-10 pr-3.5 py-3.5 border rounded-2xl focus:outline-none transition-all ${errors.preferredDate ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                            }`}
                        />
                      </div>
                      {errors.preferredDate && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.preferredDate}</p>}
                    </div>

                    {/* City */}
                    <div>
                      <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">City *</label>
                      <input
                        type="text"
                        name="city"
                        value={formData.city}
                        onChange={handleInputChange}
                        className={`w-full text-sm p-3.5 border rounded-2xl focus:outline-none transition-all ${errors.city ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                          }`}
                        placeholder="e.g. Ahmedabad, Surat, Mumbai"
                      />
                      {errors.city && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.city}</p>}
                    </div>
                  </div>

                  {/* Message */}
                  <div className="text-left">
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Message Details *</label>
                    <textarea
                      name="message"
                      value={formData.message}
                      onChange={handleInputChange}
                      rows="4"
                      className={`w-full text-sm p-3.5 border rounded-2xl focus:outline-none transition-all resize-none ${errors.message ? 'border-red-500 bg-red-50/10' : 'border-slate-200 focus:border-primary'
                        }`}
                      placeholder="Tell us about your kitchen, daily order estimates, or specific requirements..."
                    />
                    {errors.message && <p className="text-red-500 text-xs mt-1 font-semibold">{errors.message}</p>}
                  </div>

                  {/* Submit Button */}
                  <button
                    type="submit"
                    disabled={isSending || hasFormErrors}
                    className={`w-full bg-primary hover:bg-primary-dark text-white font-bold p-4 rounded-full shadow-lg hover:shadow-primary/30 transition-all duration-300 flex items-center justify-center space-x-2 ${isSending || hasFormErrors ? 'opacity-60 cursor-not-allowed' : 'hover:scale-[1.01]'
                      }`}
                  >
                    {isSending ? (
                      <>
                        <Loader2 className="w-5 h-5 animate-spin" />
                        <span>Sending Request...</span>
                      </>
                    ) : (
                      <>
                        <span>Request Demo</span>
                        <Send className="w-4 h-4" />
                      </>
                    )}
                  </button>
                </motion.form>
              ) : (
                <motion.div
                  key="success"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ duration: 0.5 }}
                  className="flex flex-col items-center justify-center py-20 text-center space-y-6"
                >
                  <div className="w-20 h-20 bg-green-50 rounded-full flex items-center justify-center text-green-500 shadow-inner">
                    <CheckCircle className="w-12 h-12" />
                  </div>
                  <div className="space-y-2">
                    <h3 className="text-3xl font-black text-secondary">Demo Booked</h3>
                    <p className="text-slate-500 text-base max-w-md mx-auto leading-relaxed">
                      Thank you, <span className="font-bold text-primary">{formData.name}</span>. Our expert tech engineer will contact you on <span className="font-bold text-secondary">{formData.mobile}</span> ({formData.email}) for your demo scheduled on <span className="font-bold text-secondary">{formData.preferredDate}</span>.
                    </p>
                  </div>

                  <button
                    onClick={() => {
                      setSubmitted(false);
                      setFormData({ name: '', businessName: '', mobile: '', email: '', preferredDate: todayStr, city: '', message: '' });
                      setErrors({ name: '', businessName: '', mobile: '', email: '', preferredDate: '', city: '', message: '' });
                    }}
                    className="text-slate-400 hover:text-slate-600 text-xs font-semibold underline transition-colors pt-2"
                  >
                    Fill Form Again
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Right Side: SaaS Contact Sidebar */}
          <div className="md:col-span-5 bg-secondary text-white p-8 md:p-10 rounded-3xl shadow-2xl flex flex-col justify-between text-left relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 rounded-full blur-2xl pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-24 h-24 bg-white/5 rounded-full blur-xl pointer-events-none" />

            <div className="space-y-8 relative z-10">
              <div>
                <h3 className="text-2xl font-black tracking-tight mb-2 text-white">We're Here.</h3>
                <p className="text-slate-400 text-sm">Have urgent queries? Contact BillJi support.</p>
              </div>

              <ul className="space-y-5 text-sm">
                <li className="flex items-start space-x-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center text-primary shrink-0">
                    <Phone className="w-5 h-5" />
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider block">Call Sales Support</span>
                    <a href="tel:+919409111116" className="hover:text-primary font-semibold text-white transition-colors block mt-0.5">+91 94091 11116 / +91 99747 23326</a>
                  </div>
                </li>
                <li className="flex items-start space-x-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center text-primary shrink-0">
                    <Mail className="w-5 h-5" />
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider block">Email Inquiries</span>
                    <a href="mailto:billji.support@gmail.com" className="hover:text-primary font-semibold text-white transition-colors block mt-0.5">billji.support@gmail.com</a>
                  </div>
                </li>
                <li className="flex items-start space-x-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center text-primary shrink-0">
                    <MapPin className="w-5 h-5" />
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider block">Main HQ Address</span>
                    <span className="text-slate-300 block mt-0.5">104 Hindva Pride,Amar Jawan Circle Nikol , Ahmedabad, Gujarat - 382350</span>
                  </div>
                </li>
                <li className="flex items-start space-x-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center text-primary shrink-0">
                    <Clock className="w-5 h-5" />
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider block">Business Hours</span>
                    <span className="text-slate-300 block mt-0.5">Mon - Sat: 9:00 AM to 6:00 PM IST</span>
                  </div>
                </li>
              </ul>

              <div className="mt-8 pt-6 border-t border-slate-800 relative z-10">
                <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider block mb-3.5">Office Map Location</span>
                <div className="w-full h-44 bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden relative shadow-inner">
                  <iframe
                    src="https://maps.google.com/maps?q=104%20Hindva%20Pride,%20Amar%20Jawan%20Circle%20Nikol,%20Ahmedabad,%20Gujarat%20-%20382350&t=&z=16&ie=UTF8&iwloc=&output=embed"
                    width="100%"
                    height="100%"
                    style={{ border: 0 }}
                    allowFullScreen=""
                    loading="lazy"
                    title="BillJi Office Map Location"
                    className="grayscale opacity-90 contrast-125 hover:grayscale-0 transition-all duration-300"
                  ></iframe>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-800 flex justify-between items-center relative z-10">
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Social Channels</span>
              <div className="flex space-x-3">
                <a href="https://www.facebook.com/profile.php?id=61589825966944" target="_blank" rel="noreferrer" className="w-7 h-7 rounded-lg bg-slate-800 hover:bg-primary text-slate-300 hover:text-white flex items-center justify-center transition-all duration-300">
                  <FacebookIcon className="w-3.5 h-3.5" />
                </a>
                <a href="https://x.com/GoalScripture" target="_blank" rel="noreferrer" className="w-7 h-7 rounded-lg bg-slate-800 hover:bg-primary text-slate-300 hover:text-white flex items-center justify-center transition-all duration-300">
                  <TwitterIcon className="w-3.5 h-3.5" />
                </a>
                <a href="https://www.instagram.com/goal_scripture/" target="_blank" rel="noreferrer" className="w-7 h-7 rounded-lg bg-slate-800 hover:bg-primary text-slate-300 hover:text-white flex items-center justify-center transition-all duration-300">
                  <InstagramIcon className="w-3.5 h-3.5" />
                </a>
                <a href="https://www.linkedin.com/company/goal-scripture" target="_blank" rel="noreferrer" className="w-7 h-7 rounded-lg bg-slate-800 hover:bg-primary text-slate-300 hover:text-white flex items-center justify-center transition-all duration-300">
                  <LinkedinIcon className="w-3.5 h-3.5" />
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
