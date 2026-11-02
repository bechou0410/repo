// Lề's page: the sign search, the hero's loop, the pinned frame and the add-source links.
(() => {
  // Every sign Lề draws, as the sources name it, with what the bubble writes beside it. Regulatory signs
  // (limits, bans, orders, zones) read "hiệu lực" once the car is inside them; points count down to "0 m".
  const ZONE = 'Khi xe đã vào đoạn có biển, Lề ghi “hiệu lực” thay cho khoảng cách.';
  const POINT = 'Lề đếm khoảng cách tới biển; tới nơi thì ghi “0 m”.';
  const SIGNS = [
    ['no_passing_in', 'Cấm vượt', 'vuot cam vuot', ZONE],
    ['no_passing_out', 'Hết cấm vượt', 'het cam vuot', POINT],
    ['noEntry', 'Cấm đi thẳng', 'cam di thang', ZONE],
    ['noEntryNoLeftTurn', 'Cấm đi thẳng và rẽ trái', 'cam di thang re trai', ZONE],
    ['noEntryNoRightTurn', 'Cấm đi thẳng và rẽ phải', 'cam di thang re phai', ZONE],
    ['noLeftTurn', 'Cấm rẽ trái', 'cam re trai', ZONE],
    ['noRightTurn', 'Cấm rẽ phải', 'cam re phai', ZONE],
    ['noLeftTurnNoRightTurn', 'Cấm rẽ trái và rẽ phải', 'cam re trai re phai', ZONE],
    ['noUTurnLeft', 'Cấm quay đầu', 'cam quay dau quay xe', ZONE],
    ['noUTurnRight', 'Cấm quay đầu bên phải', 'cam quay dau phai', ZONE],
    ['noLeftTurnUTurn', 'Cấm rẽ trái và quay đầu', 'cam re trai quay dau', ZONE],
    ['noRightTurnUTurn', 'Cấm rẽ phải và quay đầu', 'cam re phai quay dau', ZONE],
    ['straightAheadOnly', 'Chỉ được đi thẳng', 'chi duoc di thang huong phai di', ZONE],
    ['leftTurnOnly', 'Chỉ được rẽ trái', 'chi duoc re trai', ZONE],
    ['rightTurnOnly', 'Chỉ được rẽ phải', 'chi duoc re phai', ZONE],
    ['straightAndLeftTurnOnly', 'Chỉ được đi thẳng và rẽ trái', 'chi duoc di thang re trai', ZONE],
    ['straightAndRightTurnOnly', 'Chỉ được đi thẳng và rẽ phải', 'chi duoc di thang re phai', ZONE],
    ['leftAndRightTurnOnly', 'Chỉ được rẽ trái và rẽ phải', 'chi duoc re trai re phai', ZONE],
    ['retrict_unknown', 'Biển hạn chế chưa rõ loại', 'han che khac khong ro', ZONE],
    ['residential_area_in', 'Bắt đầu khu dân cư', 'khu dan cu khu dong dan cu bat dau', ZONE],
    ['residential_area_out', 'Hết khu dân cư', 'het khu dan cu', POINT],
    ['camera_ai', 'Camera AI', 'camera ai tri tue nhan tao', POINT],
    ['penalty_camera', 'Camera phạt nguội', 'camera phat nguoi', POINT],
    ['speed_limit_camera', 'Camera tốc độ', 'camera toc do ban toc do', POINT],
    ['traffic_camera', 'Camera giao thông', 'camera giao thong den do vuot den', POINT],
    ['railway', 'Đường sắt cắt ngang', 'duong sat tau hoa giao nhau', POINT],
    ['slow_down', 'Đi chậm', 'di cham giam toc', POINT],
    ['tunnel', 'Hầm đường bộ', 'ham duong bo ham', POINT],
    ['toll', 'Trạm thu phí', 'tram thu phi bot', POINT],
    ['toll_etc', 'Thu phí không dừng', 'thu phi khong dung etc', POINT],
    ['highway_rest_area', 'Trạm dừng nghỉ', 'tram dung nghi xang an uong', POINT],
    ['stop_lane', 'Làn dừng khẩn cấp', 'lan dung khan cap sos', POINT],
  ].map(([file, name, words, rule]) => ({ file, name, rule, words: fold(name) + ' ' + words }));

  function fold(text) {
    return text.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/[^a-z0-9 ]+/g, ' ').trim();
  }
  // A number is a limit sign: Lề draws any; the page holds the multiples of 5 up to 150, the others it
  // draws the same way in SVG.
  function limitSign(value) {
    const file = value % 5 === 0 && value <= 150 ? `media/signs/speed_limit_${value}.png` : limitSVG(value);
    return { file, name: `Tốc độ tối đa ${value} km/h`, rule: ZONE, src: file };
  }
  function limitSVG(value) {
    const size = String(value).length > 2 ? 50 : 58;
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="#e4362e"/><circle cx="50" cy="50" r="39.5" fill="#fff"/><text x="50" y="50" dy=".35em" text-anchor="middle" font-family="-apple-system,system-ui,sans-serif" font-stretch="condensed" font-weight="700" font-size="${size}" letter-spacing="-1" fill="#171a20">${value}</text></svg>`;
    return 'data:image/svg+xml,' + encodeURIComponent(svg);
  }
  function find(query) {
    const q = fold(query);
    if (!q) return null;
    const number = q.match(/^(\d{1,3})(?:\s*km(?:\s*h)?)?$/);
    if (number && +number[1] > 0) return limitSign(+number[1]);
    const terms = q.split(/\s+/);
    let best = null, score = 0;
    for (const sign of SIGNS) {
      const hits = terms.filter(t => sign.words.includes(t)).length;
      // All terms matched beats some; a name that starts with the query beats one that contains it.
      const s = hits / terms.length + (fold(sign.name).startsWith(q) ? .5 : 0) + (fold(sign.name) === q ? 1 : 0);
      if (s > score) { score = s; best = sign; }
    }
    return score >= .5 ? { ...best, src: `media/signs/${best.file}.png` } : null;
  }

  const input = document.getElementById('sign-query');
  const answer = document.querySelector('.signs__answer');
  const set = document.querySelector('.signs__set');
  if (input && answer) {
    const image = answer.querySelector('.signs__sign'), name = answer.querySelector('.signs__name'), rule = answer.querySelector('.signs__rule');
    let shown = 'no_passing_in';
    const show = () => {
      const sign = find(input.value);
      if (!sign) {
        name.textContent = 'Chưa có biển tên này';
        rule.textContent = 'Thử một con số như 60, hoặc “cấm rẽ trái”, “trạm thu phí”.';
        image.style.opacity = .25;
        return;
      }
      image.style.opacity = 1;
      name.textContent = sign.name; rule.textContent = sign.rule;
      if (shown !== sign.src) {
        shown = sign.src; image.src = sign.src; image.alt = `Biển ${sign.name.toLowerCase()} do Lề vẽ`;
        answer.classList.remove('is-new'); void answer.offsetWidth; answer.classList.add('is-new');
      }
      set?.querySelectorAll('button').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.file === sign.file)));
    };
    input.addEventListener('input', show);
    document.querySelectorAll('[data-example]').forEach(button => button.addEventListener('click', () => {
      input.value = button.dataset.example; show(); input.focus();
    }));
    if (set) {
      for (const sign of SIGNS) {
        const button = document.createElement('button');
        button.type = 'button'; button.dataset.file = sign.file; button.setAttribute('aria-label', sign.name);
        button.setAttribute('aria-pressed', String(sign.file === 'no_passing_in'));
        button.innerHTML = `<img src="media/signs/${sign.file}.png" width="240" height="240" alt="" loading="lazy">`;
        button.addEventListener('click', () => { input.value = sign.name.toLowerCase(); show(); });
        set.append(button);
      }
    }
  }

  // The hero's loop: still until it is on screen, paused on hover, focus, off screen and on request.
  document.querySelectorAll('[data-loop]').forEach(figure => {
    const button = figure.querySelector('[data-loop-toggle]');
    const state = { seen: false, hover: false, focus: false, held: matchMedia('(prefers-reduced-motion: reduce)').matches };
    const sync = () => {
      const run = state.seen && !state.hover && !state.focus && !state.held;
      figure.classList.toggle('is-running', run);
      figure.querySelectorAll('video').forEach(video => (run ? video.play().catch(() => {}) : video.pause()));
      if (button) button.textContent = state.held ? 'Chạy' : 'Dừng';
    };
    button?.addEventListener('click', () => { state.held = !state.held; sync(); });
    [['pointerenter', 'hover', true], ['pointerleave', 'hover', false], ['focusin', 'focus', true], ['focusout', 'focus', false]]
      .forEach(([type, key, value]) => figure.addEventListener(type, () => { state[key] = value; sync(); }));
    if ('IntersectionObserver' in window) new IntersectionObserver(([entry]) => { state.seen = entry.isIntersecting; sync(); }).observe(figure);
    else { state.seen = true; sync(); }
  });

  // The clip: one play button over its poster; the browser's own controls once it plays.
  document.querySelectorAll('[data-player]').forEach(player => {
    const video = player.querySelector('video'), button = player.querySelector('[data-play]');
    if (!video || !button) return;
    const start = () => { video.controls = true; button.hidden = true; };
    video.controls = false; button.hidden = false;
    button.addEventListener('click', () => { start(); video.play().catch(() => {}); video.focus(); });
    video.addEventListener('play', start);
  });

  // The pinned frame shows the moment in the middle of the screen.
  const frame = document.querySelector('.pinned__frame');
  if (frame && 'IntersectionObserver' in window) {
    const pictures = frame.querySelectorAll('img[data-moment]');
    const watch = new IntersectionObserver(entries => entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      pictures.forEach(img => img.classList.toggle('is-on', img.dataset.moment === entry.target.dataset.moment));
    }), { rootMargin: '-45% 0px -45% 0px' });
    document.querySelectorAll('.moment[data-moment]').forEach(moment => watch.observe(moment));
  }

  // Sileo and Zebra open their links only on an iPhone or iPad; elsewhere the link goes to the steps.
  const apple = /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (!apple) document.querySelectorAll('[data-add-source]').forEach(link => { link.href = '#cai'; });
})();
