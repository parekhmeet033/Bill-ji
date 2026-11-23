import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { saveTableOrder, fetchPendingTables } from './tablesApi';

const round2 = (v) => Math.round((Number(v) + Number.EPSILON) * 100) / 100;
const num = (v) => parseFloat(v ?? '') || 0;
const isGst = (p) => p?.gst_applicable === 1 || p?.gst_applicable === '1' || p?.gst_applicable === true;

// Faithful port of TableProductModel.calculateTotal (half-plate aware).
export function calcTotal(product, qty, optionsPrice = 0) {
  const base = num(product.price);
  const p = base + optionsPrice;
  const hp = num(product.half_price);
  if (qty <= 0) return 0;
  if (String(product.unit || '').toUpperCase() === 'KG') return qty * p;
  const fullQty = Math.floor(qty);
  const remainder = parseFloat((qty - fullQty).toFixed(1));
  let total = fullQty * p;
  if (remainder === 0.5 && hp > 0) total += hp + optionsPrice;
  else total += remainder * p;
  return total;
}

export function productIsCustomizable(p) {
  const hasOpts = (p.variants && p.variants.length) || (p.subcategories && p.subcategories.length);
  const isNewDish = String(p.category_name || p.name || '').trim().toLowerCase() === 'new dish'
    || String(p.name || '').trim().toLowerCase() === 'new dish';
  return !!hasOpts || isNewDish;
}
export const productOptions = (p) => (p.variants && p.variants.length ? p.variants : (p.subcategories || []));

/**
 * Cart engine for one dine-in table. Mirrors the mobile TableOrderProvider:
 * per-instance customized lines, half-plate pricing, GST-aware totals, restore
 * from a pending table, and debounced auto-save (status 'pending').
 */
