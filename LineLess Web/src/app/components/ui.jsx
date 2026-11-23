import { Loader2, AlertTriangle, Rocket } from 'lucide-react';

export function PageHeader({ title, subtitle, action }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="text-2xl font-black tracking-tight">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-slate-500">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function Card({ children, className = '' }) {
  return (
    <div className={`rounded-2xl border border-slate-100 bg-white p-5 shadow-sm ${className}`}>
      {children}
    </div>
  );
}

export function StatCard({ label, value, icon: Icon, accent = 'text-primary' }) {
  return (
    <Card className="flex items-center justify-between">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{label}</p>
        <p className="mt-1 text-2xl font-black">{value}</p>
      </div>
      {Icon && (
        <div className={`flex h-11 w-11 items-center justify-center rounded-xl bg-slate-50 ${accent}`}>
          <Icon className="h-5 w-5" />
        </div>
      )}
    </Card>
  );
}

export function Loader({ label = 'Loading…' }) {
  return (
    <div className="flex items-center justify-center gap-2 py-16 text-slate-400">
      <Loader2 className="h-5 w-5 animate-spin" />
      <span className="text-sm font-medium">{label}</span>
    </div>
  );
}

export function ErrorState({ error, onRetry }) {
  return (
    <Card className="flex flex-col items-center gap-3 py-12 text-center">
      <AlertTriangle className="h-8 w-8 text-amber-500" />
      <p className="text-sm font-semibold text-slate-600">
        {error?.message || 'Something went wrong.'}
      </p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="rounded-full bg-primary px-5 py-2 text-sm font-bold text-white hover:bg-primary-dark"
        >
          Try again
        </button>
      )}
    </Card>
  );
}

// Clean, consistent placeholder for modules that are scaffolded but not yet
// wired to the backend. Keeps the shell fully navigable.
export function ComingSoon({ title, note }) {
  return (
    <Card className="flex flex-col items-center gap-3 py-16 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
        <Rocket className="h-6 w-6" />
      </div>
      <h2 className="text-lg font-bold">{title}</h2>
      <p className="max-w-md text-sm text-slate-500">
        {note || 'This module is scaffolded and will be wired to the backend next.'}
      </p>
    </Card>
  );
}
