import { useState } from 'react';
import { ShoppingBag, Clock3, CheckCircle2, Truck, Hash, CheckCircle, Package, X, ChevronRight, User, Phone, FileText, Utensils, Receipt } from 'lucide-react';
import { fetchDashboard, updateOrderStatus } from './dashboardApi';
import { useApiQuery } from '../../core/useApiQuery';
import { useRealtime } from '../../core/useRealtime';
import { PageHeader, StatCard, Card, Loader, ErrorState } from '../../components/ui';

const money = (v) => `₹${Number(v || 0).toFixed(2)}`;

const STATUS_STYLES = {
  pending: 'bg-amber-50 text-amber-600 border border-amber-200/60',
  running: 'bg-blue-50 text-blue-600 border border-blue-200/60',
  preparing: 'bg-blue-50 text-blue-600 border border-blue-200/60',
  completed: 'bg-green-50 text-green-600 border border-green-200/60',
  dispatched: 'bg-slate-100 text-slate-600 border border-slate-200/60',
  cancelled: 'bg-red-50 text-red-500 border border-red-200/60',
};

const formatTime = (ts) => {
  if (!ts) return '';
  try {
    const d = new Date(ts);
    if (isNaN(d.getTime())) return String(ts);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  } catch {
    return String(ts);
  }
};

