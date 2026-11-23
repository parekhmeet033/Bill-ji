import { useCallback, useEffect, useState, useMemo } from 'react';
import { ChefHat, Clock3, CheckCircle2, Radio, Layers, Flame, Utensils } from 'lucide-react';
import { fetchDashboard, updateOrderStatus } from '../dashboard/dashboardApi';
import { useApiQuery } from '../../core/useApiQuery';
import { useRealtime } from '../../core/useRealtime';
import { PageHeader, Loader, ErrorState } from '../../components/ui';
import KdsItemDetailsSheet from './widgets/KdsItemDetailsSheet';

export default function KdsPage() {
  const [viewMode, setViewMode] = useState('items'); // 'items' | 'tickets'
  const [selectedItem, setSelectedItem] = useState(null);
  const [updatingId, setUpdatingId] = useState(null);

  // Use the exact same data source as the Dashboard's Recent Orders
  const { data, loading, error, refetch } = useApiQuery(fetchDashboard, []);

  // Realtime: automatically updates whenever a new order is placed or status changes
  useRealtime(refetch);

  // Safety-net poll (every 15s) to guarantee live synchronization
  useEffect(() => {
    const id = setInterval(refetch, 15000);
    return () => clearInterval(id);
  }, [refetch]);

  // Extract recent orders from the dashboard response
  const recentOrders = useMemo(() => {
    return Array.isArray(data?.recent_orders) ? data.recent_orders : [];
  }, [data]);

  // Active kitchen orders (pending, running, preparing) from Recent Orders
  // Dispatched and cancelled orders are excluded; completed orders clear from kitchen queue
  const activeOrders = useMemo(() => {
    return recentOrders.filter((o) => {
      const s = String(o.status || o.order_status || '').toLowerCase();
      return s === 'pending' || s === 'running' || s === 'preparing';
    });
  }, [recentOrders]);

  // Aggregate dishes across active kitchen orders
  const aggregatedItems = useMemo(() => {
    const itemsMap = {};
    activeOrders.forEach(order => {
      const orderId = order.order_id || order.id;
      (order.items || []).forEach(item => {
        const name = (item.name || item.product_name || 'Unknown Item').trim();
        const qty = parseFloat(item.quantity || item.qty || 0);
        const note = (item.note || '').trim();

        if (!itemsMap[name]) {
          itemsMap[name] = {
            name,
            totalQuantity: 0,
            unit: item.unit || 'NOS',
            associatedOrders: [],
            portions: {}
          };
        }
        itemsMap[name].totalQuantity += qty;

        // Breakdown note/portion
        const pKey = note || 'Standard';
        itemsMap[name].portions[pKey] = (itemsMap[name].portions[pKey] || 0) + qty;

        // Ensure order is not duplicated in associatedOrders
        let existingOrder = itemsMap[name].associatedOrders.find(
          o => (o.order_id || o.id) === orderId
        );
        if (!existingOrder) {
          existingOrder = {
            ...order,
            matchedItems: []
          };
          itemsMap[name].associatedOrders.push(existingOrder);
        }
        existingOrder.matchedItems.push(item);
      });
    });

    return Object.values(itemsMap).sort((a, b) => b.totalQuantity - a.totalQuantity);
  }, [activeOrders]);

  // Sync open item details sheet if data refreshes
  useEffect(() => {
    if (selectedItem) {
      const fresh = aggregatedItems.find(i => i.name.toLowerCase() === selectedItem.name.toLowerCase());
      if (fresh) {
        setSelectedItem(fresh);
      } else {
        setSelectedItem(null);
      }
    }
  }, [aggregatedItems, selectedItem]);

  // Update order status in kitchen (pending -> running -> completed)
  const handleUpdateStatus = async (orderId, newStatus) => {
    setUpdatingId(orderId);
    try {
      await updateOrderStatus(orderId, newStatus);
      await refetch();
    } catch (err) {
      console.error('Failed to update order status from KDS:', err);
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
    <>
      <PageHeader
        title="Kitchen Display (KDS)"
        subtitle="Live kitchen board connected to Recent Orders"
        action={
          <div className="flex items-center gap-3">
            {/* View Mode Toggle */}
            <div className="flex items-center rounded-xl border border-slate-200 bg-white p-1 text-xs font-bold dark:border-slate-800 dark:bg-slate-900">
              <button
                onClick={() => setViewMode('items')}
                className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 transition-colors ${
                  viewMode === 'items'
                    ? 'bg-primary text-white shadow-sm'
                    : 'text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white'
                }`}
              >
                <Layers className="h-3.5 w-3.5" />
                <span>Grouped Dishes ({aggregatedItems.length})</span>
              </button>
              <button
                onClick={() => setViewMode('tickets')}
                className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 transition-colors ${
                  viewMode === 'tickets'
                    ? 'bg-primary text-white shadow-sm'
                    : 'text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white'
                }`}
              >
                <Utensils className="h-3.5 w-3.5" />
                <span>Recent Orders ({activeOrders.length})</span>
              </button>
            </div>

            <span className="flex items-center gap-1.5 rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-bold text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-400">
              <Radio className="h-3.5 w-3.5 animate-pulse" /> Live KDS
            </span>
          </div>
        }
      />

      {loading ? (
        <Loader />
      ) : error ? (
        <ErrorState error={error} onRetry={refetch} />
      ) : activeOrders.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-slate-100 dark:bg-slate-800/80">
            <ChefHat className="h-10 w-10 text-slate-400" />
          </div>
          <h3 className="mt-4 text-base font-bold text-slate-700 dark:text-slate-200">No active orders in kitchen</h3>
          <p className="mt-1 text-xs text-slate-400">
            Orders from Recent Orders will appear here automatically as soon as they are placed.
          </p>
        </div>
      ) : viewMode === 'items' ? (
        /* View 1: Grouped Dishes View */
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {aggregatedItems.map((item, idx) => (
            <button
              key={idx}
              onClick={() => setSelectedItem(item)}
              className="flex flex-col rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-sm transition-all hover:border-primary hover:shadow-md dark:border-slate-800 dark:bg-slate-900 dark:hover:border-primary"
            >
              <p className="line-clamp-2 min-h-[40px] text-sm font-bold text-slate-800 dark:text-slate-100">{item.name}</p>
              {item.portions && Object.keys(item.portions).length > 0 && (
                <div className="mt-1 flex flex-wrap gap-1">
                  {Object.entries(item.portions).map(([portionName, pQty], pIdx) => (
                    <span
                      key={pIdx}
                      className="rounded-md bg-slate-100 px-1.5 py-0.5 text-[10px] font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300"
                    >
                      {pQty % 1 === 0 ? pQty : pQty.toFixed(1)}× {portionName}
                    </span>
                  ))}
                </div>
              )}
              <div className="mt-3 flex w-full items-end justify-between border-t border-slate-100 pt-3 dark:border-slate-800">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wide text-slate-400">Total Required</p>
                  <p className="text-xl font-black text-primary">
                    {item.totalQuantity % 1 === 0 ? item.totalQuantity : item.totalQuantity.toFixed(1)}{' '}
                    <span className="text-xs font-semibold">{item.unit}</span>
                  </p>
                </div>
                <div className="flex items-center gap-1.5 rounded-lg bg-blue-50 px-2.5 py-1 text-xs font-bold text-blue-600 dark:bg-blue-950/60 dark:text-blue-300">
                  <Layers className="h-3.5 w-3.5" />
                  <span>{item.associatedOrders.length} {item.associatedOrders.length === 1 ? 'ticket' : 'tickets'}</span>
                </div>
              </div>
            </button>
          ))}
        </div>
      ) : (
        /* View 2: Live Recent Order Tickets */
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {activeOrders.map((order) => {
            const id = order.order_id || order.id;
            const isDineIn = String(order.order_type || '').toLowerCase() === 'dine_in';
            const tokenText = isDineIn
              ? `Table #${order.table_no || order.token_no || order.token_number || ''}`
              : `Token #${order.token_no || order.token_number || ''}`;
            const status = String(order.status || order.order_status || 'pending').toLowerCase();
            const isRunning = status === 'running' || status === 'preparing';

            return (
              <div
                key={id}
                className="flex flex-col justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm transition-all hover:shadow-md dark:border-slate-800 dark:bg-slate-900"
              >
                <div>
                  {/* Ticket Header */}
                  <div className="flex items-start justify-between border-b border-slate-100 pb-3 dark:border-slate-800">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-base font-black text-slate-900 dark:text-white">
                          {tokenText}
                        </span>
                        <span className={`rounded-md px-2 py-0.5 text-[11px] font-bold ${
                          isRunning
                            ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/40 dark:text-blue-400'
                            : 'bg-amber-50 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400'
                        }`}>
                          {isRunning ? 'Cooking' : 'Pending'}
                        </span>
                      </div>
                      <p className="mt-0.5 text-xs font-medium text-slate-500 dark:text-slate-400">
                        {order.customer_name || 'Walk-in'} · {isDineIn ? 'Dine-in' : 'Takeaway'}
                      </p>
                    </div>

                    <div className="flex items-center gap-1 text-xs font-bold text-slate-400">
                      <Clock3 className="h-3.5 w-3.5" />
                      <span>{getElapsedTime(order.order_date || order.created_at)}</span>
                    </div>
                  </div>

                  {/* Special Note */}
                  {(order.special_note || order.order_note) && (
                    <div className="mt-2.5 rounded-lg border border-amber-200 bg-amber-50 p-2 text-xs font-semibold text-amber-900 dark:border-amber-900/40 dark:bg-amber-950/40 dark:text-amber-300">
                      <span className="font-bold uppercase tracking-wider">Note:</span> {order.special_note || order.order_note}
                    </div>
                  )}

                  {/* Item List */}
                  <div className="mt-3 space-y-2">
                    {(order.items || []).map((it, iIdx) => (
                      <div key={iIdx} className="flex items-start justify-between text-xs">
                        <div className="pr-2">
                          <p className="font-bold text-slate-800 dark:text-slate-200">
                            {it.name || it.product_name}
                          </p>
                          {it.note && (
                            <p className="text-[11px] italic text-amber-600 dark:text-amber-400">
                              ↳ {it.note}
                            </p>
                          )}
                        </div>
                        <span className="shrink-0 font-black text-primary">
                          {parseFloat(it.quantity || it.qty || 1)} {it.unit || ''}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Ticket Actions */}
                <div className="mt-5 flex items-center justify-end gap-2 border-t border-slate-100 pt-3 dark:border-slate-800">
                  {!isRunning ? (
                    <button
                      disabled={updatingId === id}
                      onClick={() => handleUpdateStatus(id, 'running')}
                      className="inline-flex items-center gap-1.5 rounded-xl bg-blue-50 px-3 py-1.5 text-xs font-bold text-blue-600 transition-colors hover:bg-blue-100 disabled:opacity-50 dark:bg-blue-950/60 dark:text-blue-300"
                    >
                      <Flame className="h-3.5 w-3.5" />
                      Start Cooking
                    </button>
                  ) : null}

                  <button
                    disabled={updatingId === id}
                    onClick={() => handleUpdateStatus(id, 'completed')}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-green-600 px-3.5 py-1.5 text-xs font-bold text-white shadow-sm transition-colors hover:bg-green-700 disabled:opacity-50"
                  >
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    Mark Ready
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {selectedItem && (
        <KdsItemDetailsSheet
          item={selectedItem}
          onClose={() => setSelectedItem(null)}
          onUpdateStatus={handleUpdateStatus}
        />
      )}
    </>
  );
}
