import { createContext, useContext, useState, useCallback, useMemo } from 'react';
import { loginRequest, logoutRequest } from './authApi';
import { getToken, getUser, saveSession, clearSession } from './authStorage';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => getToken());
  const [user, setUser] = useState(() => getUser());

  const login = useCallback(async (email, password) => {
    const { token: t, user: u } = await loginRequest(email, password);
    if (!t) throw new Error('No token returned by the server.');
    saveSession(t, u);
    setToken(t);
    setUser(u);
    return u;
  }, []);

  const logout = useCallback(async () => {
    try {
      await logoutRequest();
    } finally {
      clearSession();
      setToken(null);
      setUser(null);
    }
  }, []);

  const value = useMemo(
    () => ({ token, user, isAuthenticated: !!token, login, logout }),
    [token, user, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}
