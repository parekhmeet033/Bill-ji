import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from './AuthContext';

// Guards the vendor app: unauthenticated visitors are sent to /login and
// returned to where they were headed after signing in.
export default function ProtectedRoute({ children }) {
  const { isAuthenticated } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }
  return children;
}
