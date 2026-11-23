import { Plus, Trash2 } from 'lucide-react';

// Editable list of { name, price } used for item variants and category
// sub-categories (customization add-ons).
export default function VariantsEditor({ label = 'Sub-categories', value = [], onChange }) {
  const rows = value || [];
  const update = (i, key, v) => {
    const next = rows.map((r, idx) => (idx === i ? { ...r, [key]: key === 'price' ? v : v } : r));
    onChange(next);
  };
  const add = () => onChange([...rows, { name: '', price: 0 }]);
  const remove = (i) => onChange(rows.filter((_, idx) => idx !== i));

  return (
    <div>
      <div className="mb-1 flex items-center justify-between">
        <span className="text-xs font-bold text-slate-600">{label}</span>
        <button type="button" onClick={add} className="flex items-center gap-1 text-xs font-bold text-primary">
          <Plus className="h-3.5 w-3.5" /> Add
        </button>
      </div>
      {rows.length === 0 && <p className="text-xs text-slate-400">None. Add options customers can choose (each with an optional extra price).</p>}
      <div className="space-y-2">
        {rows.map((r, i) => (
          <div key={i} className="flex items-center gap-2">
            <input
              value={r.name}
              onChange={(e) => update(i, 'name', e.target.value)}
              placeholder="Name (e.g. Extra cheese)"
              className="flex-1 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-primary focus:bg-white"
            />
            <div className="relative w-28">
              <span className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-xs text-slate-400">+₹</span>
              <input
                type="number"
                value={r.price}
                onChange={(e) => update(i, 'price', Number(e.target.value))}
                className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2 pl-7 pr-2 text-sm outline-none focus:border-primary focus:bg-white"
              />
            </div>
            <button type="button" onClick={() => remove(i)} className="rounded-lg p-2 text-red-400 hover:bg-red-50"><Trash2 className="h-4 w-4" /></button>
          </div>
        ))}
      </div>
    </div>
  );
}
