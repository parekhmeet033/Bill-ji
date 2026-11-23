// Lightweight SVG donut chart (no chart library — keeps the bundle small).
// segments: [{ label, value, color }]
export default function Donut({ title, segments = [], size = 160, thickness = 22 }) {
  const total = segments.reduce((s, x) => s + (Number(x.value) || 0), 0);
  const r = (size - thickness) / 2;
  const c = size / 2;
  const circ = 2 * Math.PI * r;
  let offset = 0;

  return (
    <div className="flex items-center gap-5">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="shrink-0">
        <circle cx={c} cy={c} r={r} fill="none" stroke="#f1f5f9" strokeWidth={thickness} />
        {total > 0 && segments.map((s, i) => {
          const frac = (Number(s.value) || 0) / total;
          const len = frac * circ;
          const el = (
            <circle
              key={i}
              cx={c} cy={c} r={r} fill="none"
              stroke={s.color} strokeWidth={thickness}
              strokeDasharray={`${len} ${circ - len}`}
              strokeDashoffset={-offset}
              transform={`rotate(-90 ${c} ${c})`}
            />
          );
          offset += len;
          return el;
        })}
        <text x={c} y={c - 2} textAnchor="middle" className="fill-slate-800" style={{ fontSize: 20, fontWeight: 800 }}>{total}</text>
        <text x={c} y={c + 16} textAnchor="middle" className="fill-slate-400" style={{ fontSize: 10 }}>total</text>
      </svg>
      <div className="space-y-1.5">
        {title && <p className="mb-1 text-sm font-bold">{title}</p>}
        {segments.map((s, i) => (
          <div key={i} className="flex items-center gap-2 text-xs">
            <span className="h-2.5 w-2.5 rounded-full" style={{ background: s.color }} />
            <span className="font-semibold capitalize text-slate-600">{s.label}</span>
            <span className="ml-auto font-bold text-slate-500">{s.value}</span>
          </div>
        ))}
        {total === 0 && <p className="text-xs text-slate-400">No data.</p>}
      </div>
    </div>
  );
}
