// Thermal-receipt printing for the browser.
//
// A web page cannot open a Bluetooth-Classic/raw-9100 thermal printer directly
// (Web Bluetooth is BLE-only; browsers can't open raw TCP sockets). The
// reliable path is OS printing: we render a thermal-width HTML ticket and call
// print(), which routes to whatever printer the device has — including a
// thermal/KOT printer installed as a system printer. For fully silent raw
// ESC/POS to a BT/LAN printer, a small local print-bridge agent is required
// (see the note in the Settings/print UI).

const esc = (s) => String(s ?? '').replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
const money = (v) => `Rs.${Number(v || 0).toFixed(0)}`;

function itemRows(items, { showPrice }) {
  return (items || [])
    .map((it) => {
      const qty = it.quantity ?? it.qty ?? 1;
      const name = it.name || it.product_name || 'Item';
      const note = (it.note || '').trim();
      const right = showPrice ? money(it.total ?? Number(it.price || 0) * Number(qty || 0)) : '';
      return `<div class="row"><span class="l">${esc(qty)} x ${esc(name)}</span><span class="r">${right}</span></div>${
        note ? `<div class="note">&gt;&gt; ${esc(note)}</div>` : ''
      }`;
    })
    .join('');
}

function shell(title, bodyHtml, widthMm = 72) {
  return `<!doctype html><html><head><meta charset="utf-8"><title>${esc(title)}</title>
<style>
  @page { size: ${widthMm}mm auto; margin: 0; }
  * { box-sizing: border-box; }
  body { width: ${widthMm}mm; margin: 0; padding: 6px 8px; font-family: 'Courier New', monospace; color: #000; font-size: 12px; }
  .center { text-align: center; }
  .b { font-weight: 700; }
  .big { font-size: 16px; font-weight: 800; }
  .sep { border-top: 1px dashed #000; margin: 6px 0; }
  .row { display: flex; justify-content: space-between; gap: 8px; }
  .row .l { flex: 1; }
  .row .r { white-space: nowrap; }
  .note { padding-left: 10px; font-weight: 700; }
  .muted { font-size: 11px; }
</style></head><body>${bodyHtml}<script>window.onload=function(){window.focus();window.print();setTimeout(function(){window.close();},300);};</script></body></html>`;
}

function openAndPrint(html) {
  // Hidden iframe keeps the vendor on the current page.
  const iframe = document.createElement('iframe');
  iframe.style.position = 'fixed';
  iframe.style.right = '0';
  iframe.style.bottom = '0';
  iframe.style.width = '0';
  iframe.style.height = '0';
  iframe.style.border = '0';
  document.body.appendChild(iframe);
  const doc = iframe.contentWindow.document;
  doc.open();
  doc.write(html);
  doc.close();
  setTimeout(() => { try { document.body.removeChild(iframe); } catch { /* ignore */ } }, 4000);
}

const labelFor = (o) => {
  const dineIn = String(o.order_type || '').toLowerCase() === 'dine_in';
  const no = o.token_no ?? o.token_number ?? '';
  return `${dineIn ? 'TABLE' : 'TOKEN'} ${no}`;
};

export function printKitchenTicket(order) {
  const body = `
    <div class="center big">KITCHEN COPY</div>
    <div class="sep"></div>
    <div class="center b">${esc(labelFor(order))}</div>
    ${order.customer_name ? `<div class="center b">Customer: ${esc(order.customer_name)}</div>` : ''}
    ${order.customer_mobile ? `<div class="center">Mobile: ${esc(order.customer_mobile)}</div>` : ''}
    <div class="center muted">${esc(new Date(order.order_date || order.created_at || Date.now()).toLocaleString())}</div>
    <div class="sep"></div>
    <div class="center b">ITEMS</div>
    <div class="sep"></div>
    ${itemRows(order.items, { showPrice: false })}
    ${order.special_note ? `<div class="sep"></div><div class="b">NOTE:</div><div>${esc(order.special_note)}</div>` : ''}
    <div class="sep"></div>`;
  openAndPrint(shell('Kitchen Copy', body));
}

export function printBill(order, { shopName = 'BillJi', gstin = '' } = {}) {
  const gst = Number(order.gst_amount || 0);
  const subtotal = Number(order.subtotal_amount || order.total_amount || 0);
  const body = `
    <div class="center">Bill Of Supply</div>
    <div class="center big">${esc(shopName)}</div>
    ${gstin ? `<div class="center b">GSTIN: ${esc(gstin)}</div><div class="center muted">Inclusive of supply</div>` : ''}
    <div class="sep"></div>
    <div class="center big">${esc(labelFor(order))}</div>
    <div class="sep"></div>
    <div class="row"><span class="l">Date</span><span class="r">${esc(new Date(order.order_date || order.created_at || Date.now()).toLocaleString())}</span></div>
    ${order.customer_name ? `<div class="center b">${esc(order.customer_name)}</div>` : ''}
    ${order.customer_mobile ? `<div class="center">${esc(order.customer_mobile)}</div>` : ''}
    <div class="sep"></div>
    <div class="center b">ITEMS</div>
    <div class="sep"></div>
    ${itemRows(order.items, { showPrice: true })}
    <div class="sep"></div>
    ${gst > 0 ? `<div class="row"><span class="l">Sub Total</span><span class="r">${money(subtotal)}</span></div>
    <div class="row"><span class="l">CGST</span><span class="r">${money(gst / 2)}</span></div>
    <div class="row"><span class="l">SGST</span><span class="r">${money(gst / 2)}</span></div>` : ''}
    <div class="row b"><span class="l">GRAND TOTAL</span><span class="r">${money(order.total_amount)}</span></div>
    <div class="sep"></div>
    <div class="center muted">Thank you! Powered by BillJi</div>`;
  openAndPrint(shell('Bill', body));
}
