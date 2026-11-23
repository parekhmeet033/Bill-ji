import { useState } from 'react';
import { useNavigate, useLocation, Link, Navigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Store, Mail, Lock, ArrowRight, Loader2, ShieldCheck, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../app/auth/AuthContext';
import { validateEmail } from '../utils/validation';

// Vendor login page. Authenticates against the same backend the mobile app
// uses, so vendors sign in with their existing credentials.
export default function Login() {
  const { isAuthenticated, login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const redirectTo = location.state?.from || '/app';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [fieldErr, setFieldErr] = useState({});
  const [formErr, setFormErr] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (isAuthenticated) return <Navigate to={redirectTo} replace />;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setFormErr('');
    const errs = {};
    const emailErr = validateEmail(email);
    if (emailErr) errs.email = emailErr;
    if (!password) errs.password = 'Password is required.';
    setFieldErr(errs);
    if (Object.keys(errs).length) return;

    setSubmitting(true);
    try {
      await login(email, password);
      navigate(redirectTo, { replace: true });
    } catch (err) {
      setFormErr(err?.message || 'Login failed. Please check your credentials.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-10">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md rounded-3xl border border-slate-100 bg-white p-8 shadow-xl"
      >
        <Link to="/" className="mb-6 flex items-center justify-center gap-2">
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/10 text-primary">
            <Store className="h-6 w-6" />
          </div>
          <span className="text-2xl font-black tracking-tight text-secondary">BillJi</span>
        </Link>

        <h1 className="text-center text-xl font-black text-secondary">Vendor sign in</h1>
        <p className="mt-1 text-center text-xs text-slate-500">
          Use the same email &amp; password as the BillJi mobile app.
        </p>

        {formErr && (
          <div className="mt-5 rounded-xl border border-red-100 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-600">
            {formErr}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-6 space-y-4" noValidate>
          <div>
            <label className="mb-1 block text-xs font-bold text-slate-600">Email</label>
            <div className="relative">
              <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="email"
                autoFocus
                value={email}
                onChange={(e) => { setEmail(e.target.value); setFieldErr((p) => ({ ...p, email: '' })); }}
                placeholder="owner@restaurant.com"
                className={`w-full rounded-2xl border bg-slate-50 py-3 pl-10 pr-4 text-sm outline-none transition-colors focus:border-primary focus:bg-white ${
                  fieldErr.email ? 'border-red-400' : 'border-slate-200'
                }`}
              />
            </div>
            {fieldErr.email && <p className="mt-1 text-xs font-semibold text-red-500">{fieldErr.email}</p>}
          </div>

          <div>
            <label className="mb-1 block text-xs font-bold text-slate-600">Password</label>
            <div className="relative">
              <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => { setPassword(e.target.value); setFieldErr((p) => ({ ...p, password: '' })); }}
                placeholder="••••••••••••"
                className={`w-full rounded-2xl border bg-slate-50 py-3 pl-10 pr-10 text-sm outline-none transition-colors focus:border-primary focus:bg-white ${
                  fieldErr.password ? 'border-red-400' : 'border-slate-200'
                }`}
              />
              <button
                type="button"
                onClick={() => setShowPassword((prev) => !prev)}
                className="absolute right-3 top-1/2 -translate-y-1/2 rounded-lg p-1 text-slate-400 transition-colors hover:text-slate-600 focus:outline-none"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
            {fieldErr.password && <p className="mt-1 text-xs font-semibold text-red-500">{fieldErr.password}</p>}
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="flex w-full items-center justify-center gap-2 rounded-2xl bg-primary py-3.5 font-bold text-white shadow-lg transition-all hover:bg-primary-dark disabled:opacity-60"
          >
            {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <>Sign in <ArrowRight className="h-4 w-4" /></>}
          </button>
        </form>

        <p className="mt-5 flex items-center justify-center gap-1.5 text-[11px] text-slate-400">
          <ShieldCheck className="h-3.5 w-3.5 text-primary" /> Secure session · works on any device
        </p>
      </motion.div>
    </div>
  );
}
