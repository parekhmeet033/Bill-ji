import { X, Receipt, Search, Clock, CheckCircle2, Flame } from 'lucide-react';
import { useState } from 'react';

export default function KdsItemDetailsSheet({ item, onClose, onUpdateStatus }) {
  const [search, setSearch] = useState('');
  const [updatingId, setUpdatingId] = useState(null);

  const filteredOrders = (item?.associatedOrders || []).filter(order =>
    order.token_number?.toString().includes(search) ||
    order.token_no?.toString().includes(search) ||
    order.customer_name?.toLowerCase().includes(search.toLowerCase())
  );

  const handleStatusChange = async (orderId, nextStatus) => {
    setUpdatingId(orderId);
    try {
      if (onUpdateStatus) {
        await onUpdateStatus(orderId, nextStatus);
      }
    } finally {
      setUpdatingId(null);
    }
  };

  const getElapsedTime = (dateStr) => {
    if (!dateStr) return '';
    const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 60000);
    if (diff < 1) return 'Just now';
    if (diff === 1) return '1m ago';
    return `${diff}m ago`;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center sm:p-4">
      <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm transition-opacity" onClick={onClose} />
      <div className="relative z-10 flex h-[85vh] w-full flex-col overflow-hidden rounded-t-3xl bg-white shadow-2xl transition-transform dark:border-slate-800 dark:bg-slate-900 sm:h-auto sm:max-h-[85vh] sm:max-w-2xl sm:rounded-3xl">

        {/* Header */}
        <div className="flex shrink-0 items-start justify-between border-b border-slate-100 p-5 dark:border-slate-800 sm:p-6">
          <div className="pr-4">
            <h2 className="text-xl font-black text-slate-800 dark:text-slate-100">{item.name}</h2>
            <p className="mt-1 text-sm font-semibold text-primary">
              Total Required: {item.totalQuantity % 1 === 0 ? item.totalQuantity : item.totalQuantity.toFixed(1)} {item.unit || 'NOS'}
            </p>
          </div>
          <button
            onClick={onClose}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-100 text-slate-500 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:hover:bg-slate-700"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex flex-1 flex-col overflow-hidden bg-slate-50/50 dark:bg-slate-950/40">
          <div className="px-5 pb-2 pt-4 sm:px-6">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Search token or customer in recent orders..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-9 pr-4 text-sm outline-none transition-colors focus:border-primary focus:ring-1 focus:ring-primary dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder-slate-500"
              />
            </div>
            <div className="mt-4 flex items-center justify-between">
              <p className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Recent Orders Containing This Dish ({filteredOrders.length})
              </p>
            </div>
          </div>

          <div className="flex-1 overflow-y-auto p-5 pt-2 sm:px-6">
            {filteredOrders.length === 0 ? (
              <div className="py-12 text-center text-sm text-slate-400">
                No orders match your search.
              </div>
            ) : (
              <div className="space-y-3">
                {filteredOrders.map((order, index) => {
                  const id = order.order_id || order.id;
                  const matchedList = order.matchedItems && order.matchedItems.length > 0
                    ? order.matchedItems
                    : (order.items || []).filter(i =>
                        (i.name || i.product_name || '').trim().toLowerCase() === item.name.toLowerCase()
                      );
                  const totalTicketQty = matchedList.reduce((sum, it) => sum + parseFloat(it.quantity || it.qty || 0), 0);
                  const isDineIn = String(order.order_type || '').toLowerCase() === 'dine_in';
                  const tokenText = isDineIn
                    ? `Table #${order.table_no || order.token_no || order.token_number || ''}`
                    : `Token #${order.token_no || order.token_number || ''}`;
                  const status = String(order.status || order.order_status || 'pending').toLowerCase();
                  const isRunning = status === 'running' || status === 'preparing';

                  return (
                    <div
                      key={`${id}-${index}`}
                      className="flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md dark:border-slate-800 dark:bg-slate-900"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex min-w-0 flex-1 items-start gap-3">
                          <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl font-black ${
                            isRunning
                              ? 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300'
                              : 'bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300'
                          }`}>
                            <Receipt className="h-5 w-5" />
                          </div>
                          <div className="min-w-0">
                            <div className="flex flex-wrap items-center gap-2">
                              <span className="text-sm font-black text-slate-800 dark:text-slate-100">
                                {tokenText}
                              </span>
                              <span className={`inline-flex items-center rounded-md px-2 py-0.5 text-[11px] font-bold ${
                                isRunning
                                  ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/40 dark:text-blue-400'
                                  : 'bg-amber-50 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400'
                              }`}>
                                {isRunning ? 'Cooking' : 'Pending'}
                              </span>
                              <span className="text-xs text-slate-400">
                                · {order.customer_name || 'Walk-in'}
                              </span>
                            </div>
                            <div className="mt-1 flex items-center gap-2 text-xs text-slate-400">
                              <Clock className="h-3.5 w-3.5" />
                              <span>{getElapsedTime(order.order_date || order.created_at)}</span>
                            </div>
                          </div>
                        </div>

                        {/* Dish Quantity in this order */}
                        <div className="flex items-baseline gap-1 rounded-xl bg-primary/10 px-3 py-1.5 text-primary">
                          <span className="text-[10px] font-bold uppercase tracking-wider">Qty</span>
                          <span className="text-lg font-black">{totalTicketQty % 1 === 0 ? totalTicketQty : totalTicketQty.toFixed(1)}</span>
                        </div>
                      </div>

                      {/* Line variations (Half, Full, Customizations) */}
                      {matchedList.length > 0 && (
                        <div className="space-y-1.5">
                          {matchedList.map((mItem, mIdx) => (
                            <div key={mIdx} className="flex items-center justify-between rounded-xl bg-slate-50 px-3 py-2 text-xs font-semibold dark:bg-slate-800">
                              <div className="flex items-center gap-2">
                                <span className="font-black text-primary">{parseFloat(mItem.quantity || mItem.qty || 1)}×</span>
                                <span className="text-slate-800 dark:text-slate-200">{mItem.name || mItem.product_name}</span>
                                {mItem.note && (
                                  <span className="rounded-md bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-800 dark:bg-amber-900/50 dark:text-amber-300">
                                    {mItem.note}
                                  </span>
                                )}
                              </div>
                              <span className="text-xs text-slate-400">₹{mItem.price}</span>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* General Order Note if any */}
                      {(order.special_note || order.order_note) && (
                        <div className="rounded-xl border border-amber-200/60 bg-amber-50/70 p-2 text-xs text-amber-900 dark:border-amber-900/30 dark:bg-amber-950/30 dark:text-amber-200">
                          <span className="font-bold uppercase tracking-wide">Order note:</span> {order.special_note || order.order_note}
                        </div>
                      )}

                      {/* Status Action Buttons */}
                      {onUpdateStatus && (
                        <div className="flex items-center justify-end gap-2 border-t border-slate-100 pt-3 dark:border-slate-800">
                          {!isRunning && (
                            <button
                              disabled={updatingId === id}
                              onClick={() => handleStatusChange(id, 'running')}
                              className="inline-flex items-center gap-1.5 rounded-xl bg-blue-50 px-3.5 py-1.5 text-xs font-bold text-blue-600 transition-colors hover:bg-blue-100 disabled:opacity-50 dark:bg-blue-950/60 dark:text-blue-300 dark:hover:bg-blue-900/60"
                            >
                              <Flame className="h-3.5 w-3.5" />
                              Start Cooking
                            </button>
                          )}
                          <button
                            disabled={updatingId === id}
                            onClick={() => handleStatusChange(id, 'completed')}
                            className="inline-flex items-center gap-1.5 rounded-xl bg-green-600 px-4 py-1.5 text-xs font-bold text-white shadow-sm transition-colors hover:bg-green-700 disabled:opacity-50"
                          >
                            <CheckCircle2 className="h-3.5 w-3.5" />
                            Mark Ready
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
