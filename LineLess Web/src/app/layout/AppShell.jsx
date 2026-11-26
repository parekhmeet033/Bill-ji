import { useState } from 'react';
import { NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, UtensilsCrossed, ReceiptText, Table2,
  MonitorCog, BarChart3, Settings, LogOut, Menu, X, Store,
} from 'lucide-react';
import { useAuth } from '../auth/AuthContext';

const NAV = [
  { to: '/app', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/app/orders', label: 'Orders', icon: ReceiptText },
  { to: '/app/tables', label: 'Tables & POS', icon: Table2 },
  { to: '/app/menu', label: 'Menu', icon: UtensilsCrossed },
  { to: '/app/kds', label: 'Kitchen (KDS)', icon: MonitorCog },
  { to: '/app/reports', label: 'Reports', icon: BarChart3 },
  { to: '/app/settings', label: 'Settings', icon: Settings },
];

export default function AppShell() {
  const [open, setOpen] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  const SidebarLinks = ({ onNavigate }) => (
    <nav className="flex flex-col gap-1 px-3">
      {NAV.map(({ to, label, icon: Icon, end }) => (
        <NavLink
          key={to}
          to={to}
          end={end}
          onClick={onNavigate}
          className={({ isActive }) =>
            `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${
              isActive
                ? 'bg-primary text-white shadow-sm'
                : 'text-slate-600 hover:bg-slate-100 hover:text-secondary dark:text-slate-400 dark:hover:bg-slate-800/80 dark:hover:text-slate-100'
            }`
          }
        >
          <Icon className="h-4.5 w-4.5" style={{ width: 18, height: 18 }} />
          <span>{label}</span>
        </NavLink>
      ))}
    </nav>
  );

  const location = useLocation();
  const isSupport = location.pathname.startsWith('/app/support');

  return (
    <div className="min-h-screen bg-slate-50 text-secondary dark:bg-slate-950 dark:text-slate-100">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r border-slate-100 bg-white dark:border-slate-800 dark:bg-slate-900 lg:flex">
        <div className="flex items-center gap-2 px-6 py-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/10 text-primary">
            <Store className="h-5 w-5" />
          </div>
          <span className="text-lg font-black tracking-tight text-secondary dark:text-white">BillJi</span>
        </div>
        <div className="mt-2 flex-1 overflow-y-auto pb-4">
          <SidebarLinks />
        </div>
        <div className="border-t border-slate-100 p-3 dark:border-slate-800">
          <button
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold text-red-500 transition-colors hover:bg-red-50 dark:hover:bg-red-950/30"
          >
            <LogOut style={{ width: 18, height: 18 }} /> Sign out
          </button>
        </div>
      </aside>

      {/* Mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => setOpen(false)} />
          <aside className="absolute inset-y-0 left-0 flex w-72 max-w-[82%] flex-col border-r border-slate-100 bg-white shadow-2xl dark:border-slate-800 dark:bg-slate-900">
            <div className="flex items-center justify-between px-5 py-4">
              <span className="text-lg font-black text-secondary dark:text-white">BillJi</span>
              <button onClick={() => setOpen(false)} className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto pb-4">
              <SidebarLinks onNavigate={() => setOpen(false)} />
            </div>
            <div className="border-t border-slate-100 p-3 dark:border-slate-800">
              <button
                onClick={handleLogout}
                className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30"
              >
                <LogOut style={{ width: 18, height: 18 }} /> Sign out
              </button>
            </div>
          </aside>
        </div>
      )}

      {/* Main column */}
      <div className="lg:pl-64">
        {!isSupport && (
          <header className="sticky top-0 z-20 flex items-center justify-between border-b border-slate-100 bg-white/90 px-4 py-3 backdrop-blur dark:border-slate-800 dark:bg-slate-900/90 md:px-8">
            <button
              onClick={() => setOpen(true)}
              className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800 lg:hidden"
              aria-label="Open menu"
            >
              <Menu className="h-5 w-5" />
            </button>
            <div className="hidden lg:block" />
            <div className="flex items-center gap-3">
              <div className="text-right">
                <p className="text-sm font-bold leading-tight text-secondary dark:text-slate-100">{user?.name || 'Vendor'}</p>
                <p className="text-xs text-slate-400 leading-tight dark:text-slate-400">{user?.email || ''}</p>
              </div>
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-secondary text-sm font-bold text-white shadow-sm ring-2 ring-primary/20 dark:bg-slate-800 dark:text-white dark:border dark:border-slate-700">
                {(user?.name || 'V').charAt(0).toUpperCase()}
              </div>
            </div>
          </header>
        )}

        <main className={isSupport ? 'p-0 pb-12' : 'mx-auto max-w-7xl px-4 py-6 md:px-8'}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}