export default function DashboardPage() {
  const { data, loading, error, refetch } = useApiQuery(fetchDashboard, []);
  useRealtime(refetch);

  const [selectedOrder, setSelectedOrder] = useState(null);
  const [dispatchOrder, setDispatchOrder] = useState(null);
  const [payment, setPayment] = useState('upi');
  const [upiAmount, setUpiAmount] = useState('');
  const [cashAmount, setCashAmount] = useState('');
  const [updating, setUpdating] = useState(false);

  const handleUpdateStatus = async (orderId, newStatus) => {
    try {
      setUpdating(true);
      await updateOrderStatus(orderId, newStatus);
      if (selectedOrder && (selectedOrder.id === orderId || selectedOrder.order_id === orderId)) {
        setSelectedOrder((prev) => (prev ? { ...prev, status: newStatus } : null));
      }
      refetch();
    } catch (e) {
      console.error(e);
    } finally {
      setUpdating(false);
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
      if (selectedOrder && (selectedOrder.id === dispatchOrder.id || selectedOrder.order_id === dispatchOrder.order_id)) {
        setSelectedOrder(null);
      }
      refetch();
    } catch (e) {
      console.error(e);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) return <><PageHeader title="Dashboard" subtitle="Today at a glance" /><Loader /></>;
  if (error) return <><PageHeader title="Dashboard" /><ErrorState error={error} onRetry={refetch} /></>;

  const d = data || {};
  const recent = Array.isArray(d.recent_orders) ? d.recent_orders : [];

  return (
    <>
      <PageHeader title="Dashboard" subtitle="Today at a glance" />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Total Orders" value={d.today_total_orders ?? 0} icon={ShoppingBag} />
        <StatCard label="Pending" value={d.today_pending_orders ?? 0} icon={Clock3} accent="text-amber-500" />
        <StatCard label="Completed" value={d.today_completed_orders ?? 0} icon={CheckCircle2} accent="text-green-500" />
        <StatCard label="Dispatched" value={d.today_dispatched_orders ?? 0} icon={Truck} accent="text-slate-500" />
      </div>

      {d.running_token != null && d.running_token !== '0' && (
        <Card
          className="mt-4 flex cursor-pointer items-center justify-between gap-3 transition-colors hover:bg-slate-50"
          onClick={() => {
            const running = recent.find((o) => String(o.token_no || o.token_number) === String(d.running_token));
            if (running) setSelectedOrder(running);
          }}
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
              <Hash className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Now serving token</p>
              <p className="text-xl font-black">{d.running_token}</p>
            </div>
          </div>
          <span className="flex items-center text-xs font-bold text-primary">
            View Live Order <ChevronRight className="ml-1 h-4 w-4" />
          </span>
        </Card>
      )}

      <div className="mb-3 mt-8 flex items-center justify-between">
        <h2 className="text-lg font-bold">Recent Orders</h2>
        <span className="text-xs text-slate-400">Click any order to view full details</span>
      </div>

      <Card className="p-0">
        {recent.length === 0 ? (
          <p className="px-5 py-10 text-center text-sm text-slate-400">No orders yet today.</p>
        ) : (
          <div className="divide-y divide-slate-100">
            {recent.map((o) => {
              const status = String(o.status || '').toLowerCase();
              const isDineIn = String(o.order_type || '').toLowerCase() === 'dine_in';
              const label = isDineIn
                ? `Table ${o.table_no || o.token_no || o.token_number || ''}`
                : `Token ${o.token_no || o.token_number || ''}`;

              return (
                <div
                  key={o.order_id || o.id}
                  onClick={() => setSelectedOrder(o)}
                  className="group flex flex-col gap-3 px-5 py-4 transition-all duration-150 hover:bg-amber-50/30 sm:flex-row sm:items-center sm:justify-between cursor-pointer"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <p className="truncate text-sm font-bold text-slate-900 group-hover:text-primary transition-colors">
                        {label}
                      </p>
                      <span className="text-xs font-medium text-slate-400">
                        · {o.customer_name || 'Walk-in'}
                      </span>
                    </div>
                    <p className="truncate text-xs text-slate-400 mt-0.5">
                      {(o.items?.length ?? 0)} item{(o.items?.length ?? 0) === 1 ? '' : 's'} · {isDineIn ? 'Dine-in' : 'Takeaway'}
                      {o.created_at ? ` · ${formatTime(o.created_at)}` : ''}
                    </p>
                  </div>

                  <div className="flex shrink-0 items-center gap-3">
                    <span className="text-sm font-black">{money(o.total_amount)}</span>
                    <span className={`rounded-full px-2.5 py-1 text-[11px] font-bold capitalize ${STATUS_STYLES[status] || 'bg-slate-100 text-slate-600'}`}>
                      {status || '—'}
                    </span>
                  </div>

                  <div className="flex items-center gap-2 sm:ml-4" onClick={(e) => e.stopPropagation()}>
                    {status === 'pending' && (
                      <button
                        onClick={() => handleUpdateStatus(o.order_id || o.id, 'running')}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-full bg-amber-500 px-3 py-1.5 text-xs font-bold text-white hover:bg-amber-600 sm:flex-none transition-colors"
                      >
                        <Package className="h-3.5 w-3.5" /> Start Preparing
                      </button>
                    )}
                    {status === 'running' && (
                      <button
                        onClick={() => handleUpdateStatus(o.order_id || o.id, 'completed')}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-bold text-white hover:bg-primary-dark sm:flex-none transition-colors"
                      >
                        <CheckCircle className="h-3.5 w-3.5" /> Mark as Ready
                      </button>
                    )}
                    {status === 'completed' && (
                      <button
                        onClick={() => setDispatchOrder(o)}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-full bg-green-500 px-3 py-1.5 text-xs font-bold text-white hover:bg-green-600 sm:flex-none transition-colors"
                      >
                        <Truck className="h-3.5 w-3.5" /> Dispatch
                      </button>
                    )}
                    <ChevronRight className="h-4 w-4 text-slate-300 group-hover:text-slate-500 transition-colors hidden sm:block" />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>

      {/* Order Details Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm transition-opacity"
            onClick={() => setSelectedOrder(null)}
          />

          <div className="relative z-10 flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-3xl bg-white shadow-2xl">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-xl font-black text-slate-900">
                    {String(selectedOrder.order_type || '').toLowerCase() === 'dine_in'
                      ? `Table ${selectedOrder.table_no || selectedOrder.token_no || selectedOrder.token_number || ''}`
                      : `Token ${selectedOrder.token_no || selectedOrder.token_number || ''}`}
                  </h2>
                  <span className="rounded-md bg-slate-100 px-2 py-0.5 text-xs font-bold text-slate-600">
                    #{selectedOrder.order_id || selectedOrder.id}
                  </span>
                </div>
                <p className="mt-0.5 text-xs text-slate-400">
                  {String(selectedOrder.order_type || '').toLowerCase() === 'dine_in' ? 'Dine-in' : 'Takeaway'}
                  {selectedOrder.created_at ? ` · ${formatTime(selectedOrder.created_at)}` : ''}
                </p>
              </div>

              <div className="flex items-center gap-2">
                <span
                  className={`rounded-full px-3 py-1 text-xs font-bold capitalize ${
                    STATUS_STYLES[String(selectedOrder.status || '').toLowerCase()] || 'bg-slate-100 text-slate-600'
                  }`}
                >
                  {selectedOrder.status || 'pending'}
                </span>
                <button
                  onClick={() => setSelectedOrder(null)}
                  className="rounded-full bg-slate-100 p-2 text-slate-500 hover:bg-slate-200 transition-colors"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            </div>

            {/* Modal Body */}
            <div className="flex-1 space-y-4 overflow-y-auto p-6">
              {/* Customer Info Card */}
              <div className="rounded-2xl border border-slate-100 bg-slate-50/80 p-3.5 text-xs">
                <div className="grid grid-cols-2 gap-2">
                  <div className="flex items-center gap-2 text-slate-700">
                    <User className="h-3.5 w-3.5 text-slate-400" />
                    <span className="font-semibold text-slate-900">{selectedOrder.customer_name || 'Walk-in Customer'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-slate-700">
                    <Phone className="h-3.5 w-3.5 text-slate-400" />
                    <span>{selectedOrder.customer_mobile && selectedOrder.customer_mobile !== 'N/A' ? selectedOrder.customer_mobile : 'No Phone'}</span>
                  </div>
                </div>
                {(selectedOrder.special_note || selectedOrder.order_note) && (
                  <div className="mt-2.5 flex items-start gap-2 border-t border-slate-200/60 pt-2 text-amber-700">
                    <FileText className="h-3.5 w-3.5 shrink-0 mt-0.5 text-amber-500" />
                    <span className="font-medium italic">{selectedOrder.special_note || selectedOrder.order_note}</span>
                  </div>
                )}
              </div>

              {/* Items List */}
              <div>
                <div className="mb-2 flex items-center justify-between">
                  <h3 className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-slate-400">
                    <Utensils className="h-3.5 w-3.5" /> Order Items ({selectedOrder.items?.length || 0})
                  </h3>
                </div>

                <div className="divide-y divide-slate-100 rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
                  {(selectedOrder.items || []).map((item, idx) => {
                    const qty = Math.round(Number(item.qty || item.quantity || 1));
                    const price = Number(item.price || 0);
                    const total = Number(item.total || (qty * price));
                    const note = String(item.note || '').trim();
                    const isHalf = note.toLowerCase().includes('half') || note.includes('½');
                    const isFull = note.toLowerCase().includes('full');

                    return (
                      <div key={idx} className="flex items-center justify-between p-3 text-sm">
                        <div className="min-w-0 flex-1 pr-3">
                          <div className="flex items-center gap-2">
                            <span className="font-bold text-slate-900">
                              {qty} × {item.product_name || item.name}
                            </span>
                            {isHalf && (
                              <span className="rounded-md bg-purple-100 px-2 py-0.5 text-[10px] font-bold text-purple-700">
                                Half (½)
                              </span>
                            )}
                            {isFull && (
                              <span className="rounded-md bg-emerald-100 px-2 py-0.5 text-[10px] font-bold text-emerald-700">
                                Full
                              </span>
                            )}
                          </div>
                          {note && !isHalf && !isFull && (
                            <p className="mt-0.5 text-xs font-medium text-amber-600">{note}</p>
                          )}
                          {note && (isHalf || isFull) && note.replace(/half(\s*\(½\))?|full/gi, '').replace(/[·,\-]/g, '').trim() && (
                            <p className="mt-0.5 text-xs font-medium text-amber-600">
                              {note.replace(/half(\s*\(½\))?|full/gi, '').replace(/^[·,\-\s]+|[·,\-\s]+$/g, '').trim()}
                            </p>
                          )}
                        </div>
                        <div className="text-right">
                          <p className="font-bold text-slate-900">{money(total)}</p>
                          <p className="text-[11px] text-slate-400">{money(price)} each</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Financial Breakdown */}
              <div className="rounded-2xl border border-slate-100 bg-slate-50/60 p-4 space-y-2 text-xs">
                <div className="flex justify-between text-slate-500">
                  <span>Subtotal</span>
                  <span className="font-medium text-slate-700">{money(selectedOrder.subtotal_amount)}</span>
                </div>
                {Number(selectedOrder.gst_amount || 0) > 0 && (
                  <div className="flex justify-between text-slate-500">
                    <span>Tax (GST)</span>
                    <span className="font-medium text-slate-700">{money(selectedOrder.gst_amount)}</span>
                  </div>
                )}
                <div className="flex justify-between items-center border-t border-slate-200/80 pt-2 text-sm font-black text-slate-900">
                  <span>Grand Total</span>
                  <span className="text-base text-primary font-black">{money(selectedOrder.total_amount)}</span>
                </div>
                <div className="flex justify-between text-[11px] text-slate-400 pt-1">
                  <span>Payment Mode:</span>
                  <span className="font-bold uppercase text-slate-600">{selectedOrder.payment_type || 'Cash'}</span>
                </div>
              </div>
            </div>

            {/* Modal Footer Actions */}
            <div className="border-t border-slate-100 bg-white p-4">
              <div className="flex gap-2">
                {String(selectedOrder.status || '').toLowerCase() === 'pending' && (
                  <button
                    disabled={updating}
                    onClick={() => handleUpdateStatus(selectedOrder.id || selectedOrder.order_id, 'running')}
                    className="flex flex-1 items-center justify-center gap-2 rounded-2xl bg-amber-500 py-3 text-sm font-bold text-white shadow-lg shadow-amber-500/20 hover:bg-amber-600 disabled:opacity-50 transition-colors"
                  >
                    <Package className="h-4 w-4" /> Start Preparing
                  </button>
                )}
                {String(selectedOrder.status || '').toLowerCase() === 'running' && (
                  <button
                    disabled={updating}
                    onClick={() => handleUpdateStatus(selectedOrder.id || selectedOrder.order_id, 'completed')}
                    className="flex flex-1 items-center justify-center gap-2 rounded-2xl bg-primary py-3 text-sm font-bold text-white shadow-lg shadow-primary/20 hover:bg-primary-dark disabled:opacity-50 transition-colors"
                  >
                    <CheckCircle className="h-4 w-4" /> Mark as Ready
                  </button>
                )}
                {String(selectedOrder.status || '').toLowerCase() === 'completed' && (
                  <button
                    disabled={updating}
                    onClick={() => {
                      setDispatchOrder(selectedOrder);
                      setSelectedOrder(null);
                    }}
                    className="flex flex-1 items-center justify-center gap-2 rounded-2xl bg-green-500 py-3 text-sm font-bold text-white shadow-lg shadow-green-500/20 hover:bg-green-600 disabled:opacity-50 transition-colors"
                  >
                    <Truck className="h-4 w-4" /> Dispatch Order
                  </button>
                )}
                {String(selectedOrder.status || '').toLowerCase() === 'dispatched' && (
                  <div className="flex flex-1 items-center justify-center gap-2 rounded-2xl bg-slate-100 py-3 text-sm font-bold text-slate-500">
                    <CheckCircle2 className="h-4 w-4 text-green-500" /> Order Dispatched
                  </div>
                )}
                <button
                  onClick={() => setSelectedOrder(null)}
                  className="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-bold text-slate-600 hover:bg-slate-50 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
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
