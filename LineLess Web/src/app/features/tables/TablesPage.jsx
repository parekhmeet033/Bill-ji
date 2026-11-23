import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Plus } from 'lucide-react';
import { fetchPendingTables } from './tablesApi';
import { fetchSettings } from '../settings/settingsApi';
import { useApiQuery } from '../../core/useApiQuery';
import { useRealtime } from '../../core/useRealtime';
import { PageHeader, Card, Loader, ErrorState } from '../../components/ui';

const money = (v) => `₹${Number(v || 0).toFixed(2)}`;

function formatDuration(startTime) {
  if (!startTime) return 'Active';
  const start = new Date(startTime).getTime();
  if (isNaN(start)) return 'Active';

  const diffMins = Math.floor((Date.now() - start) / 60000);
  if (diffMins < 0) return '0m';
  if (diffMins < 60) return `${diffMins}m`;
  return `${Math.floor(diffMins / 60)}h ${diffMins % 60}m`;
}

export default function TablesPage() {
  const { data: tables, loading, error, refetch } = useApiQuery(fetchPendingTables, []);
  const { data: settings } = useApiQuery(fetchSettings, []);
  const navigate = useNavigate();
  useRealtime(refetch);

  // Force re-render every minute for the time elapsed counter
  const [, setTick] = useState(0);
  useEffect(() => {
    const timer = setInterval(() => setTick((t) => t + 1), 60000);
    return () => clearInterval(timer);
  }, []);

  const count = Number(settings?.number_of_tables) || 0;
  const byNo = {};
  (tables || []).forEach((t) => { byNo[Number(t.table_no)] = t; });
  const tableNumbers = count > 0
    ? Array.from({ length: count }, (_, i) => i + 1)
    : (tables || []).map((t) => Number(t.table_no));

  return (
    <>
      <PageHeader
        title="Tables & POS"
        subtitle="Dine-in tables and takeaway POS"
        action={
          <Link to="/app/pos" className="flex items-center gap-2 rounded-full bg-primary px-4 py-2.5 text-sm font-bold text-white hover:bg-primary-dark">
            <Plus className="h-4 w-4" /> New takeaway
          </Link>
        }
      />

      {loading ? <Loader /> : error ? <ErrorState error={error} onRetry={refetch} /> : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
          {tableNumbers.map((n) => {
            const t = byNo[n];
            const occupied = t && Number(t.total_amount) > 0;
            // Get created_at from the first item if available
            const createdAt = t?.items?.[0]?.created_at || t?.created_at;

            return (
              <button
                key={n}
                onClick={() => navigate(`/app/tables/${n}`)}
                className={`relative flex h-28 flex-col items-center justify-center rounded-2xl border p-3 text-center transition-colors ${
                  occupied ? 'border-green-200 bg-green-50 hover:bg-green-100' : 'border-slate-200 bg-white hover:border-primary'
                }`}
              >
                <span className="text-xs font-bold uppercase tracking-wide text-slate-400">Table</span>
                <span className="text-2xl font-black">{n}</span>
                {occupied ? (
                  <>
                    <span className="mt-1 text-sm font-bold text-green-600">{money(t.total_amount)}</span>
                    <span className="absolute bottom-2 right-2 rounded bg-green-600 px-1.5 py-0.5 text-[10px] font-bold text-white">
                      {formatDuration(createdAt)}
                    </span>
                  </>
                ) : (
                  <span className="mt-1 text-xs font-semibold text-slate-400">Empty</span>
                )}
              </button>
            );
          })}
          {tableNumbers.length === 0 && <Card className="col-span-full"><p className="py-10 text-center text-sm text-slate-400">No tables configured.</p></Card>}
        </div>
      )}
    </>
  );
}
