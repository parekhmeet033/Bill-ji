const path = require('path');
const bcrypt = require('bcryptjs');
const userRepository = require('../repositories/userRepository');
const { generateToken } = require('../utils/tokenGenerator');
const { COOKIE_NAME } = require('../middleware/adminAuthMiddleware');

const viewsDir = path.join(__dirname, '../views/admin');

function slugify(value) {
  return String(value || '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/[\s_]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

class AdminController {
  // ---- Pages ----
  loginPage(req, res) {
    res.sendFile(path.join(viewsDir, 'login.html'));
  }

  usersPage(req, res) {
    res.sendFile(path.join(viewsDir, 'users.html'));
  }

  dashboardPage(req, res) {
    res.sendFile(path.join(viewsDir, 'dashboard.html'));
  }

  async dashboardData(req, res) {
    try {
      const stats = await userRepository.getAdminDashboardStats();
      res.json({ status: true, success: true, data: stats });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  // ---- Auth actions ----
  async login(req, res) {
    const { email, password } = req.body;
    const render = (msg) =>
      res.redirect('/admin/login?error=' + encodeURIComponent(msg));

    if (!email || !password) return render('Email and password are required');

    const user = await userRepository.findByEmail(email);
    if (!user) return render('Invalid email or password');

    let ok = false;
    try {
      ok = await bcrypt.compare(password, user.password);
    } catch (_) {
      ok = false;
    }
    if (!ok && password === user.password) ok = true; // legacy plaintext fallback
    if (!ok) return render('Invalid email or password');

    const token = generateToken(user);
    res.cookie(COOKIE_NAME, token, {
      httpOnly: true,
      sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
    });
    res.redirect('/admin/users');
  }

  logout(req, res) {
    res.clearCookie(COOKIE_NAME);
    res.redirect('/admin/login');
  }

  me(req, res) {
    res.json({ status: true, success: true, data: req.admin });
  }

  // ---- Users JSON API ----
  async listUsers(req, res) {
    const users = await userRepository.getAllUsers(req.query.search || '');
    res.json({ status: true, success: true, data: users });
  }

  async createUser(req, res) {
    try {
      const { name, email, password, phone, role, slug, plan_start_date, plan_end_date, status } = req.body;
      if (!name || !email || !password) {
        return res.status(400).json({ status: false, success: false, message: 'Name, email and password are required' });
      }
      const existing = await userRepository.findByEmail(email);
      if (existing) {
        return res.status(409).json({ status: false, success: false, message: 'A user with this email already exists' });
      }
      const hashed = await bcrypt.hash(password, 10);
      const id = await userRepository.createUser({ name, email, password: hashed, phone, role: role || 'admin' });
      // Set the admin-panel fields that aren't part of the base insert.
      await userRepository.updateUser(id, {
        slug: slugify(slug || name),
        status: status === undefined ? 1 : (status ? 1 : 0),
        plan_start_date: plan_start_date || null,
        plan_end_date: plan_end_date || null
      });
      res.json({ status: true, success: true, message: 'User created', data: { id } });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  async updateUser(req, res) {
    try {
      const id = parseInt(req.params.id, 10);
      // NOTE: `name` is intentionally ignored here — the shop name cannot be edited.
      const { email, phone, role, password, slug, plan_start_date, plan_end_date, status } = req.body;
      const target = await userRepository.findById(id);
      if (!target) {
        return res.status(404).json({ status: false, success: false, message: 'User not found' });
      }
      if (email && email !== target.email) {
        const dup = await userRepository.findByEmail(email);
        if (dup && dup.id !== id) {
          return res.status(409).json({ status: false, success: false, message: 'Another user already uses this email' });
        }
      }
      const fields = {};
      if (email !== undefined) fields.email = email;
      if (phone !== undefined) fields.phone = phone || null;
      if (role !== undefined) fields.role = role;
      if (slug !== undefined) fields.slug = slugify(slug);
      if (status !== undefined) fields.status = status ? 1 : 0;
      if (plan_start_date !== undefined) fields.plan_start_date = plan_start_date || null;
      if (plan_end_date !== undefined) fields.plan_end_date = plan_end_date || null;
      if (password) fields.password = await bcrypt.hash(password, 10);
      await userRepository.updateUser(id, fields);
      res.json({ status: true, success: true, message: 'User updated' });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  async deleteUser(req, res) {
    try {
      const id = parseInt(req.params.id, 10);
      if (req.admin && req.admin.id === id) {
        return res.status(400).json({ status: false, success: false, message: 'You cannot delete the account you are logged in with' });
      }
      const affected = await userRepository.deleteUser(id);
      if (!affected) {
        return res.status(404).json({ status: false, success: false, message: 'User not found' });
      }
      res.json({ status: true, success: true, message: 'User deleted' });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }
}

module.exports = new AdminController();
