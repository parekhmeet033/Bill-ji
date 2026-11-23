// Theme manager for BillJi Web App
// Supports 'light', 'dark', and 'system' modes.

export function applyTheme(theme) {
  const root = document.documentElement;
  const isDark =
    theme === 'dark' ||
    (theme === 'system' && window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);

  if (isDark) {
    root.classList.add('dark');
  } else {
    root.classList.remove('dark');
  }
}

export function initTheme() {
  const saved = localStorage.getItem('billji_theme') || 'system';
  applyTheme(saved);

  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      const current = localStorage.getItem('billji_theme') || 'system';
      if (current === 'system') {
        applyTheme('system');
      }
    });
  }
}
