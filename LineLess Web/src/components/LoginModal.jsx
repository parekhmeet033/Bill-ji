import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, KeyRound, Store, ShieldAlert, ArrowRight, CheckCircle2, Eye, EyeOff } from 'lucide-react';
import { validateEmail } from '../utils/validation';

export default function LoginModal({ isOpen, onClose }) {
  const [loginMode, setLoginMode] = useState('pos'); // 'pos' or 'owner'
  const [pin, setPin] = useState(['', '', '', '', '', '']);
  const [pinError, setPinError] = useState('');
  const [email, setEmail] = useState('');
  const [emailError, setEmailError] = useState('');
  const [password, setPassword] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  if (!isOpen) return null;

  const handlePinChange = (index, value) => {
    // Restrict PIN digits to numbers only
    const digit = value.replace(/\D/g, '');
    const char = digit.length > 0 ? digit[digit.length - 1] : '';

    const newPin = [...pin];
    newPin[index] = char;
    setPin(newPin);

    if (pinError) setPinError('');

    // Auto-focus next input field
    if (char && index < 5) {
      const nextInput = document.getElementById(`modal-pin-${index + 1}`);
      if (nextInput) nextInput.focus();
    }
  };

  const handleKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !pin[index] && index > 0) {
      const prevInput = document.getElementById(`modal-pin-${index - 1}`);
      if (prevInput) prevInput.focus();
    }
  };

  const handleEmailChange = (val) => {
    setEmail(val);
    const err = validateEmail(val);
    setEmailError(err || '');
  };

  const handleLoginSubmit = (e) => {
    e.preventDefault();

    if (loginMode === 'pos') {
      const fullPin = pin.join('');
      if (fullPin.length < 6) {
        setPinError('Please enter a 6-digit PIN.');
        return;
      }
    } else {
      const err = validateEmail(email);
      if (err) {
        setEmailError(err);
        return;
      }
      if (!password) {
        setPasswordError('Password is required.');
        return;
      }
    }

    setIsSuccess(true);
    setTimeout(() => {
      setIsSuccess(false);
      onClose();
    }, 1800);
  };

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
            className="relative w-full max-w-md bg-white rounded-3xl shadow-2xl border border-slate-100 overflow-y-auto z-10 my-auto max-h-[92vh] flex flex-col"
          >
            <button
              onClick={onClose}
              className="absolute top-5 right-5 p-2 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-500 transition-colors z-20"
              aria-label="Close"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Modal Header */}
            <div className="p-6 pb-4 text-center">
              <div className="w-12 h-12 bg-primary/10 text-primary rounded-2xl flex items-center justify-center mx-auto mb-3">
                <Store className="w-6 h-6" />
              </div>
              <h3 className="text-2xl font-black text-secondary">BillJi Platform Login</h3>
              <p className="text-slate-500 text-xs mt-1">Access Smart POS Terminal & Owner Dashboard</p>

              {/* Mode Toggle Switcher */}
              <div className="flex bg-slate-100 p-1 rounded-2xl mt-5">
                <button
                  type="button"
                  onClick={() => setLoginMode('pos')}
                  className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                    loginMode === 'pos'
                      ? 'bg-white text-secondary shadow-sm'
                      : 'text-slate-500 hover:text-secondary'
                  }`}
                >
                  GO POS Terminal (PIN)
                </button>
                <button
                  type="button"
                  onClick={() => setLoginMode('owner')}
                  className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                    loginMode === 'owner'
                      ? 'bg-white text-secondary shadow-sm'
                      : 'text-slate-500 hover:text-secondary'
                  }`}
                >
                  Owner Dashboard
                </button>
              </div>
            </div>

            {/* Login Content */}
            <div className="p-6 pt-2">
              {isSuccess ? (
                <div className="py-8 text-center space-y-3">
                  <div className="w-14 h-14 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto animate-bounce">
                    <CheckCircle2 className="w-8 h-8" />
                  </div>
                  <h4 className="text-xl font-bold text-secondary">Authentication Verified!</h4>
                  <p className="text-slate-500 text-xs">Redirecting to BillJi Restaurant OS...</p>
                </div>
              ) : loginMode === 'pos' ? (
                /* POS PIN Terminal Form */
                <form onSubmit={handleLoginSubmit} className="space-y-5" noValidate>
                  <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100 text-center">
                    <div className="flex items-center justify-center space-x-1.5 text-xs font-bold text-slate-600 mb-3">
                      <KeyRound className="w-4 h-4 text-primary" />
                      <span>Enter 6-Digit Staff / POS PIN</span>
                    </div>

                    <div className="flex justify-center space-x-2">
                      {pin.map((digit, idx) => (
                        <input
                          key={idx}
                          id={`modal-pin-${idx}`}
                          type="password"
                          maxLength={1}
                          value={digit}
                          onChange={(e) => handlePinChange(idx, e.target.value)}
                          onKeyDown={(e) => handleKeyDown(idx, e)}
                          className={`w-10 h-12 text-center text-lg font-bold bg-white border rounded-xl focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all ${
                            pinError ? 'border-red-500' : 'border-slate-200'
                          }`}
                        />
                      ))}
                    </div>
                    {pinError && <p className="text-red-500 text-xs font-semibold mt-2">{pinError}</p>}
                    <p className="text-[10px] text-slate-400 mt-2">
                      Default POS Staff PIN: <span className="font-mono text-slate-600 font-bold">123456</span>
                    </p>
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-3.5 rounded-2xl shadow-lg hover:shadow-primary/20 transition-all flex items-center justify-center space-x-2"
                  >
                    <span>Launch POS Terminal</span>
                    <ArrowRight className="w-4 h-4" />
                  </button>
                </form>
              ) : (
                /* Owner Email / Password Form */
                <form onSubmit={handleLoginSubmit} className="space-y-4" noValidate>
                  <div>
                    <label className="block text-xs font-bold text-slate-600 mb-1 text-left">Owner Email *</label>
                    <input
                      type="email"
                      placeholder="owner@restaurant.com"
                      value={email}
                      onChange={(e) => handleEmailChange(e.target.value)}
                      className={`w-full px-4 py-3 border rounded-2xl text-sm focus:outline-none transition-colors ${
                        emailError ? 'border-red-500 bg-red-50/10' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                      }`}
                    />
                    {emailError && <p className="text-red-500 text-xs font-semibold mt-1 text-left">{emailError}</p>}
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-600 mb-1 text-left">Master Password *</label>
                    <div className="relative">
                      <input
                        type={showPassword ? 'text' : 'password'}
                        placeholder="••••••••••••"
                        value={password}
                        onChange={(e) => {
                          setPassword(e.target.value);
                          if (passwordError) setPasswordError('');
                        }}
                        className={`w-full px-4 py-3 pr-10 border rounded-2xl text-sm focus:outline-none transition-colors ${
                          passwordError ? 'border-red-500 bg-red-50/10' : 'bg-slate-50 border-slate-200 focus:border-primary focus:bg-white'
                        }`}
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword((prev) => !prev)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 rounded-lg p-1 text-slate-400 transition-colors hover:text-slate-600 focus:outline-none"
                        aria-label={showPassword ? 'Hide password' : 'Show password'}
                      >
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                    {passwordError && <p className="text-red-500 text-xs font-semibold mt-1 text-left">{passwordError}</p>}
                  </div>

                  <div className="flex justify-between items-center text-xs">
                    <label className="flex items-center space-x-2 text-slate-600 cursor-pointer">
                      <input type="checkbox" className="rounded text-primary focus:ring-primary" defaultChecked />
                      <span>Remember session</span>
                    </label>
                    <a href="#reset" className="text-primary font-semibold hover:underline">Forgot?</a>
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-secondary hover:bg-secondary-light text-white font-bold py-3.5 rounded-2xl shadow-lg transition-all flex items-center justify-center space-x-2"
                  >
                    <span>Open Owner Dashboard</span>
                    <ArrowRight className="w-4 h-4" />
                  </button>
                </form>
              )}

              <div className="mt-5 text-center pt-3 border-t border-slate-100">
                <span className="text-[11px] text-slate-400 flex items-center justify-center space-x-1">
                  <ShieldAlert className="w-3.5 h-3.5 text-primary" />
                  <span>256-bit Encrypted Session</span>
                </span>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
