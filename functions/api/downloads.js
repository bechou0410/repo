// The download counts per package: the total and the split by package manager, as JSON for the pages.
export async function onRequestGet({ env }) {
  const { results } = await env.DB.prepare(
    'SELECT package, client, SUM(count) AS count FROM downloads GROUP BY package, client').all();
  const packages = {};
  for (const row of results) {
    const entry = packages[row.package] || (packages[row.package] = { total: 0, clients: {} });
    entry.total += row.count;
    entry.clients[row.client] = row.count;
  }
  return new Response(JSON.stringify({ packages }), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'public, max-age=60',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
