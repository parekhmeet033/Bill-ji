import React, { Component, StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import { initTheme } from './utils/theme'

initTheme();

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }
  componentDidCatch(error, errorInfo) {
    console.error('React ErrorBoundary caught:', error, errorInfo);
    fetch('/_diagnostics/error', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type: 'ErrorBoundary',
        message: error?.message,
        stack: error?.stack,
        componentStack: errorInfo?.componentStack
      })
    }).catch(() => {});
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: 40, fontFamily: 'sans-serif', color: '#b91c1c', background: '#fef2f2', minHeight: '100vh' }}>
          <h1 style={{ fontSize: 24, fontWeight: 'bold' }}>Application Error</h1>
          <p style={{ marginTop: 10, fontSize: 16 }}>{String(this.state.error?.message || this.state.error)}</p>
          <pre style={{ marginTop: 20, padding: 20, background: '#fee2e2', borderRadius: 8, overflow: 'auto', fontSize: 12 }}>
            {this.state.error?.stack}
          </pre>
          <button
            onClick={() => { localStorage.clear(); window.location.href = '/'; }}
            style={{ marginTop: 20, padding: '10px 20px', background: '#b91c1c', color: 'white', border: 'none', borderRadius: 6, cursor: 'pointer' }}
          >
            Clear Local Storage & Reload
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>,
)
