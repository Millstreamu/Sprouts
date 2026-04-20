import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { initDashboard, loadView } from '../app.js';

function makeCard(dom) {
  const doc = dom.window.document;
  const card = doc.createElement('article');
  card.innerHTML = '<div class="status"></div><div class="content"></div>';
  return card;
}

test('loadView renders empty state for list views', async () => {
  const dom = new JSDOM('<!doctype html><html><body></body></html>');
  const card = makeCard(dom);

  await loadView(
    { endpoint: '/api/tasks/open', itemLabel: 'tasks', type: 'list' },
    card,
    async () => ({ ok: true, json: async () => ({ items: [] }) }),
  );

  assert.equal(card.querySelector('.status').textContent, 'No tasks found.');
});

test('loadView renders summary key/value pairs', async () => {
  const dom = new JSDOM('<!doctype html><html><body></body></html>');
  const card = makeCard(dom);

  await loadView(
    { endpoint: '/api/manager/summary', type: 'summary' },
    card,
    async () => ({ ok: true, json: async () => ({ open_orders: 5, pending: 2 }) }),
  );

  assert.equal(card.querySelector('.status').textContent, 'Loaded');
  assert.match(card.querySelector('.content').textContent, /open_orders/);
});

test('initDashboard adds all views to the page', () => {
  const dom = new JSDOM(`<!doctype html><html><body>
      <p id="api-base"></p>
      <section id="dashboard-grid"></section>
      <template id="view-template">
        <article><h2></h2><p class="endpoint"></p><button class="refresh">Refresh</button><div class="status"></div><div class="content"></div></article>
      </template>
    </body></html>`);

  initDashboard(dom.window.document);

  assert.equal(dom.window.document.querySelectorAll('#dashboard-grid article').length, 6);
});
