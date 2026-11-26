import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Save, Store, Grid, Utensils, Hash, Bell, Volume2, Printer, Key, Monitor, Send, HelpCircle, Info, LogOut, Sparkles, Globe, CreditCard, Gift, Sun, Moon, Laptop, Minus, Plus, CheckCircle2, X, ChevronRight } from 'lucide-react';
import { fetchSettings, saveSettings } from './settingsApi';
import { useApiQuery } from '../../core/useApiQuery';
import { PageHeader, Card, Loader, ErrorState } from '../../components/ui';
import { useAuth } from '../../auth/AuthContext';
import { clearSession } from '../../auth/authStorage';
import { applyTheme } from '../../../utils/theme';

const hhmm = (t) => (t ? String(t).slice(0, 5) : ''); // '09:00:00' → '09:00'
const isOn = (s) => s === 1 || s === '1' || s === true;

// Custom Switch component
function CustomSwitch({ checked, onChange, label, description, icon: Icon, activeColor = 'bg-primary' }) {
  return (
    <div className="flex items-center justify-between gap-4 py-3">
      <div className="flex items-start gap-3">
        {Icon && <Icon className="mt-0.5 h-5 w-5 shrink-0 text-primary" />}
        <div>
          <p className="text-sm font-bold text-slate-700">{label}</p>
          {description && <p className="text-xs text-slate-400">{description}</p>}
        </div>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${checked ? activeColor : 'bg-slate-200'}`}
      >
        <span className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${checked ? 'translate-x-5' : 'translate-x-0'}`} />
      </button>
    </div>
  );
}

