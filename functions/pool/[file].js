// Serves a package from pool/ and counts it. A GET that returns the whole file, or its first bytes, adds one to
// the count for that package, version and package manager. Nothing about the device or its address is kept.
const CLIENTS = [
  ['sileo', /Sileo/i],
  ['zebra', /Zebra/i],
  ['cydia', /Cydia|Telesphoreo/i],
  ['installer', /Installer/i],
  ['apt', /APT/i],
  ['web', /Mozilla/i],
];
const DEB = /^([a-z0-9][a-z0-9+.-]+)_([^_/]+)_[a-z0-9-]+\.deb$/;
const COUNT = 'INSERT INTO downloads (package, version, client, count) VALUES (?1, ?2, ?3, 1) ' +
  'ON CONFLICT (package, version, client) DO UPDATE SET count = count + 1';

export async function onRequest(context) {
  const { request, env, params } = context;
  const response = await env.ASSETS.fetch(request);
  const name = DEB.exec(String(params.file || ''));
  const range = request.headers.get('Range');
  const whole = !range || /^bytes=0-/.test(range);
  if (request.method === 'GET' && name && whole && (response.status === 200 || response.status === 206)) {
    const agent = request.headers.get('User-Agent') || '';
    const client = (CLIENTS.find(([, test]) => test.test(agent)) || ['other'])[0];
    context.waitUntil(env.DB.prepare(COUNT).bind(name[1], name[2], client).run().catch(() => {}));
  }
  return response;
}
