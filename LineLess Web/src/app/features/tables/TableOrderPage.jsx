import { useMemo, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Plus, Minus, ArrowLeft, X, Printer, XCircle } from 'lucide-react';
import { fetchTableProducts } from './tablesApi';
import { fetchSettings } from '../settings/settingsApi';
import { useApiQuery } from '../../core/useApiQuery';
import { printKitchenTicket } from '../../core/printReceipt';
import { PageHeader, Card, Loader, ErrorState } from '../../components/ui';
import { useTableOrder, productIsCustomizable, productOptions } from './useTableOrder';

const money = (v) => `₹${Number(v || 0).toFixed(0)}`;
const money2 = (v) => `₹${Number(v || 0).toFixed(2)}`;
const num = (v) => parseFloat(v ?? '') || 0;

// Customization dialog: pick portion (Half / Full), sub-category/variant option,
// or name a "New Dish". Confirms into a cart instance.
function CustomizeDialog({ product, onClose, onConfirm }) {
  const options = productOptions(product);
  const isNewDish = options.length === 0 && String(product.name || '').trim().toLowerCase() === 'new dish';
  const hasHalf = num(product.half_price) > 0;
  const [portion, setPortion] = useState('full'); // 'full' | 'half'
  const [picked, setPicked] = useState(null);
  const [dishName, setDishName] = useState('');
  const [dishPrice, setDishPrice] = useState('');

  const base = portion === 'half' && hasHalf ? num(product.half_price) : num(product.price);

  const confirm = () => {
    if (isNewDish) {
      if (!dishName.trim() || dishPrice === '') return;
      onConfirm(dishName.trim(), num(dishPrice)); // note, unitPrice (absolute)
      return;
    }
    const o = picked;
    const parts = [];
    if (hasHalf) {
      parts.push(portion === 'half' ? 'Half (½)' : 'Full');
    }
    if (o && o.name) {
      parts.push(o.price > 0 ? `${o.name} (+₹${Math.round(o.price)})` : o.name);
    }
    const note = parts.join(' · ');
    onConfirm(note, base + (o?.price || 0));
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-900/50" onClick={onClose} />
      <div className="relative z-10 w-full max-w-sm rounded-3xl bg-white p-6 shadow-2xl">
        <button onClick={onClose} className="absolute right-4 top-4 rounded-full bg-slate-100 p-2 hover:bg-slate-200"><X className="h-4 w-4" /></button>
        <h2 className="text-lg font-black">{product.name}</h2>
        <p className="mb-4 text-xs text-slate-400">
          {isNewDish ? 'Enter dish name & price' : hasHalf ? 'Select portion & customizations' : 'Choose a sub-category'}
        </p>

        {isNewDish ? (
          <div className="space-y-2">
            <input value={dishName} onChange={(e) => setDishName(e.target.value)} placeholder="Dish name" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm outline-none focus:border-primary focus:bg-white" />
            <input type="number" value={dishPrice} onChange={(e) => setDishPrice(e.target.value)} placeholder="Price (₹)" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm outline-none focus:border-primary focus:bg-white" />
          </div>
        ) : (
          <div className="space-y-3">
            {/* Portion: Half vs Full */}
            {hasHalf && (
              <div>
                <label className="mb-1.5 block text-xs font-black uppercase tracking-wider text-slate-500">Portion / Size</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setPortion('full')}
                    className={`rounded-xl border py-2.5 px-3 text-sm font-bold transition-all ${
                      portion === 'full'
                        ? 'border-primary bg-primary text-white shadow-sm'
                        : 'border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100'
                    }`}
                  >
                    Full · {money(product.price)}
                  </button>
                  <button
                    type="button"
                    onClick={() => setPortion('half')}
                    className={`rounded-xl border py-2.5 px-3 text-sm font-bold transition-all ${
                      portion === 'half'
                        ? 'border-primary bg-primary text-white shadow-sm'
                        : 'border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100'
                    }`}
                  >
                    Half (½) · {money(product.half_price)}
                  </button>
                </div>
              </div>
            )}

            {/* Customization Options */}
            {options.length > 0 && (
              <div>
                <label className="mb-1.5 block text-xs font-black uppercase tracking-wider text-slate-500">
                  Customization {hasHalf ? '(Optional)' : ''}
                </label>
                <div className="max-h-52 space-y-2 overflow-y-auto">
                  {options.map((o, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setPicked(picked === o ? null : o)}
                      className={`flex w-full items-center justify-between rounded-xl border px-3 py-2.5 text-sm font-semibold transition-colors ${
                        picked === o ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200'
                      }`}
                    >
                      <span>{o.name}</span>
                      <span>{o.price > 0 ? `+${money(o.price)}` : 'Free'}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        <button onClick={confirm} className="mt-4 w-full rounded-2xl bg-primary py-3 font-bold text-white hover:bg-primary-dark">
          Add · {money(base + (picked?.price || 0))}
        </button>
      </div>
    </div>
  );
}

export default function TableOrderPage() {
  const { tableNo } = useParams();
  const navigate = useNavigate();
  const { data: categories, loading, error, refetch } = useApiQuery(fetchTableProducts, []);
  const { data: settings } = useApiQuery(fetchSettings, []);
  const gstEnabled = settings?.gst_enabled === 1 || settings?.gst_enabled === '1' || settings?.gst_enabled === true;

  const productLookup = useMemo(() => {
    const map = {};
    (categories || []).forEach((c) => (c.products || []).forEach((p) => { map[p.id] = p; }));
    return map;
  }, [categories]);

  const order = useTableOrder({ tableNo, productLookup, gstEnabled });
  const [activeCat, setActiveCat] = useState(null);
  const [customizing, setCustomizing] = useState(null);
  const [payment, setPayment] = useState('upi');
  const [upiAmount, setUpiAmount] = useState('');
  const [cashAmount, setCashAmount] = useState('');
  const [completing, setCompleting] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [showCancelModal, setShowCancelModal] = useState(false);
  const [msg, setMsg] = useState('');

  if (loading) return <><PageHeader title={`Table ${tableNo}`} /><Loader /></>;
  if (error) return <><PageHeader title={`Table ${tableNo}`} /><ErrorState error={error} onRetry={refetch} /></>;

  const cats = categories || [];
  const shownCats = activeCat ? cats.filter((c) => c.id === activeCat) : cats;

  const complete = async () => {
    if (order.lines.length === 0) return;
    setCompleting(true); setMsg('');
    const total = order.totals.grandTotal;

    let payload;
    if (payment === 'upi') {
      payload = { payment_type: 'upi', upi_amount: total, cash_amount: 0 };
    } else if (payment === 'cash') {
      payload = { payment_type: 'cash', upi_amount: 0, cash_amount: total };
    } else {
      payload = { payment_type: 'part_payment', upi_amount: num(upiAmount), cash_amount: num(cashAmount) };
    }

    try {
      await order.completeOrder(payload);
      navigate('/app/tables', { replace: true });
    } catch (e) {
      setMsg(e?.message || 'Failed to complete order.');
      setCompleting(false);
    }
  };

  const handleConfirmCancel = async () => {
    setCancelling(true);
    setMsg('');
    try {
      await order.cancelOrder();
      setShowCancelModal(false);
      navigate('/app/tables', { replace: true });
    } catch (e) {
      setMsg(e?.message || 'Failed to cancel table order.');
      setCancelling(false);
      setShowCancelModal(false);
    }
  };

  const ProductCard = ({ p }) => {
    const entry = order.cart[p.id];
    const qty = entry?.qty || 0;
    const customizable = productIsCustomizable(p);
    const hasHalf = num(p.half_price) > 0;
    const step = hasHalf ? 0.5 : 1;
    return (
      <div className="flex flex-col justify-between rounded-2xl border border-slate-100 bg-white p-3 shadow-sm">
        <div>
          <p className="line-clamp-2 text-sm font-bold">{p.name}</p>
          <p className="mt-0.5 text-xs font-semibold text-primary">
            {money(p.price)}{hasHalf ? ` · ½ ${money(p.half_price)}` : ''}
          </p>
          {customizable && <p className="mt-0.5 text-[10px] font-bold uppercase text-purple-500">Customizable</p>}
        </div>

        {qty === 0 ? (
          customizable ? (
            <button onClick={() => setCustomizing(p)} className="mt-3 rounded-xl bg-primary py-2 text-xs font-bold text-white hover:bg-primary-dark">
              {hasHalf ? 'Add (Half / Full)' : 'Add'}
            </button>
          ) : hasHalf ? (
            <div className="mt-3 flex gap-2">
              <button onClick={() => order.addPlain(p.id, 0.5)} className="flex-1 rounded-xl bg-slate-100 py-2 text-xs font-bold text-secondary hover:bg-slate-200">½</button>
              <button onClick={() => order.addPlain(p.id, 1)} className="flex-1 rounded-xl bg-primary py-2 text-xs font-bold text-white hover:bg-primary-dark">Full</button>
            </div>
          ) : (
            <button onClick={() => order.addPlain(p.id, 1)} className="mt-3 rounded-xl bg-primary py-2 text-xs font-bold text-white hover:bg-primary-dark">Add</button>
          )
        ) : (
          <div className="mt-3 flex items-center justify-between rounded-xl bg-primary px-2 py-1.5 text-white">
            <button onClick={() => (customizable ? order.removeOne(p.id) : order.changeQty(p.id, -step))} className="p-1"><Minus className="h-4 w-4" /></button>
            <span className="text-sm font-black">{qty % 1 === 0 ? qty : qty.toFixed(1)}</span>
            <button onClick={() => (customizable ? setCustomizing(p) : order.changeQty(p.id, step))} className="p-1"><Plus className="h-4 w-4" /></button>
          </div>
        )}
      </div>
    );
  };

  return (
    <>
      <PageHeader
        title={`Table ${tableNo}`}
        subtitle={order.restored ? 'Dine-in order' : 'Loading table…'}
        action={<button onClick={() => navigate('/app/tables')} className="flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600"><ArrowLeft className="h-4 w-4" /> Tables</button>}
      />

      <div className="grid gap-5 lg:grid-cols-[1fr_380px]">
        {/* Catalogue */}
        <div>
          <div className="mb-3 flex flex-wrap gap-2">
            <button onClick={() => setActiveCat(null)} className={`rounded-full px-3 py-1.5 text-xs font-bold ${!activeCat ? 'bg-primary text-white' : 'border border-slate-200 bg-white text-slate-500'}`}>All</button>
            {cats.map((c) => (
              <button key={c.id} onClick={() => setActiveCat(c.id)} className={`rounded-full px-3 py-1.5 text-xs font-bold ${activeCat === c.id ? 'bg-primary text-white' : 'border border-slate-200 bg-white text-slate-500'}`}>{c.name}</button>
            ))}
          </div>
          <div className="space-y-5">
            {shownCats.map((c) => (
              <div key={c.id}>
                <h3 className="mb-2 text-xs font-black uppercase tracking-wide text-slate-500">{c.name}</h3>
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                  {(c.products || []).map((p) => <ProductCard key={p.id} p={p} />)}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Cart */}
        <div className="lg:sticky lg:top-20 lg:self-start">
          <Card>
            <h3 className="mb-3 text-sm font-black">Order · Table {tableNo}</h3>
            {order.lines.length === 0 ? (
              <p className="py-6 text-center text-sm text-slate-400">Add items to start the table order.</p>
            ) : (
              <div className="mb-3 max-h-64 space-y-2 overflow-y-auto">
                {order.lines.map((l, i) => (
                  <div key={i} className="flex items-start justify-between gap-2 text-sm">
                    <div className="min-w-0">
                      <p className="truncate font-semibold text-slate-700"><span className="font-bold">{l.qty % 1 === 0 ? l.qty : l.qty.toFixed(1)}×</span> {l.product.name}</p>
                      {l.note && <p className="truncate text-xs font-semibold text-primary">{l.note}</p>}
                    </div>
                    <span className="shrink-0 font-semibold">{money2(l.lineTotal)}</span>
                  </div>
                ))}
              </div>
            )}

            <div className="space-y-2 border-t border-slate-100 pt-3">
              <input value={order.customer.name} onChange={(e) => order.setCustomer((c) => ({ ...c, name: e.target.value }))} placeholder="Customer name" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white" />
              <input value={order.customer.mobile} onChange={(e) => order.setCustomer((c) => ({ ...c, mobile: e.target.value.replace(/\D/g, '').slice(0, 10) }))} placeholder="Mobile (10 digits)" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white" />
              <input value={order.customer.note} onChange={(e) => order.setCustomer((c) => ({ ...c, note: e.target.value }))} placeholder="Order note (optional)" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white" />
            </div>

            {order.totals.gst > 0 && (
              <div className="mt-3 space-y-1 border-t border-slate-100 pt-3 text-sm text-slate-500">
                <div className="flex justify-between"><span>Subtotal</span><span>{money2(order.totals.subtotal)}</span></div>
                <div className="flex justify-between"><span>CGST</span><span>{money2(order.totals.gst / 2)}</span></div>
                <div className="flex justify-between"><span>SGST</span><span>{money2(order.totals.gst / 2)}</span></div>
              </div>
            )}
            <div className="mt-3 flex items-center justify-between border-t border-slate-100 pt-3">
              <span className="font-bold">Total</span>
              <span className="text-xl font-black text-primary">{money2(order.totals.grandTotal)}</span>
            </div>

            <div className="mt-3 flex gap-2">
              {['upi', 'cash', 'part_payment'].map((pm) => (
                <button key={pm} onClick={() => setPayment(pm)} className={`flex-1 rounded-xl py-2 text-xs font-bold ${payment === pm ? 'bg-secondary text-white' : 'bg-slate-100 text-slate-500'}`}>
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

            {msg && <p className="mt-2 text-sm font-semibold text-red-500">{msg}</p>}
            <div className="mt-3 flex gap-2">
              <button
                onClick={() => printKitchenTicket({
                  order_type: 'dine_in', token_no: tableNo,
                  customer_name: order.customer.name, customer_mobile: order.customer.mobile,
                  special_note: order.customer.note,
                  items: order.lines.map((l) => ({ name: l.product.name, quantity: l.qty, note: l.note })),
                })}
                disabled={order.lines.length === 0}
                className="flex items-center justify-center gap-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-bold text-slate-600 hover:bg-slate-50 disabled:opacity-50"
                title="Print kitchen ticket"
              >
                <Printer className="h-4 w-4" /> KOT
              </button>
              <button onClick={complete} disabled={completing || cancelling || order.lines.length === 0} className="flex-1 rounded-2xl bg-primary py-3 font-bold text-white hover:bg-primary-dark disabled:opacity-60">
                {completing ? 'Completing…' : `Complete · ${money2(order.totals.grandTotal)}`}
              </button>
            </div>
            <button
              type="button"
              onClick={() => setShowCancelModal(true)}
              disabled={cancelling || completing || (order.lines.length === 0 && !order.hasExistingOrder)}
              className="mt-2.5 flex w-full items-center justify-center gap-2 rounded-2xl border border-red-200 bg-red-50/70 py-2.5 text-xs font-bold text-red-600 transition-all hover:bg-red-100 hover:border-red-300 active:scale-[0.99] disabled:opacity-40 dark:border-red-900/50 dark:bg-red-950/20 dark:text-red-400 dark:hover:bg-red-950/40"
              title="Cancel this table order"
            >
              <XCircle className="h-4 w-4" />
              <span>Cancel Order</span>
            </button>
            <p className="mt-2 text-center text-[11px] text-slate-400">Changes auto-save to the table while you build the order.</p>
          </Card>
        </div>
      </div>

      {/* Cancel Order Confirmation Modal */}
      {showCancelModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => !cancelling && setShowCancelModal(false)} />
          <div className="relative z-10 w-full max-w-sm rounded-3xl bg-white p-6 shadow-2xl dark:bg-slate-900 dark:border dark:border-slate-800">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-red-50 text-red-600 dark:bg-red-950/40 dark:text-red-400 mb-4">
              <XCircle className="h-6 w-6" />
            </div>
            <h3 className="text-lg font-black text-slate-900 dark:text-slate-100">Cancel Table {tableNo} Order?</h3>
            <p className="mt-1 text-xs text-slate-500 leading-relaxed dark:text-slate-400">
              This will discard all items and free Table {tableNo} immediately. This action cannot be undone.
            </p>
            <div className="mt-5 flex gap-2">
              <button
                type="button"
                disabled={cancelling}
                onClick={() => setShowCancelModal(false)}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-xs font-bold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
              >
                Keep Order
              </button>
              <button
                type="button"
                disabled={cancelling}
                onClick={handleConfirmCancel}
                className="flex-1 rounded-xl bg-red-500 py-2.5 text-xs font-bold text-white hover:bg-red-600 disabled:opacity-50 transition-colors shadow-sm"
              >
                {cancelling ? 'Cancelling…' : 'Yes, Cancel'}
              </button>
            </div>
          </div>
        </div>
      )}

      {customizing && (
        <CustomizeDialog
          product={customizing}
          onClose={() => setCustomizing(null)}
          onConfirm={(note, unitPrice) => { order.addInstance(customizing.id, note, unitPrice); setCustomizing(null); }}
        />
      )}
    </>
  );
}
