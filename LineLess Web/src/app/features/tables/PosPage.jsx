import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Minus, ShoppingCart, ArrowLeft } from 'lucide-react';
import { fetchTableProducts, placePosOrder } from './tablesApi';
import { useApiQuery } from '../../core/useApiQuery';
import { PageHeader, Card, Loader, ErrorState } from '../../components/ui';

const money = (v) => `₹${Number(v || 0).toFixed(0)}`;
const PAYMENTS = [
  { label: 'UPI', value: 'upi' },
  { label: 'Cash', value: 'cash' },
  { label: 'Part', value: 'part_payment' },
];

export default function PosPage() {
  const navigate = useNavigate();
  const { data: categories, loading, error, refetch } = useApiQuery(fetchTableProducts, []);
  const [activeCat, setActiveCat] = useState(null);
  const [cart, setCart] = useState({}); // productId -> { product, qty }
  const [name, setName] = useState('');
  const [mobile, setMobile] = useState('');
  const [note, setNote] = useState('');
  const [payment, setPayment] = useState('upi');
  const [placing, setPlacing] = useState(false);
  const [msg, setMsg] = useState('');

  const cats = categories || [];
  const shownCats = activeCat ? cats.filter((c) => c.id === activeCat) : cats;

  const add = (p, portion = 'full') => {
    const key = `${p.id}_${portion}`;
    const unitPrice = portion === 'half' ? Number(p.half_price || p.price) : Number(p.price);
    const displayName = portion === 'half' ? `${p.name} (Half)` : p.name;
    setCart((c) => ({
      ...c,
      [key]: {
        key,
        product: p,
        name: displayName,
        price: unitPrice,
        portion,
        qty: (c[key]?.qty || 0) + 1,
      },
    }));
  };

  const sub = (key) => setCart((c) => {
    const item = c[key];
    if (!item) return c;
    const qty = item.qty - 1;
    const next = { ...c };
    if (qty <= 0) delete next[key]; else next[key] = { ...item, qty };
    return next;
  });

  const lines = Object.values(cart);
  const total = useMemo(() => lines.reduce((s, l) => s + Number(l.price || 0) * l.qty, 0), [lines]);

  const place = async () => {
    if (lines.length === 0) return;
    setPlacing(true); setMsg('');
    try {
      const items = lines.map((l) => ({
        product_id: l.product.id,
        product_name: l.name,
        price: Number(l.price || 0),
        qty: l.qty,
        unit: l.portion === 'half' ? 'HALF' : (l.product.unit || 'NOS'),
        total: Number(l.price || 0) * l.qty,
        note: l.portion === 'half' ? 'Half plate' : null,
      }));
      await placePosOrder({
        customerName: name, customerMobile: mobile, note,
        total, paymentType: payment,
        upiAmount: payment === 'upi' ? total : 0,
        cashAmount: payment === 'cash' ? total : 0,
        items,
      });
      navigate('/app', { replace: true });
    } catch (e) {
      setMsg(e?.message || 'Failed to place order.');
      setPlacing(false);
    }
  };

  if (loading) return <><PageHeader title="New Takeaway" /><Loader /></>;
  if (error) return <><PageHeader title="New Takeaway" /><ErrorState error={error} onRetry={refetch} /></>;

  return (
    <>
      <PageHeader
        title="New Takeaway (POS)"
        subtitle="Build a takeaway order and place it"
        action={<button onClick={() => navigate('/app/tables')} className="flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600"><ArrowLeft className="h-4 w-4" /> Back</button>}
      />

      <div className="grid gap-5 lg:grid-cols-[1fr_360px]">
        {/* Catalogue */}
        <div>
          <div className="mb-3 flex flex-wrap gap-2">
            <button onClick={() => setActiveCat(null)} className={`rounded-full px-3 py-1.5 text-xs font-bold ${!activeCat ? 'bg-primary text-white' : 'bg-white text-slate-500 border border-slate-200'}`}>All</button>
            {cats.map((c) => (
              <button key={c.id} onClick={() => setActiveCat(c.id)} className={`rounded-full px-3 py-1.5 text-xs font-bold ${activeCat === c.id ? 'bg-primary text-white' : 'bg-white text-slate-500 border border-slate-200'}`}>{c.name}</button>
            ))}
          </div>

          <div className="space-y-5">
            {shownCats.map((c) => (
              <div key={c.id}>
                <h3 className="mb-2 text-xs font-black uppercase tracking-wide text-slate-500">{c.name}</h3>
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                  {(c.products || []).map((p) => {
                    const hasHalf = Number(p.half_price || 0) > 0;
                    const fullKey = `${p.id}_full`;
                    const halfKey = `${p.id}_half`;
                    const fullQty = cart[fullKey]?.qty || 0;
                    const halfQty = cart[halfKey]?.qty || 0;

                    return (
                      <div key={p.id} className="flex flex-col justify-between rounded-2xl border border-slate-100 bg-white p-3 shadow-sm">
                        <div>
                          <p className="line-clamp-2 text-sm font-bold">{p.name}</p>
                          <p className="mt-0.5 text-xs font-semibold text-primary">
                            {money(p.price)}{hasHalf ? ` · ½ ${money(p.half_price)}` : ''}
                          </p>
                        </div>

                        {hasHalf ? (
                          <div className="mt-3 flex gap-2">
                            {halfQty === 0 ? (
                              <button
                                type="button"
                                onClick={() => add(p, 'half')}
                                className="flex-1 rounded-xl bg-slate-100 py-2 text-xs font-bold text-slate-700 hover:bg-slate-200"
                              >
                                ½ {money(p.half_price)}
                              </button>
                            ) : (
                              <div className="flex flex-1 items-center justify-between rounded-xl bg-slate-700 px-1.5 py-1 text-white">
                                <button type="button" onClick={() => sub(halfKey)} className="p-0.5"><Minus className="h-3.5 w-3.5" /></button>
                                <span className="text-xs font-black">{halfQty}½</span>
                                <button type="button" onClick={() => add(p, 'half')} className="p-0.5"><Plus className="h-3.5 w-3.5" /></button>
                              </div>
                            )}

                            {fullQty === 0 ? (
                              <button
                                type="button"
                                onClick={() => add(p, 'full')}
                                className="flex-1 rounded-xl bg-primary py-2 text-xs font-bold text-white hover:bg-primary-dark"
                              >
                                Full {money(p.price)}
                              </button>
                            ) : (
                              <div className="flex flex-1 items-center justify-between rounded-xl bg-primary px-1.5 py-1 text-white">
                                <button type="button" onClick={() => sub(fullKey)} className="p-0.5"><Minus className="h-3.5 w-3.5" /></button>
                                <span className="text-xs font-black">{fullQty}</span>
                                <button type="button" onClick={() => add(p, 'full')} className="p-0.5"><Plus className="h-3.5 w-3.5" /></button>
                              </div>
                            )}
                          </div>
                        ) : fullQty === 0 ? (
                          <button
                            type="button"
                            onClick={() => add(p, 'full')}
                            className="mt-3 rounded-xl bg-primary py-2 text-xs font-bold text-white hover:bg-primary-dark"
                          >
                            Add · {money(p.price)}
                          </button>
                        ) : (
                          <div className="mt-3 flex items-center justify-between rounded-xl bg-primary px-2 py-1.5 text-white">
                            <button type="button" onClick={() => sub(fullKey)} className="p-1"><Minus className="h-4 w-4" /></button>
                            <span className="text-sm font-black">{fullQty}</span>
                            <button type="button" onClick={() => add(p, 'full')} className="p-1"><Plus className="h-4 w-4" /></button>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Cart */}
        <div className="lg:sticky lg:top-20 lg:self-start">
          <Card>
            <h3 className="mb-3 flex items-center gap-2 text-sm font-black"><ShoppingCart className="h-4 w-4" /> Cart</h3>
            {lines.length === 0 ? (
              <p className="py-6 text-center text-sm text-slate-400">Add items to start an order.</p>
            ) : (
              <div className="mb-3 max-h-56 space-y-1.5 overflow-y-auto">
                {lines.map((l) => (
                  <div key={l.key} className="flex items-center justify-between gap-2 text-sm">
                    <span className="min-w-0 truncate text-slate-700 font-medium">
                      <span className="font-bold text-slate-900">{l.qty}×</span> {l.name}
                    </span>
                    <div className="flex shrink-0 items-center gap-2">
                      <span className="font-semibold">{money(l.price * l.qty)}</span>
                      <button type="button" onClick={() => sub(l.key)} className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-red-500">
                        <Minus className="h-3 w-3" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div className="space-y-2 border-t border-slate-100 pt-3">
              <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Customer name" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white" />
              <input value={mobile} onChange={(e) => setMobile(e.target.value.replace(/\D/g, '').slice(0, 10))} placeholder="Mobile (10 digits)" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white" />
              <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="Note (optional)" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white" />
              <div className="flex gap-2">
                {PAYMENTS.map((pm) => (
                  <button key={pm.value} onClick={() => setPayment(pm.value)} className={`flex-1 rounded-xl py-2 text-xs font-bold ${payment === pm.value ? 'bg-secondary text-white' : 'bg-slate-100 text-slate-500'}`}>{pm.label}</button>
                ))}
              </div>
            </div>

            <div className="mt-3 flex items-center justify-between border-t border-slate-100 pt-3">
              <span className="font-bold">Total</span>
              <span className="text-xl font-black text-primary">{money(total)}</span>
            </div>
            {msg && <p className="mt-2 text-sm font-semibold text-red-500">{msg}</p>}
            <button onClick={place} disabled={placing || lines.length === 0} className="mt-3 w-full rounded-2xl bg-primary py-3 font-bold text-white hover:bg-primary-dark disabled:opacity-60">
              {placing ? 'Placing…' : `Place order · ${money(total)}`}
            </button>
          </Card>
        </div>
      </div>
    </>
  );
}
