/**
 * Minimal i18n for API messages.
 *
 * Translations are keyed by their English text (see src/locales/*.json), so the
 * existing English messages the controllers already pass get localized
 * automatically. Anything missing falls back to the original English string.
 */
const hi = require('../locales/hi.json');
const gu = require('../locales/gu.json');

const DICTIONARIES = { hi, gu };
const SUPPORTED = ['en', 'hi', 'gu'];
const DEFAULT_LANG = 'en';

/**
 * Resolve the request language from an `Accept-Language` header.
 * Accepts values like `hi`, `hi-IN`, `en,hi;q=0.9` → returns `en` | `hi` | `gu`.
 */
function pickLang(acceptLanguage) {
  if (!acceptLanguage) return DEFAULT_LANG;
  const first = String(acceptLanguage).split(',')[0].trim().slice(0, 2).toLowerCase();
  return SUPPORTED.includes(first) ? first : DEFAULT_LANG;
}

/**
 * Translate an English message to `lang`, falling back to English when the
 * language is unsupported or the key is missing.
 */
function translate(lang, message) {
  if (!message || lang === DEFAULT_LANG) return message;
  const dict = DICTIONARIES[lang];
  if (dict && Object.prototype.hasOwnProperty.call(dict, message)) {
    return dict[message];
  }
  return message; // English fallback
}

module.exports = { pickLang, translate, SUPPORTED, DEFAULT_LANG };
