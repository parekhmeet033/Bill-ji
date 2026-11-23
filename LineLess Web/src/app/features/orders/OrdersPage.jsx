import { useCallback, useState } from 'react';
import { Search, ChevronDown, ChevronUp, Printer, ReceiptText, CheckCircle, Truck, Package, X } from 'lucide-react';
import { fetchOrders, updateOrderStatus } from './ordersApi';
import { fetchSettings } from '../settings/settingsApi';
import { useApiQuery } from '../../core/useApiQuery';
import { useRealtime } from '../../core/useRealtime';
import { printKitchenTicket, printBill } from '../../core/printReceipt';
import { PageHeader, Card, Loader, ErrorState } from '../../components/ui';

const money = (v) => `₹${Number(v || 0).toFixed(2)}`;
const STATUSES = ['All', 'pending', 'running', 'completed', 'dispatched', 'cancelled'];
const TYPES = [
  { label: 'All', value: 'All' },
  { label: 'Takeaway', value: 'take_away' },
  { label: 'Dine-in', value: 'dine_in' },
];
const STATUS_STYLES = {
  pending: 'bg-amber-50 text-amber-600',
  running: 'bg-blue-50 text-blue-600',
  completed: 'bg-green-50 text-green-600',
  dispatched: 'bg-slate-100 text-slate-600',
  cancelled: 'bg-red-50 text-red-500',
};