export function useTableOrder({ tableNo, productLookup, gstEnabled }) {
  // cart: { [productId]: { qty, instances: [{ note, unitPrice }] } }
  const [cart, setCart] = useState({});
  const [customer, setCustomer] = useState({ name: '', mobile: '', note: '' });
  const [restored, setRestored] = useState(false);
  const autosyncTimer = useRef(null);
  const skipNextSync = useRef(true); // don't auto-save immediately after restore/mount

  // ---- Restore existing table order ----
  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const tables = await fetchPendingTables();
        const t = (tables || []).find((x) => Number(x.table_no) === Number(tableNo));
        if (active && t) {
          const next = {};
          (t.items || []).forEach((it) => {
            const pid = it.product_id;
            if (pid == null) return;
            const q = num(it.qty ?? it.quantity);
            next[pid] ||= { qty: 0, instances: [] };
            next[pid].qty += q;
            const note = (it.note || '').trim();
            if (note) next[pid].instances.push({ note, unitPrice: num(it.price) });
          });
          setCart(next);
          setCustomer({ name: t.customer_name || '', mobile: t.customer_mobile || '', note: t.order_note || '' });
        }
      } catch { /* ignore — start empty */ }
      finally { if (active) { setRestored(true); skipNextSync.current = true; } }
    })();
    return () => { active = false; };
  }, [tableNo]);

  // ---- Cart operations ----
  const addPlain = useCallback((pid, step = 1) => {
    setCart((c) => {
      const cur = c[pid] || { qty: 0, instances: [] };
      return { ...c, [pid]: { ...cur, qty: round2(cur.qty + step) } };
    });
  }, []);

  const changeQty = useCallback((pid, step) => {
    setCart((c) => {
      const cur = c[pid];
      if (!cur) return c;
      const qty = round2(cur.qty + step);
      const next = { ...c };
      if (qty <= 0) { delete next[pid]; return next; }
      // Trim instances from the end so they stay aligned with qty.
      let instances = cur.instances;
      if (instances.length > qty) instances = instances.slice(0, Math.max(0, Math.floor(qty)));
      next[pid] = { qty, instances };
      return next;
    });
  }, []);

  const addInstance = useCallback((pid, note, unitPrice) => {
    setCart((c) => {
      const cur = c[pid] || { qty: 0, instances: [] };
      return { ...c, [pid]: { qty: round2(cur.qty + 1), instances: [...cur.instances, { note, unitPrice }] } };
    });
  }, []);

  const removeOne = useCallback((pid) => {
    setCart((c) => {
      const cur = c[pid];
      if (!cur) return c;
      const next = { ...c };
      const qty = round2(cur.qty - 1);
      const instances = cur.instances.slice(0, Math.max(0, cur.instances.length - 1));
      if (qty <= 0) delete next[pid]; else next[pid] = { qty, instances };
      return next;
    });
  }, []);

  const clear = useCallback(() => { setCart({}); setCustomer({ name: '', mobile: '', note: '' }); }, []);

  // ---- Enumerate bill lines (one per customized instance + plain remainder) ----
  const lines = useMemo(() => {
    const out = [];
    Object.entries(cart).forEach(([pid, entry]) => {
      const product = productLookup[pid];
      if (!product) return;
      const base = num(product.price);
      if (entry.instances.length) {
        let instQty = 0;
        entry.instances.forEach((inst) => {
          instQty += 1;
          const unitPrice = round2(inst.unitPrice);
          out.push({ product, qty: 1, unitPrice, lineTotal: unitPrice, note: inst.note || null });
        });
        const remainder = round2(entry.qty - instQty);
        if (remainder > 0) out.push({ product, qty: remainder, unitPrice: base, lineTotal: calcTotal(product, remainder, 0), note: null });
      } else {
        out.push({ product, qty: entry.qty, unitPrice: base, lineTotal: calcTotal(product, entry.qty, 0), note: null });
      }
    });
    return out;
  }, [cart, productLookup]);

  const totals = useMemo(() => {
    let subtotal = 0, gst = 0;
    lines.forEach((l) => {
      subtotal += l.lineTotal;
      if (gstEnabled && isGst(l.product)) gst += round2(l.lineTotal * (num(l.product.gst_rate) / 100));
    });
    subtotal = round2(subtotal); gst = round2(gst);
    return { subtotal, gst, grandTotal: round2(subtotal + gst) };
  }, [lines, gstEnabled]);

  // ---- Build the save payload ----
  const buildPayload = useCallback((status, payment) => {
    const items = lines.map((l) => {
      const itemGst = gstEnabled && isGst(l.product);
      const lineGst = itemGst ? round2(l.lineTotal * (num(l.product.gst_rate) / 100)) : 0;
      return {
        product_id: l.product.id,
        product_name: l.product.name,
        price: l.unitPrice,
        qty: l.qty,
        unit: l.product.unit || 'NOS',
        total: l.lineTotal,
        note: l.note,
        gst_applicable: itemGst ? 1 : 0,
        gst_rate: num(l.product.gst_rate),
        gst_amount: lineGst,
        taxable_amount: l.lineTotal,
      };
    });
    return {
      table_no: Number(tableNo),
      customer_name: customer.name,
      customer_mobile: customer.mobile,
      order_note: customer.note,
      total_amount: totals.grandTotal,
      order_status: status,
      items,
      remove_items: [],
      ...(payment || {}),
    };
  }, [lines, totals, customer, tableNo, gstEnabled]);

  // ---- Debounced auto-save (status 'pending'), mirroring the mobile app ----
  useEffect(() => {
    if (!restored) return;
    if (skipNextSync.current) { skipNextSync.current = false; return; }
    if (autosyncTimer.current) clearTimeout(autosyncTimer.current);
    autosyncTimer.current = setTimeout(() => {
      if (lines.length === 0) return; // nothing to sync yet
      saveTableOrder(buildPayload('pending')).catch(() => { /* retried on next change */ });
    }, 700);
    return () => { if (autosyncTimer.current) clearTimeout(autosyncTimer.current); };
  }, [cart, customer, restored, lines.length, buildPayload]);

  // ---- Finalize (complete) ----
  const completeOrder = useCallback(async (payment) => {
    if (autosyncTimer.current) clearTimeout(autosyncTimer.current);
    await saveTableOrder(buildPayload('completed', payment));
    clear();
  }, [buildPayload, clear]);

  return {
    cart, customer, setCustomer,
    lines, totals, restored,
    addPlain, changeQty, addInstance, removeOne, clear,
    completeOrder,
  };
}
