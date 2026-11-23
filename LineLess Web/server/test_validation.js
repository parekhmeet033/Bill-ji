const assert = require('assert');
const {
  validateEmail,
  validateMobile,
  validateBookingDate,
  getTodayDateString
} = require('./utils/validation');

console.log('--- Running Validation Unit Tests ---');

// 1. Email Validation Tests
assert.strictEqual(validateEmail(''), 'Email is required.');
assert.strictEqual(validateEmail('   '), 'Email is required.');
assert.strictEqual(validateEmail('invalid-email'), 'Please enter a valid email address.');
assert.strictEqual(validateEmail('user..name@domain.com'), 'Please enter a valid email address.');
assert.strictEqual(validateEmail('user@domain..com'), 'Please enter a valid email address.');
assert.strictEqual(validateEmail('user @domain.com'), 'Please enter a valid email address.');
assert.strictEqual(validateEmail('  prashant@goalscripture.com  '), null);
console.log('✓ Email validation passed!');

// 2. Mobile Validation Tests
assert.strictEqual(validateMobile(''), 'Mobile number is required.');
assert.strictEqual(validateMobile('12345'), 'Please enter a valid mobile number.');
assert.strictEqual(validateMobile('987654321'), 'Please enter a valid mobile number.');
assert.strictEqual(validateMobile('98765432100'), 'Please enter a valid mobile number.');
assert.strictEqual(validateMobile('5876543210'), 'Please enter a valid mobile number.'); // Indian mobile starts with 6-9
assert.strictEqual(validateMobile('9974723326'), null);
console.log('✓ Mobile number validation passed!');

// 3. Demo Booking Date Validation Tests
const todayStr = getTodayDateString();
assert.strictEqual(validateBookingDate(''), 'Demo date is required.');
assert.strictEqual(validateBookingDate('2020-01-01'), 'Please select today or a future date.');
assert.strictEqual(validateBookingDate(todayStr), null);

// Future date test
const futureDate = new Date();
futureDate.setFullYear(futureDate.getFullYear() + 1);
const futureStr = futureDate.toISOString().split('T')[0];
assert.strictEqual(validateBookingDate(futureStr), null);
console.log('✓ Demo Booking Date validation passed!');

console.log('--- ALL VALIDATION TESTS PASSED SUCCESSFULLY ---');
