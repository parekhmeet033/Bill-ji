/**
 * Server-Side Validation Utilities for Lineless Web Application
 * Enforces strict backend validation for Email, Mobile Number, and Demo Booking Date.
 */

function getTodayDateString() {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function validateEmail(email) {
  if (!email || typeof email !== 'string') {
    return 'Email is required.';
  }

  const trimmed = email.trim();
  if (trimmed.length === 0) {
    return 'Email is required.';
  }

  if (/\s/.test(trimmed)) {
    return 'Please enter a valid email address.';
  }

  if (/\.\./.test(trimmed)) {
    return 'Please enter a valid email address.';
  }

  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmed)) {
    return 'Please enter a valid email address.';
  }

  return null;
}

function validateMobile(mobile) {
  if (!mobile || typeof mobile !== 'string') {
    return 'Mobile number is required.';
  }

  const trimmed = mobile.trim();
  if (trimmed.length === 0) {
    return 'Mobile number is required.';
  }

  if (!/^\d+$/.test(trimmed)) {
    return 'Please enter a valid mobile number.';
  }

  const mobileRegex = /^[6-9]\d{9}$/;
  if (!mobileRegex.test(trimmed)) {
    return 'Please enter a valid mobile number.';
  }

  return null;
}

function validateBookingDate(dateStr) {
  if (!dateStr || typeof dateStr !== 'string' || dateStr.trim() === '') {
    return 'Demo date is required.';
  }

  const trimmedDate = dateStr.trim();
  const todayStr = getTodayDateString();

  if (trimmedDate < todayStr) {
    return 'Please select today or a future date.';
  }

  const timestamp = Date.parse(trimmedDate);
  if (isNaN(timestamp)) {
    return 'Please select a valid date.';
  }

  return null;
}

function validateRequired(val, fieldName = 'Field') {
  if (!val || typeof val !== 'string' || val.trim() === '') {
    return `${fieldName} is required.`;
  }
  return null;
}

module.exports = {
  getTodayDateString,
  validateEmail,
  validateMobile,
  validateBookingDate,
  validateRequired
};
