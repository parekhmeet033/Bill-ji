import { apiClient } from '../../core/apiClient';

// ---- Items ----
export async function fetchMenu() {
  const res = await apiClient.post('menu-list', {});
  return Array.isArray(res?.product) ? res.product : (Array.isArray(res?.data) ? res.data : (Array.isArray(res) ? res : []));
}

export async function setMenuStatus(productId, status) {
  return apiClient.post('menu-status', { product_id: productId, status });
}

export async function deleteMenuItem(productId) {
  return apiClient.post('menu-destroy', { product_id: productId });
}

// Build multipart FormData for an item (image optional; variants as JSON).
function itemForm(payload, imageFile) {
  const fd = new FormData();
  Object.entries(payload).forEach(([k, v]) => {
    if (v === undefined || v === null) return;
    fd.append(k, k === 'variants' ? JSON.stringify(v) : String(v));
  });
  if (imageFile) fd.append('image', imageFile);
  return fd;
}

// POST /api/menu-add (multipart) — supports an image and sub-category variants.
export async function addMenuItem(payload, imageFile) {
  return apiClient.postForm('menu-add', itemForm(payload, imageFile));
}

// POST /api/menu-update (multipart)
export async function updateMenuItem(payload, imageFile) {
  return apiClient.postForm('menu-update', itemForm(payload, imageFile));
}

// ---- Categories & sub-categories ----
export async function fetchCategories() {
  const res = await apiClient.post('category-list', {});
  return Array.isArray(res?.data) ? res.data : (Array.isArray(res) ? res : []);
}

function categoryForm({ id, name, subcategories }, imageFile) {
  const fd = new FormData();
  if (id != null) fd.append('id', String(id));
  fd.append('name', name || '');
  fd.append('subcategories', JSON.stringify(subcategories || []));
  if (imageFile) fd.append('image', imageFile);
  return fd;
}

export async function addCategory(data, imageFile) {
  return apiClient.postForm('category-add', categoryForm(data, imageFile));
}

export async function updateCategory(data, imageFile) {
  return apiClient.postForm('category-update', categoryForm(data, imageFile));
}

export async function deleteCategory(id) {
  return apiClient.post('category-destroy', { id });
}