export default function SettingsPage() {
  const { data, loading, error, refetch } = useApiQuery(fetchSettings, []);
  const navigate = useNavigate();
  const [form, setForm] = useState(null);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');
  const [feedback, setFeedback] = useState('');

  // Local storage preferences
  const [localPrefs, setLocalPrefs] = useState({
    theme: localStorage.getItem('billji_theme') || 'system',
    alertTone: localStorage.getItem('billji_alert_tone') !== 'false',
    notifications: localStorage.getItem('billji_notifications') !== 'false',
    kdsEnabled: localStorage.getItem('billji_kds_enabled') !== 'false',
  });

  useEffect(() => {
    if (data) {
      setForm({
        shop_open: isOn(data.shop_open) ? 1 : 0,
        category_display: isOn(data.category_display) ? 1 : 0,
        opration_mode_status: data.opration_mode_status || 'both',
        generated_code: data.generated_code || '',

        gst_enabled: isOn(data.gst_enabled) ? 1 : 0,
        gstin: data.gstin || '',
        legal_business_name: data.legal_business_name || '',
        business_address: data.business_address || '',
        state: data.state || '',
        state_code: data.state_code || '',

        number_of_tables: data.number_of_tables ?? 10,
        morning_start: hhmm(data.morning_start), morning_end: hhmm(data.morning_end),
        afternoon_start: hhmm(data.afternoon_start), afternoon_end: hhmm(data.afternoon_end),
        evening_start: hhmm(data.evening_start), evening_end: hhmm(data.evening_end),
      });
    }
  }, [data]);

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));
  const updateVal = (k, v) => setForm((f) => ({ ...f, [k]: v }));
  const toggle = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.checked ? 1 : 0 }));

  const updateLocal = (k, v) => {
    setLocalPrefs(p => ({ ...p, [k]: v }));
    localStorage.setItem(`billji_${k.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`)}`, v);
    if (k === 'theme') {
      applyTheme(v);
    }
  };

  const submit = async (e) => {
    e.preventDefault();
    setSaving(true); setMsg('');
    try {
      await saveSettings(form);
      setMsg('Settings saved successfully!');
      refetch();
    } catch (e2) {
      setMsg(e2?.message || 'Failed to save settings.');
    } finally {
      setSaving(false);
      setTimeout(() => setMsg(''), 3000);
    }
  };

  const { logout } = useAuth();

  const handleLogout = async () => {
    if (window.confirm("Are you sure you want to logout from the portal?")) {
      await logout();
      navigate('/login', { replace: true });
    }
  };

  const generateCode = async () => {
    const code = Array.from({ length: 6 }, () => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[Math.floor(Math.random() * 36)]).join('');
    const updated = { ...form, generated_code: code };
    setForm(updated);
    try {
      await saveSettings(updated);
      setMsg('POS Link code generated!');
      setTimeout(() => setMsg(''), 3000);
    } catch (e) {
      setMsg('Failed to save code.');
    }
  };

  const clearCode = async (e) => {
    e.stopPropagation();
    const updated = { ...form, generated_code: '' };
    setForm(updated);
    try {
      await saveSettings(updated);
      setMsg('POS Link code cleared!');
      setTimeout(() => setMsg(''), 3000);
    } catch (e) {
      setMsg('Failed to clear code.');
    }
  };

  if (loading || !form) return <><PageHeader title="Settings" /><Loader /></>;
  if (error) return <><PageHeader title="Settings" /><ErrorState error={error} onRetry={refetch} /></>;

  const field = (label, k, type = 'text') => (
    <label className="text-xs font-bold text-slate-600">{label}
      <input type={type} value={form[k]} onChange={set(k)} className="mt-1 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm outline-none focus:border-primary focus:bg-white" />
    </label>
  );

  return (
    <>
      <PageHeader title="Settings" subtitle="Manage your application preferences" />
      <div className="mx-auto max-w-4xl pb-12">
        <form onSubmit={submit} className="space-y-6">

          {/* Shop Status */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">Shop Status</h2>
            <Card className="p-0">
              <div className="divide-y divide-slate-100 px-4">
                <CustomSwitch
                  icon={Store}
                  label="Shop On/Off"
                  description={form.shop_open ? "Shop is currently accepting orders" : "Shop is currently closed"}
                  checked={!!form.shop_open}
                  onChange={(v) => updateVal('shop_open', v ? 1 : 0)}
                />
                <CustomSwitch
                  icon={Grid}
                  label="Category Display"
                  description="Show or hide categories in menu"
                  checked={!!form.category_display}
                  onChange={(v) => updateVal('category_display', v ? 1 : 0)}
                />
              </div>
            </Card>
          </div>

          {/* Operating Timing */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">Operating Timing</h2>
            <Card>
              <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                {field('Morning start', 'morning_start', 'time')}
                {field('Morning end', 'morning_end', 'time')}
                {field('Afternoon start', 'afternoon_start', 'time')}
                {field('Afternoon end', 'afternoon_end', 'time')}
                {field('Evening start', 'evening_start', 'time')}
                {field('Evening end', 'evening_end', 'time')}
              </div>
            </Card>
          </div>

          {/* Restaurant Mode */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">Restaurant Mode</h2>
            <Card className="p-0">
              <div className="p-4">
                <div className="flex items-center gap-3">
                  <Utensils className="h-5 w-5 text-primary" />
                  <div>
                    <p className="text-sm font-bold text-slate-700">Operation Mode</p>
                    <p className="text-xs text-slate-400">Choose how you serve customers</p>
                  </div>
                </div>
                <div className="mt-4 flex gap-2">
                  {['take_away', 'dine_in', 'both'].map(mode => (
                    <button
                      key={mode}
                      type="button"
                      onClick={() => updateVal('opration_mode_status', mode)}
                      className={`flex-1 rounded-xl py-2.5 text-xs font-bold capitalize transition-colors ${form.opration_mode_status === mode ? 'bg-primary text-white' : 'bg-slate-100 text-slate-500 hover:bg-slate-200'}`}
                    >
                      {mode.replace('_', '-')}
                    </button>
                  ))}
                </div>
              </div>

              {form.opration_mode_status !== 'take_away' && (
                <div className="flex items-center justify-between border-t border-slate-100 p-4">
                  <div className="flex items-center gap-3">
                    <Hash className="h-5 w-5 text-primary" />
                    <div>
                      <p className="text-sm font-bold text-slate-700">Number of Tables</p>
                      <p className="text-xs text-slate-400">Configure your floor layout</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <button type="button" onClick={() => updateVal('number_of_tables', Math.max(1, form.number_of_tables - 1))} className="flex h-8 w-8 items-center justify-center rounded-full bg-red-50 text-red-500 hover:bg-red-100">
                      <Minus size={16} />
                    </button>
                    <input
                      type="number"
                      value={form.number_of_tables}
                      onChange={(e) => updateVal('number_of_tables', Math.max(1, parseInt(e.target.value) || 1))}
                      className="w-12 text-center text-lg font-black outline-none"
                    />
                    <button type="button" onClick={() => updateVal('number_of_tables', form.number_of_tables + 1)} className="flex h-8 w-8 items-center justify-center rounded-full bg-green-50 text-green-600 hover:bg-green-100">
                      <Plus size={16} />
                    </button>
                  </div>
                </div>
              )}
            </Card>
          </div>

          {/* GST Settings */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">GST Configuration</h2>
            <Card>
              <label className="mb-4 flex items-center gap-2 text-sm font-semibold text-slate-700">
                <input type="checkbox" checked={!!form.gst_enabled} onChange={toggle('gst_enabled')} className="h-4 w-4 rounded border-slate-300 text-primary focus:ring-primary" />
                Enable GST features
              </label>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                {field('GSTIN', 'gstin')}
                {field('Legal business name', 'legal_business_name')}
                {field('Business address', 'business_address')}
                {field('State', 'state')}
                {field('State code', 'state_code')}
              </div>
            </Card>
          </div>

          {/* Appearance */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">Appearance</h2>
            <Card className="p-0">
              <div className="divide-y divide-slate-100 px-4">
                <div className="flex cursor-pointer items-center justify-between py-3" onClick={() => updateLocal('theme', 'light')}>
                  <div className="flex items-center gap-3">
                    <Sun className={`h-5 w-5 ${localPrefs.theme === 'light' ? 'text-primary' : 'text-slate-400'}`} />
                    <p className={`text-sm font-bold ${localPrefs.theme === 'light' ? 'text-slate-900' : 'text-slate-600'}`}>Light Mode</p>
                  </div>
                  {localPrefs.theme === 'light' && <CheckCircle2 className="h-5 w-5 text-primary" />}
                </div>
                <div className="flex cursor-pointer items-center justify-between py-3" onClick={() => updateLocal('theme', 'dark')}>
                  <div className="flex items-center gap-3">
                    <Moon className={`h-5 w-5 ${localPrefs.theme === 'dark' ? 'text-primary' : 'text-slate-400'}`} />
                    <p className={`text-sm font-bold ${localPrefs.theme === 'dark' ? 'text-slate-900' : 'text-slate-600'}`}>Dark Mode</p>
                  </div>
                  {localPrefs.theme === 'dark' && <CheckCircle2 className="h-5 w-5 text-primary" />}
                </div>
                <div className="flex cursor-pointer items-center justify-between py-3" onClick={() => updateLocal('theme', 'system')}>
                  <div className="flex items-center gap-3">
                    <Laptop className={`h-5 w-5 ${localPrefs.theme === 'system' ? 'text-primary' : 'text-slate-400'}`} />
                    <p className={`text-sm font-bold ${localPrefs.theme === 'system' ? 'text-slate-900' : 'text-slate-600'}`}>System Default</p>
                  </div>
                  {localPrefs.theme === 'system' && <CheckCircle2 className="h-5 w-5 text-primary" />}
                </div>
              </div>
            </Card>
          </div>

          {/* Alert Settings */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">Alert Settings</h2>
            <Card className="p-0">
              <div className="divide-y divide-slate-100 px-4">
                <CustomSwitch
                  icon={Bell}
                  label="Push Notifications"
                  description="Receive updates for new orders"
                  checked={localPrefs.notifications}
                  onChange={(v) => updateLocal('notifications', v)}
                />
                <CustomSwitch
                  icon={Volume2}
                  label="Alert Tone"
                  description="Play sound when new order arrives"
                  checked={localPrefs.alertTone}
                  onChange={(v) => updateLocal('alertTone', v)}
                />
              </div>
            </Card>
          </div>

          {/* Printer Settings */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">Printer Settings</h2>
            <Card className="flex flex-col gap-4">
              <div className="flex items-center justify-between rounded-xl border border-slate-100 p-4">
                <div className="flex items-center gap-3">
                  <Printer className="h-5 w-5 text-primary" />
                  <div>
                    <p className="text-sm font-bold text-slate-700">Browser Printing</p>
                    <p className="text-xs text-slate-400">Handled automatically via browser print dialog</p>
                  </div>
                </div>
                <span className="rounded bg-green-50 px-2 py-1 text-xs font-bold text-green-600">Active</span>
              </div>
            </Card>
          </div>

          {/* App Configuration */}
          <div>
            <h2 className="mb-2 pl-1 text-[15px] font-bold">App Configuration</h2>
            <Card className="p-0">
              <div className="divide-y divide-slate-100 px-4">
                <div
                  className="flex cursor-pointer items-center justify-between py-4"
                  onClick={generateCode}
                >
                  <div className="flex items-center gap-3">
                    <Key className="h-5 w-5 text-primary" />
                    <div>
                      <p className="text-sm font-bold text-slate-700">POS Link Code</p>
                      <p className="text-xs font-bold tracking-widest text-primary">{form.generated_code || 'Tap to generate code'}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {form.generated_code && (
                      <button
                        onClick={clearCode}
                        className="rounded-full bg-red-50 p-1.5 text-red-500 hover:bg-red-100"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    )}
                    <button className="rounded-full bg-primary/10 p-1.5 text-primary hover:bg-primary/20">
                      <Monitor className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                <CustomSwitch
                  icon={Monitor}
                  label="Kitchen Display System (KDS)"
                  description="Show or hide the kitchen tab"
                  checked={localPrefs.kdsEnabled}
                  onChange={(v) => updateLocal('kdsEnabled', v)}
                />
              </div>
            </Card>
          </div>

          <div className="flex items-center gap-3 pt-2">
            <button type="submit" disabled={saving} className="flex items-center gap-2 rounded-full bg-primary px-8 py-3.5 text-sm font-bold text-white shadow-lg hover:bg-primary-dark disabled:opacity-60">
              <Save className="h-4 w-4" /> {saving ? 'Saving…' : 'SAVE SETTINGS'}
            </button>
            {msg && <span className="text-sm font-semibold text-slate-500">{msg}</span>}
          </div>
        </form>

        {/* Suggestion & Feedback */}
        <div className="mt-8">
          <h2 className="mb-2 pl-1 text-[15px] font-bold">Suggestion & Feedback</h2>
          <Card>
            <textarea
              value={feedback}
              onChange={e => setFeedback(e.target.value)}
              placeholder="Share your suggestions or feedback here..."
              className="w-full resize-none rounded-xl border border-slate-200 bg-slate-50 p-3 text-sm outline-none focus:border-primary focus:bg-white"
              rows={3}
            />
            <button
              onClick={() => { if (feedback.trim()) { setFeedback(''); alert('Thank you for your feedback!'); } }}
              className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl bg-primary py-2.5 text-sm font-bold text-white hover:bg-primary-dark"
            >
              <Send className="h-4 w-4" /> SUBMIT FEEDBACK
            </button>
          </Card>
        </div>

        {/* About Section */}
        <div className="mt-8">
          <h2 className="mb-2 pl-1 text-[15px] font-bold">About</h2>
          <Card className="overflow-hidden p-0">
            <div className="divide-y divide-slate-100 dark:divide-slate-800">
              <div
                onClick={() => navigate('/app/support')}
                className="group flex cursor-pointer items-center justify-between p-4 transition-all duration-200 hover:bg-slate-50 dark:hover:bg-slate-800/60"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/10 text-primary transition-all duration-200 group-hover:scale-105 group-hover:bg-primary group-hover:text-white">
                    <HelpCircle className="h-5 w-5" />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-slate-800 transition-colors group-hover:text-primary dark:text-slate-100">
                      Contact &amp; Support
                    </p>
                    <p className="text-xs text-slate-400">Get help, reach our team &amp; send message</p>
                  </div>
                </div>
                <span className="flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1 text-xs font-bold text-primary transition-all duration-200 group-hover:bg-primary group-hover:text-white">
                  Contact Us <ChevronRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
                </span>
              </div>
              <div className="flex items-center justify-between p-4">
                <div className="flex items-center gap-3">
                  <Info className="h-5 w-5 text-primary" />
                  <p className="text-sm font-bold text-slate-700 dark:text-slate-300">Version</p>
                </div>
                <p className="text-xs font-semibold text-slate-400">1.0.1</p>
              </div>
            </div>
          </Card>
        </div>

        {/* Logout */}
        <div className="mt-8 flex justify-center pb-8">
          <button onClick={handleLogout} className="flex items-center gap-2 text-sm font-bold tracking-wide text-red-500 hover:text-red-600">
            <LogOut className="h-4 w-4" /> LOGOUT FROM PORTAL
          </button>
        </div>

        {/* Upcoming Features */}
        <div className="pt-4">
          <div className="mb-4 flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-amber-500" />
            <h2 className="text-[13px] font-bold uppercase tracking-widest text-slate-400">Upcoming Features</h2>
          </div>
          <div className="space-y-3 pl-1">
            <div className="flex items-center gap-3 text-slate-500">
              <Globe className="h-4 w-4 opacity-60" />
              <span className="text-sm font-medium opacity-80">Language (Gujarati, Hindi, English)</span>
            </div>
            <div className="flex items-center gap-3 text-slate-500">
              <CreditCard className="h-4 w-4 opacity-60" />
              <span className="text-sm font-medium opacity-80">Online Order Payment Integration</span>
            </div>
            <div className="flex items-center gap-3 text-slate-500">
              <Gift className="h-4 w-4 opacity-60" />
              <span className="text-sm font-medium opacity-80">Customer Loyalty & Rewards</span>
            </div>
          </div>
        </div>

      </div>
    </>
  );
}
