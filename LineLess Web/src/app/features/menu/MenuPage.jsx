import { useMemo, useState } from 'react';
import { Plus, Pencil, Trash2, X, ImagePlus, Layers } from 'lucide-react';
import {
  fetchMenu, fetchCategories, setMenuStatus, deleteMenuItem, addMenuItem, updateMenuItem,
  addCategory, updateCategory, deleteCategory,
} from './menuApi';
import { useApiQuery } from '../../core/useApiQuery';
import { PageHeader, Card, Loader, ErrorState } from '../../components/ui';
import VariantsEditor from './VariantsEditor';
import { IMAGE_BASE_URL } from '../../core/config';

const money = (v) => `₹${Number(v || 0).toFixed(0)}`;
const isOn = (s) => s === 1 || s === '1' || s === true;
const UNITS = ['NOS', 'PLATE', 'KG'];

function ImageField({ existing, file, onFile }) {
  const preview = file ? URL.createObjectURL(file) : (existing ? `${IMAGE_BASE_URL}${existing}` : null);
  return (
    <label className="flex cursor-pointer items-center gap-3">
      <div className="flex h-16 w-16 items-center justify-center overflow-hidden rounded-xl border border-dashed border-slate-300 bg-slate-50 text-slate-400">
        {preview ? <img src={preview} alt="" className="h-full w-full object-cover" /> : <ImagePlus className="h-5 w-5" />}
      </div>
      <span className="text-xs font-bold text-primary">{existing || file ? 'Change image' : 'Upload image'}</span>
      <input type="file" accept="image/*" className="hidden" onChange={(e) => onFile(e.target.files?.[0] || null)} />
    </label>
  );
}

function ItemModal({ item, categories, onClose, onSaved }) {
  const editing = !!item?.id;
  const [form, setForm] = useState({
    name: item?.name || '', category_id: item?.category_id || categories[0]?.id || '',
    price: item?.price ?? '', half_price: item?.half_price ?? '', unit: (item?.unit || 'NOS').toUpperCase(),
    gst_applicable: isOn(item?.gst_applicable) ? 1 : 0, gst_rate: item?.gst_rate ?? '', description: item?.description || '',
  });
  const [variants, setVariants] = useState(Array.isArray(item?.variants) ? item.variants : []);
  const [file, setFile] = useState(null);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState('');
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault();
    if (!form.name.trim() || form.price === '') { setErr('Name and price are required.'); return; }
    setSaving(true); setErr('');
    try {
      const payload = {
        ...(editing ? { id: item.id } : {}), category_id: form.category_id, name: form.name.trim(),
        unit: form.unit, price: Number(form.price), half_price: form.half_price === '' ? 0 : Number(form.half_price),
        gst_applicable: form.gst_applicable ? 1 : 0, gst_rate: form.gst_applicable ? Number(form.gst_rate || 0) : 0,
        description: form.description, variants: variants.filter((v) => v.name?.trim()),
      };
      await (editing ? updateMenuItem(payload, file) : addMenuItem(payload, file));
      onSaved();
    } catch (e2) { setErr(e2?.message || 'Failed to save item.'); } finally { setSaving(false); }
  };

  return (
    <Modal onClose={onClose} title={editing ? 'Edit item' : 'New item'}>
      <form onSubmit={submit} className="space-y-3">
        {err && <p className="rounded-xl bg-red-50 px-3 py-2 text-sm font-semibold text-red-600">{err}</p>}
        <ImageField existing={item?.image} file={file} onFile={setFile} />
        <div className="grid grid-cols-2 gap-3">
          <label className="col-span-2 text-xs font-bold text-slate-600">Name
            <input value={form.name} onChange={set('name')} className="input" />
          </label>
          <label className="text-xs font-bold text-slate-600">Category
            <select value={form.category_id} onChange={set('category_id')} className="input">
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </label>
          <label className="text-xs font-bold text-slate-600">Unit
            <select value={form.unit} onChange={set('unit')} className="input">{UNITS.map((u) => <option key={u} value={u}>{u}</option>)}</select>
          </label>
          <label className="text-xs font-bold text-slate-600">Price (₹)<input type="number" value={form.price} onChange={set('price')} className="input" /></label>
          <label className="text-xs font-bold text-slate-600">Half price (₹)<input type="number" value={form.half_price} onChange={set('half_price')} className="input" /></label>
          <label className="col-span-2 flex items-center gap-2 text-xs font-bold text-slate-600">
            <input type="checkbox" checked={!!form.gst_applicable} onChange={(e) => setForm((f) => ({ ...f, gst_applicable: e.target.checked ? 1 : 0 }))} /> GST applicable
            {form.gst_applicable ? <input type="number" value={form.gst_rate} onChange={set('gst_rate')} placeholder="rate %" className="ml-2 w-24 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm" /> : null}
          </label>
        </div>
        <VariantsEditor label="Sub-categories (customization options)" value={variants} onChange={setVariants} />
        <button type="submit" disabled={saving} className="w-full rounded-2xl bg-primary py-3 font-bold text-white hover:bg-primary-dark disabled:opacity-60">
          {saving ? 'Saving…' : editing ? 'Save changes' : 'Add item'}
        </button>
      </form>
    </Modal>
  );
}

