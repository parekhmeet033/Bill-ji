/**
 * Shared Validation Utilities for BillJi Web Application
 * Ensures consistent frontend and backend validation rules.
 */

/**
 * Gets today's date in local YYYY-MM-DD format.
 */
export function getTodayDateString() {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Validates Email address format.
 * Rules:
 * - Trims leading & trailing spaces
 * - Rejects empty email
 * - Rejects multiple consecutive dots (e.g., '..')
 * - Rejects spaces or disallowed characters
 * - Validates proper email format regex: username@domain.tld
 *
 * @param {string} email
 * @returns {string|null} Error message or null if valid
 */
export function validateEmail(email) {
  if (!email || typeof email !== 'string') {
    return 'Email is required.';
  }

  const trimmed = email.trim();
  if (trimmed.length === 0) {
    return 'Email is required.';
  }

  // Prevent internal spaces
  if (/\s/.test(trimmed)) {
    return 'Please enter a valid email address.';
  }

  // Prevent multiple consecutive dots (e.g. user..name@domain.com or domain..com)
  if (/\.\./.test(trimmed)) {
    return 'Please enter a valid email address.';
  }

  // Standard proper RFC-compliant email regex pattern
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmed)) {
    return 'Please enter a valid email address.';
  }

  return null;
}

/**
 * Sanitizes mobile input to contain numeric digits only.
 * @param {string} val
 * @returns {string} Only numeric digits
 */
export function sanitizeMobileInput(val) {
  if (!val) return '';
  return val.replace(/\D/g, '').slice(0, 10);
}

/**
 * Validates Mobile Number format.
 * Rules:
 * - Numeric input only
 * - 10 digits (Standard mobile number starting with valid digit 6-9 or 10 digits)
 *
 * @param {string} mobile
 * @returns {string|null} Error message or null if valid
 */
export function validateMobile(mobile) {
  if (!mobile || typeof mobile !== 'string') {
    return 'Mobile number is required.';
  }

  const trimmed = mobile.trim();
  if (trimmed.length === 0) {
    return 'Mobile number is required.';
  }

  // Check numeric only
  if (!/^\d+$/.test(trimmed)) {
    return 'Please enter a valid mobile number.';
  }

  // 10-digit mobile validation (e.g. Indian standard 6-9 prefix or standard 10 digits)
  const mobileRegex = /^[6-9]\d{9}$/;
  if (!mobileRegex.test(trimmed)) {
    return 'Please enter a valid mobile number.';
  }

  return null;
}

/**
 * Validates Demo Booking Date.
 * Rules:
 * - Required date
 * - Must be today or any future date (past dates rejected)
 *
 * @param {string} dateStr YYYY-MM-DD
 * @returns {string|null} Error message or null if valid
 */
export function validateBookingDate(dateStr) {
  if (!dateStr || typeof dateStr !== 'string' || dateStr.trim() === '') {
    return 'Demo date is required.';
  }

  const trimmedDate = dateStr.trim();
  const todayStr = getTodayDateString();

  // Compare YYYY-MM-DD strings directly for accurate local date comparison
  if (trimmedDate < todayStr) {
    return 'Please select today or a future date.';
  }

  // Verify it's a valid date
  const timestamp = Date.parse(trimmedDate);
  if (isNaN(timestamp)) {
    return 'Please select a valid date.';
  }

  return null;
}

/**
 * Generic required field validation helper.
 */
export function validateRequired(val, fieldName = 'Field') {
  if (!val || typeof val !== 'string' || val.trim() === '') {
    return `${fieldName} is required.`;
  }
  return null;
}
