import { useCallback, useState } from 'react';
import { IndianRupee, ShoppingBag, CalendarRange, Banknote, Smartphone, Wallet, XCircle } from 'lucide-react';
import { fetchReports } from './reportsApi';
import { fetchAllOrders } from '../orders/ordersApi';
import { useApiQuery } from '../../core/useApiQuery';
import { PageHeader, Card, StatCard, Loader, ErrorState } from '../../components/ui';
import Donut from '../../components/Donut';

const money = (v) => `₹${Number(v || 0).toFixed(2)}`;

const STATUS_COLORS = { pending: '#f59e0b', running: '#3b82f6', completed: '#22c55e', dispatched: '#64748b', cancelled: '#ef4444' };
const PAY_COLORS = { upi: '#FE701A', cash: '#22c55e', part_payment: '#8b5cf6', unpaid: '#cbd5e1' };

function Charts() {
  const { data: orders, loading } = useApiQuery(fetchAllOrders, []);
  if (loading) return null;
  const list = orders || [];

  const statusCounts = {};
  const payCounts = {};
  list.forEach((o) => {
    const s = String(o.status || '').toLowerCase();
    if (s) statusCounts[s] = (statusCounts[s] || 0) + 1;
    const p = String(o.payment_type || '').toLowerCase() || 'unpaid';
    payCounts[p] = (payCounts[p] || 0) + 1;
  });
  const statusSeg = Object.entries(statusCounts).map(([k, v]) => ({ label: k, value: v, color: STATUS_COLORS[k] || '#94a3b8' }));
  const paySeg = Object.entries(payCounts).map(([k, v]) => ({ label: k === 'part_payment' ? 'part' : k, value: v, color: PAY_COLORS[k] || '#94a3b8' }));

  return (
    <div className="mt-6 grid gap-4 md:grid-cols-2">
      <Card><Donut title="Order status" segments={statusSeg} /></Card>
      <Card><Donut title="Payment type" segments={paySeg} /></Card>
    </div>
  );
}

export default function ReportsPage() {
  const [userPin, setUserPin] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [applied, setApplied] = useState({ userPin: '', startDate: '', endDate: '' });

  const loader = useCallback(() => fetchReports(applied), [applied]);
  const { data, loading, error, refetch } = useApiQuery(loader, [applied]);

  const apply = () => setApplied({ userPin, startDate, endDate });
  const isRange = !!(applied.startDate && applied.endDate);
  const d = data || {};

  return (
    <>
      <PageHeader title="Reports" subtitle="Sales analytics & performance" />

      <Card className="mb-4">
        <div className="flex flex-wrap items-end gap-3">
          <label className="text-xs font-bold text-slate-600">From
            <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className="mt-1 block rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary" />
          </label>
          <label className="text-xs font-bold text-slate-600">To
            <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} className="mt-1 block rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary" />
          </label>
          <label className="text-xs font-bold text-slate-600">Reports PIN (if set)
            <input type="password" value={userPin} onChange={(e) => setUserPin(e.target.value)} placeholder="••••••" className="mt-1 block w-28 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary" />
          </label>
          <button onClick={apply} className="rounded-full bg-primary px-5 py-2.5 text-sm font-bold text-white hover:bg-primary-dark">Apply</button>
          {(applied.startDate || applied.endDate || applied.userPin) && (
            <button onClick={() => { setStartDate(''); setEndDate(''); setUserPin(''); setApplied({ userPin: '', startDate: '', endDate: '' }); }} className="rounded-full border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-500">Clear</button>
          )}
        </div>
      </Card>

      {loading ? <Loader /> : error ? <ErrorState error={error} onRetry={refetch} /> : (
        isRange ? (
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            <StatCard label="Range Revenue" value={money(d.total_sales)} icon={CalendarRange} />
            <StatCard label="Range Orders" value={d.total_orders ?? 0} icon={ShoppingBag} />
            <StatCard label="Range UPI" value={money(d.total_upi_sales)} icon={Smartphone} />
            <StatCard label="Range Cash" value={money(d.total_cash_sales)} icon={Banknote} accent="text-green-500" />
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            <StatCard label="Today Revenue" value={money(d.today_revenue)} icon={IndianRupee} />
            <StatCard label="Weekly Sales" value={money(d.weekly_sales)} icon={CalendarRange} accent="text-green-500" />
            <StatCard label="Total Sales" value={money(d.total_sales)} icon={Wallet} />
            <StatCard label="Total Orders" value={d.total_orders ?? 0} icon={ShoppingBag} />
            <StatCard label="Today UPI" value={money(d.today_upi_payment)} icon={Smartphone} />
            <StatCard label="Today Cash" value={money(d.today_cash_payment)} icon={Banknote} accent="text-green-500" />
            <StatCard label="Total UPI" value={money(d.total_upi_sales)} icon={Smartphone} />
            <StatCard label="Total Cash" value={money(d.total_cash_sales)} icon={Banknote} accent="text-green-500" />
          </div>
        )
      )}

      {!loading && !error && Number(d.orders_cancelled) > 0 && (
        <Card className="mt-4 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-red-50 text-red-500"><XCircle className="h-5 w-5" /></div>
          <div><p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Cancelled orders</p><p className="text-lg font-black">{d.orders_cancelled}</p></div>
        </Card>
      )}

      <Charts />
    </>
  );
}