export default function OrdersPage() {
  const [status, setStatus] = useState('All');
  const [type, setType] = useState('All');
  const [search, setSearch] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [page, setPage] = useState(1);
  const [expanded, setExpanded] = useState(null);

  const [dispatchOrder, setDispatchOrder] = useState(null);
  const [payment, setPayment] = useState('upi');
  const [upiAmount, setUpiAmount] = useState('');
  const [cashAmount, setCashAmount] = useState('');
  const [updating, setUpdating] = useState(false);

  const handleUpdateStatus = async (orderId, newStatus) => {
    try {
      await updateOrderStatus(orderId, newStatus);
      refetch();
    } catch (e) {
      console.error(e);
    }
  };

  const handleConfirmDispatch = async () => {
    if (!dispatchOrder) return;
    setUpdating(true);
    const total = dispatchOrder.total_amount;
    let extra = {};
    if (payment === 'upi') {
      extra = { payment_type: 'upi', upi_amount: total, cash_amount: 0 };
    } else if (payment === 'cash') {
      extra = { payment_type: 'cash', upi_amount: 0, cash_amount: total };
    } else {
      extra = { payment_type: 'part_payment', upi_amount: Number(upiAmount) || 0, cash_amount: Number(cashAmount) || 0 };
    }
    try {
      await updateOrderStatus(dispatchOrder.id || dispatchOrder.order_id, 'dispatched', extra);
      setDispatchOrder(null);
      refetch();
    } catch (e) {
      console.error(e);
    } finally {
      setUpdating(false);
    }
  };

  const loader = useCallback(
    () => fetchOrders({ status, orderType: type, search, startDate, endDate, page }),
    [status, type, search, startDate, endDate, page],
  );
  const { data, loading, error, refetch } = useApiQuery(loader, [status, type, search, startDate, endDate, page]);
  const { data: settings } = useApiQuery(fetchSettings, []);
  useRealtime(refetch);
  const gstin = settings?.gst_enabled && settings?.gstin ? settings.gstin : (settings?.gstin || '');
  const shopName = settings?.legal_business_name || 'BillJi';

  const orders = data?.orders ?? [];
  const pagination = data?.pagination ?? { currentPage: 1, lastPage: 1 };

  const resetToFirstPage = (fn) => (v) => { setPage(1); fn(v); };

  return (
    <>
      <PageHeader title="Orders" subtitle="Order history, status & payments" />

      {/* Filters */}
      <Card className="mb-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[200px] flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              value={search}
              onChange={(e) => resetToFirstPage(setSearch)(e.target.value)}
              placeholder="Search name, mobile, token…"
              className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm outline-none focus:border-primary focus:bg-white"
            />
          </div>
          <select value={type} onChange={(e) => resetToFirstPage(setType)(e.target.value)} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm outline-none focus:border-primary">
            {TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
          </select>
          <select value={status} onChange={(e) => resetToFirstPage(setStatus)(e.target.value)} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm capitalize outline-none focus:border-primary">
            {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
          <input type="date" value={startDate} onChange={(e) => resetToFirstPage(setStartDate)(e.target.value)} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm outline-none focus:border-primary" />
          <input type="date" value={endDate} onChange={(e) => resetToFirstPage(setEndDate)(e.target.value)} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm outline-none focus:border-primary" />
        </div>
      </Card>

      {loading ? (
        <Loader />
      ) : error ? (
        <ErrorState error={error} onRetry={refetch} />
      ) : orders.length === 0 ? (
        <Card><p className="py-10 text-center text-sm text-slate-400">No orders match these filters.</p></Card>
      ) : (
        <div className="space-y-2">
          {orders.map((o) => {
            const id = o.order_id || o.id;
            const st = String(o.status || '').toLowerCase();
            const isDineIn = String(o.order_type || '').toLowerCase() === 'dine_in';
            const items = o.items || [];
            const open = expanded === id;
            return (
              <Card key={id} className="p-0">
                <button onClick={() => setExpanded(open ? null : id)} className="flex w-full items-center justify-between gap-3 px-5 py-3.5 text-left">
                  <div className="min-w-0">
                    <p className="truncate text-sm font-bold">
                      {isDineIn ? `Table ${o.token_no || o.token_number || ''}` : `Token ${o.token_no || o.token_number || ''}`}
                      <span className="ml-2 text-xs font-medium text-slate-400">{o.customer_name || 'Walk-in'}{o.customer_mobile ? ` · ${o.customer_mobile}` : ''}</span>
                    </p>
                    <p className="truncate text-xs text-slate-400">{items.length} item{items.length === 1 ? '' : 's'} · {isDineIn ? 'Dine-in' : 'Takeaway'}{o.payment_type ? ` · ${o.payment_type}` : ''}</p>
                  </div>
                  <div className="flex shrink-0 items-center gap-3">
                    <span className="text-sm font-black">{money(o.total_amount)}</span>
                    <span className={`rounded-full px-2.5 py-1 text-[11px] font-bold capitalize ${STATUS_STYLES[st] || 'bg-slate-100 text-slate-600'}`}>{st || '—'}</span>
                    {open ? <ChevronUp className="h-4 w-4 text-slate-400" /> : <ChevronDown className="h-4 w-4 text-slate-400" />}
                  </div>
                </button>
                {open && (
                  <div className="border-t border-slate-100 px-5 py-3">
                    {items.map((it, i) => (
                      <div key={i} className="flex items-center justify-between py-1 text-sm">
                        <span className="text-slate-600">
                          <span className="font-semibold">{it.quantity || it.qty}×</span> {it.name || it.product_name}
                          {it.note ? <span className="ml-2 text-xs text-primary">{it.note}</span> : null}
                        </span>
                        <span className="font-semibold">{money(it.total ?? (it.price * (it.quantity || it.qty || 0)))}</span>
                      </div>
                    ))}
                    {(Number(o.gst_amount) > 0) && (
                      <div className="mt-2 flex items-center justify-between border-t border-slate-100 pt-2 text-xs text-slate-500">
                        <span>GST</span><span>{money(o.gst_amount)}</span>
                      </div>
                    )}
                    <div className="mt-3 flex flex-wrap gap-2">
                      <button onClick={() => printKitchenTicket(o)} className="flex items-center gap-1.5 rounded-full border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-600 hover:bg-slate-50">
                        <Printer className="h-3.5 w-3.5" /> Print KOT
                      </button>
                      <button onClick={() => printBill(o, { shopName, gstin })} className="flex items-center gap-1.5 rounded-full border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-600 hover:bg-slate-50">
                        <ReceiptText className="h-3.5 w-3.5" /> Print bill
                      </button>
                      {st === 'pending' && (
                        <button onClick={() => handleUpdateStatus(id, 'running')} className="flex items-center gap-1.5 rounded-full bg-amber-500 px-3 py-1.5 text-xs font-bold text-white hover:bg-amber-600">
                          <Package className="h-3.5 w-3.5" /> Start Preparing
                        </button>
                      )}
                      {st === 'running' && (
                        <button onClick={() => handleUpdateStatus(id, 'completed')} className="flex items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-bold text-white hover:bg-primary-dark">
                          <CheckCircle className="h-3.5 w-3.5" /> Mark as Ready
                        </button>
                      )}
                      {st === 'completed' && (
                        <button onClick={() => setDispatchOrder(o)} className="flex items-center gap-1.5 rounded-full bg-green-500 px-3 py-1.5 text-xs font-bold text-white hover:bg-green-600">
                          <Truck className="h-3.5 w-3.5" /> Dispatch
                        </button>
                      )}
                    </div>
                  </div>
                )}
              </Card>
            );
          })}
        </div>
      )}

      {/* Pagination */}
      {!loading && !error && pagination.lastPage > 1 && (
        <div className="mt-5 flex items-center justify-center gap-3">
          <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)} className="rounded-full border border-slate-200 px-4 py-2 text-sm font-semibold disabled:opacity-40">Previous</button>
          <span className="text-sm text-slate-500">Page {pagination.currentPage} of {pagination.lastPage}</span>
          <button disabled={page >= pagination.lastPage} onClick={() => setPage((p) => p + 1)} className="rounded-full border border-slate-200 px-4 py-2 text-sm font-semibold disabled:opacity-40">Next</button>
        </div>
      )}

      {/* Dispatch Payment Modal */}
      {dispatchOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-900/50" onClick={() => setDispatchOrder(null)} />
          <div className="relative z-10 w-full max-w-sm rounded-3xl bg-white p-6 shadow-2xl">
            <button onClick={() => setDispatchOrder(null)} className="absolute right-4 top-4 rounded-full bg-slate-100 p-2 hover:bg-slate-200"><X className="h-4 w-4" /></button>
            <h2 className="text-lg font-black">Dispatch Order</h2>
            <p className="mb-4 text-xs text-slate-400">Total: {money(dispatchOrder.total_amount)}</p>

            <h3 className="mb-2 text-sm font-bold">Payment Type</h3>
            <div className="flex gap-2">
              {['upi', 'cash', 'part_payment'].map((pm) => (
                <button key={pm} onClick={() => setPayment(pm)} className={`flex-1 rounded-xl py-2 text-xs font-bold ${payment === pm ? 'bg-primary text-white' : 'bg-slate-100 text-slate-500'}`}>
                  {pm === 'part_payment' ? 'Part' : pm.toUpperCase()}
                </button>
              ))}
            </div>

            {payment === 'part_payment' && (
              <div className="mt-3 flex gap-3">
                <input
                  type="number"
                  value={upiAmount}
                  onChange={(e) => setUpiAmount(e.target.value)}
                  placeholder="UPI Amount"
                  className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white"
                />
                <input
                  type="number"
                  value={cashAmount}
                  onChange={(e) => setCashAmount(e.target.value)}
                  placeholder="Cash Amount"
                  className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white"
                />
              </div>
            )}

            <button onClick={handleConfirmDispatch} disabled={updating} className="mt-6 w-full rounded-2xl bg-green-500 py-3 font-bold text-white hover:bg-green-600 disabled:opacity-60">
              {updating ? 'Confirming…' : 'CONFIRM DISPATCH'}
            </button>
          </div>
        </div>
      )}
    </>
  );
}