function CategoryModal({ category, onClose, onSaved }) {
  const editing = !!category?.id;
  const [name, setName] = useState(category?.name || '');
  const [subs, setSubs] = useState(Array.isArray(category?.subcategories) ? category.subcategories : []);
  const [file, setFile] = useState(null);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState('');

  const submit = async (e) => {
    e.preventDefault();
    if (!name.trim()) { setErr('Name is required.'); return; }
    setSaving(true); setErr('');
    try {
      const data = { ...(editing ? { id: category.id } : {}), name: name.trim(), subcategories: subs.filter((s) => s.name?.trim()) };
      await (editing ? updateCategory(data, file) : addCategory(data, file));
      onSaved();
    } catch (e2) { setErr(e2?.message || 'Failed to save category.'); } finally { setSaving(false); }
  };

  return (
    <Modal onClose={onClose} title={editing ? 'Edit category' : 'New category'}>
      <form onSubmit={submit} className="space-y-3">
        {err && <p className="rounded-xl bg-red-50 px-3 py-2 text-sm font-semibold text-red-600">{err}</p>}
        <label className="block text-xs font-bold text-slate-600">Name<input value={name} onChange={(e) => setName(e.target.value)} className="input" /></label>
        <VariantsEditor label="Sub-categories" value={subs} onChange={setSubs} />
        <button type="submit" disabled={saving} className="w-full rounded-2xl bg-primary py-3 font-bold text-white hover:bg-primary-dark disabled:opacity-60">
          {saving ? 'Saving…' : editing ? 'Save changes' : 'Add category'}
        </button>
      </form>
    </Modal>
  );
}

function Modal({ title, onClose, children }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto p-4">
      <div className="absolute inset-0 bg-slate-900/50" onClick={onClose} />
      <div className="relative z-10 my-8 w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl">
        <button onClick={onClose} className="absolute right-4 top-4 rounded-full bg-slate-100 p-2 hover:bg-slate-200"><X className="h-4 w-4" /></button>
        <h2 className="mb-4 text-lg font-black">{title}</h2>
        {children}
      </div>
      <style>{`.input{margin-top:4px;width:100%;border-radius:0.75rem;border:1px solid #e2e8f0;background:#f8fafc;padding:0.625rem 0.75rem;font-size:0.875rem;outline:none}.input:focus{border-color:var(--tw-primary,#FE701A);background:#fff}`}</style>
    </div>
  );
}

