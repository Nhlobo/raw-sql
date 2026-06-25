const DEVICE_KEY = 'kutlwano_device_fingerprint';

export function getFingerprint() {
  let existing = localStorage.getItem(DEVICE_KEY);
  if (existing) return existing;

  existing = crypto.randomUUID();
  localStorage.setItem(DEVICE_KEY, existing);
  return existing;
}

export function getBrowserName() {
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes('edg')) return 'edge';
  if (ua.includes('firefox')) return 'firefox';
  if (ua.includes('chrome')) return 'chrome';
  if (ua.includes('safari')) return 'safari';
  return 'unknown';
}

export function getPlatformName() {
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes('windows')) return 'windows';
  if (ua.includes('android')) return 'android';
  if (ua.includes('iphone') || ua.includes('ipad')) return 'ios';
  if (ua.includes('mac')) return 'macos';
  if (ua.includes('linux')) return 'linux';
  return 'web';
}
