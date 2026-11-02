// Fills each [data-downloads="<package>"] with that package's download count from /api/downloads (counted on
// Cloudflare as Sileo, Zebra and other package managers fetch the .deb). With no count yet, no API (as on
// GitHub Pages) or no script, the element stays hidden: the page never shows a number it was not given.
(() => {
  const spots = document.querySelectorAll('[data-downloads]');
  if (!spots.length || !window.fetch) return;
  const number = new Intl.NumberFormat('vi-VN');
  const names = { sileo: 'Sileo', zebra: 'Zebra', cydia: 'Cydia', installer: 'Installer', apt: 'APT', web: 'trình duyệt', other: 'khác' };
  fetch('/api/downloads', { headers: { Accept: 'application/json' } })
    .then(response => (response.ok ? response.json() : Promise.reject(response.status)))
    .then(data => spots.forEach(spot => {
      const entry = data && data.packages && data.packages[spot.dataset.downloads];
      if (!entry || !(entry.total > 0)) return;
      if (spot.hasAttribute('data-split')) {
        const parts = Object.entries(entry.clients).sort((a, b) => b[1] - a[1])
          .map(([client, count]) => (names[client] || client) + ' ' + number.format(count));
        spot.textContent = number.format(entry.total) + (parts.length > 1 ? ' (' + parts.join(', ') + ')' : ' qua ' + parts[0].replace(/ [\d.]+$/, ''));
      } else {
        spot.textContent = number.format(entry.total) + ' lượt tải';
      }
      (spot.closest('[data-downloads-row]') || spot).hidden = false;
    }))
    .catch(() => {});
})();