export default function MenuPage() {
  const [tab, setTab] = useState('items');
  const { data: items, loading, error, refetch } = useApiQuery(fetchMenu, []);
  const { data: categories, refetch: refetchCats } = useApiQuery(fetchCategories, []);
  const [itemModal, setItemModal] = useState(null);
  const [catModal, setCatModal] = useState(null);
  const [busy, setBusy] = useState(null);

  const grouped = useMemo(() => {
    const map = {};
    (Array.isArray(items) ? items : []).forEach((p) => { (map[p.category_name || 'Uncategorized'] ||= []).push(p); });
    return map;
  }, [items]);

  const toggle = async (p) => { setBusy(p.id); try { await setMenuStatus(p.id, isOn(p.status) ? 0 : 1); await refetch(); } finally { setBusy(null); } };
  const removeItem = async (p) => { if (!window.confirm(`Delete "${p.name}"?`)) return; setBusy(p.id); try { await deleteMenuItem(p.id); await refetch(); } finally { setBusy(null); } };
  const removeCat = async (c) => { if (!window.confirm(`Delete category "${c.name}"?`)) return; setBusy(`c${c.id}`); try { await deleteCategory(c.id); await refetchCats(); } finally { setBusy(null); } };

  return (
    <>
      <PageHeader
        title="Menu"
        subtitle="Items, categories & sub-categories"
        action={
          tab === 'items'
            ? <button onClick={() => setItemModal({})} className="flex items-center gap-2 rounded-full bg-primary px-4 py-2.5 text-sm font-bold text-white hover:bg-primary-dark"><Plus className="h-4 w-4" /> New item</button>
            : <button onClick={() => setCatModal({})} className="flex items-center gap-2 rounded-full bg-primary px-4 py-2.5 text-sm font-bold text-white hover:bg-primary-dark"><Plus className="h-4 w-4" /> New category</button>
        }
      />

      <div className="mb-4 inline-flex rounded-2xl bg-slate-100 p-1">
        {['items', 'categories'].map((t) => (
          <button key={t} onClick={() => setTab(t)} className={`rounded-xl px-4 py-2 text-sm font-bold capitalize ${tab === t ? 'bg-white shadow-sm' : 'text-slate-500'}`}>{t}</button>
        ))}
      </div>

      {tab === 'items' ? (
        loading ? <Loader /> : error ? <ErrorState error={error} onRetry={refetch} /> : (
          <div className="space-y-6">
            {Object.entries(grouped).map(([cat, list]) => (
              <div key={cat}>
                <h2 className="mb-2 text-sm font-black uppercase tracking-wide text-slate-500">{cat}</h2>
                <Card className="p-0">
                  <div className="divide-y divide-slate-100">
                    {list.map((p) => (
                      <div key={p.id} className="flex items-center justify-between gap-3 px-4 py-3">
                        <div className="flex min-w-0 items-center gap-3">
                          <div className="h-11 w-11 shrink-0 overflow-hidden rounded-xl bg-slate-100">
                            {p.image ? <img src={`${IMAGE_BASE_URL}${p.image}`} alt="" className="h-full w-full object-cover" /> : null}
                          </div>
                          <div className="min-w-0">
                            <p className="truncate text-sm font-bold">{p.name}</p>
                            <p className="text-xs text-slate-400">
                              {money(p.price)}{Number(p.half_price) > 0 ? ` · ½ ${money(p.half_price)}` : ''} · {(p.unit || 'NOS').toUpperCase()}
                              {isOn(p.gst_applicable) ? ` · GST ${Number(p.gst_rate || 0)}%` : ''}
                              {Array.isArray(p.variants) && p.variants.length ? ` · ${p.variants.length} sub` : ''}
                            </p>
                          </div>
                        </div>
                        <div className="flex shrink-0 items-center gap-1.5">
                          <button onClick={() => toggle(p)} disabled={busy === p.id} className={`rounded-full px-2.5 py-1 text-[11px] font-bold ${isOn(p.status) ? 'bg-green-50 text-green-600' : 'bg-slate-100 text-slate-500'}`}>{isOn(p.status) ? 'Available' : 'Hidden'}</button>
                          <button onClick={() => setItemModal(p)} className="rounded-lg p-2 text-slate-500 hover:bg-slate-100"><Pencil className="h-4 w-4" /></button>
                          <button onClick={() => removeItem(p)} disabled={busy === p.id} className="rounded-lg p-2 text-red-400 hover:bg-red-50"><Trash2 className="h-4 w-4" /></button>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              </div>
            ))}
            {(Array.isArray(items) ? items : []).length === 0 && <Card><p className="py-10 text-center text-sm text-slate-400">No items yet.</p></Card>}
          </div>
        )
      ) : (
        <Card className="p-0">
          <div className="divide-y divide-slate-100">
            {(Array.isArray(categories) ? categories : []).map((c) => (
              <div key={c.id} className="flex items-center justify-between gap-3 px-5 py-3.5">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><Layers className="h-5 w-5" /></div>
                  <div>
                    <p className="text-sm font-bold">{c.name}</p>
                    <p className="text-xs text-slate-400">{Array.isArray(c.subcategories) ? c.subcategories.length : 0} sub-categor{(Array.isArray(c.subcategories) ? c.subcategories.length : 0) === 1 ? 'y' : 'ies'}</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5">
                  <button onClick={() => setCatModal(c)} className="rounded-lg p-2 text-slate-500 hover:bg-slate-100"><Pencil className="h-4 w-4" /></button>
                  <button onClick={() => removeCat(c)} disabled={busy === `c${c.id}`} className="rounded-lg p-2 text-red-400 hover:bg-red-50"><Trash2 className="h-4 w-4" /></button>
                </div>
              </div>
            ))}
            {(Array.isArray(categories) ? categories : []).length === 0 && <p className="py-10 text-center text-sm text-slate-400">No categories yet.</p>}
          </div>
        </Card>
      )}

      {itemModal && <ItemModal item={itemModal.id ? itemModal : null} categories={categories || []} onClose={() => setItemModal(null)} onSaved={() => { setItemModal(null); refetch(); }} />}
      {catModal && <CategoryModal category={catModal.id ? catModal : null} onClose={() => setCatModal(null)} onSaved={() => { setCatModal(null); refetchCats(); refetch(); }} />}
    </>
  );
}
