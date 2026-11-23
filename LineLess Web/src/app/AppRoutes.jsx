import { Routes, Route } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute';
import AppShell from './layout/AppShell';
import DashboardPage from './features/dashboard/DashboardPage';
import OrdersPage from './features/orders/OrdersPage';
import MenuPage from './features/menu/MenuPage';
import ReportsPage from './features/reports/ReportsPage';
import SettingsPage from './features/settings/SettingsPage';
import TablesPage from './features/tables/TablesPage';
import TableOrderPage from './features/tables/TableOrderPage';
import PosPage from './features/tables/PosPage';
import KdsPage from './features/kds/KdsPage';
import SupportPage from './features/support/SupportPage';

// All vendor-app routes live under /app and are gated by ProtectedRoute.
export default function AppRoutes() {
  return (
    <ProtectedRoute>
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<DashboardPage />} />
          <Route path="orders" element={<OrdersPage />} />
          <Route path="tables" element={<TablesPage />} />
          <Route path="tables/:tableNo" element={<TableOrderPage />} />
          <Route path="pos" element={<PosPage />} />
          <Route path="menu" element={<MenuPage />} />
          <Route path="kds" element={<KdsPage />} />
          <Route path="reports" element={<ReportsPage />} />
          <Route path="settings" element={<SettingsPage />} />
          <Route path="support" element={<SupportPage />} />
          <Route path="settings/support" element={<SupportPage />} />
        </Route>
      </Routes>
    </ProtectedRoute>
  );
}
