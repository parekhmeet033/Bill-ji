import { useEffect, useRef } from 'react';
import { subscribeRealtime } from './realtime';
import { useAuth } from '../auth/AuthContext';

// Calls `onUpdate` when a `dashboard.updated` event for THIS vendor arrives,
// or when the window/tab regains focus (e.g. after signing back in or switching tabs).
// Debounced so bursts of events trigger a single refresh.
export function useRealtime(onUpdate, { debounceMs = 400 } = {}) {
  const { user } = useAuth();
  const cb = useRef(onUpdate);
  cb.current = onUpdate;
  const myId = user?.id != null ? String(user.id) : null;

  useEffect(() => {
    // Refresh immediately whenever window/tab regains focus or visibility
    const handleFocus = () => {
      cb.current?.();
    };
    window.addEventListener('focus', handleFocus);
    const handleVisibility = () => {
      if (document.visibilityState === 'visible') handleFocus();
    };
    document.addEventListener('visibilitychange', handleVisibility);

    let timer = null;
    const unsub = subscribeRealtime((evt) => {
      if (evt.event !== 'dashboard.updated') return;
      const eventUserId = evt.data?.user_id != null ? String(evt.data.user_id) : null;
      // Allow updates for shared vendor accounts (admin: 1, super: 2)
      const isShared = (myId === '1' || myId === '2') && (eventUserId === '1' || eventUserId === '2');
      if (eventUserId && myId && eventUserId !== myId && !isShared) return;
      clearTimeout(timer);
      timer = setTimeout(() => cb.current?.(), debounceMs);
    });

    return () => {
      window.removeEventListener('focus', handleFocus);
      document.removeEventListener('visibilitychange', handleVisibility);
      clearTimeout(timer);
      unsub();
    };
  }, [myId, debounceMs]);
}
