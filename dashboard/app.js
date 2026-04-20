const API_BASE = resolveApiBase();

function resolveApiBase() {
  if (typeof window === 'undefined') {
    return 'http://localhost:8000';
  }

  return window.SPROUTS_API_BASE_URL || window.localStorage.getItem('sprouts_api_base') || 'http://localhost:8000';
}

const VIEWS = [
  { key: 'summary', title: 'Manager Summary', endpoint: '/api/manager/summary', type: 'summary' },
  { key: 'openTasks', title: 'Open Tasks', endpoint: '/api/tasks/open', type: 'list', itemLabel: 'tasks' },
  { key: 'lowStock', title: 'Low Stock Products', endpoint: '/api/products/low-stock', type: 'list', itemLabel: 'products' },
  { key: 'recentOrders', title: 'Recent Orders', endpoint: '/api/orders/recent', type: 'list', itemLabel: 'orders' },
  { key: 'approvals', title: 'Pending Approvals', endpoint: '/api/approvals/pending', type: 'list', itemLabel: 'approvals' },
  { key: 'agentActivity', title: 'Agent Activity', endpoint: '/api/agents/activity', type: 'list', itemLabel: 'activities' },
];

export async function loadView(view, card, fetchImpl = fetch) {
  const statusEl = card.querySelector('.status');
  const contentEl = card.querySelector('.content');
  const url = `${API_BASE}${view.endpoint}`;

  statusEl.textContent = 'Loading…';
  statusEl.className = 'status loading';
  contentEl.innerHTML = '';

  try {
    const response = await fetchImpl(url, { headers: { Accept: 'application/json' } });

    if (!response.ok) {
      throw new Error(`Request failed (${response.status})`);
    }

    const data = await response.json();
    const items = Array.isArray(data) ? data : data.items || [];

    if (view.type === 'summary') {
      renderSummary(contentEl, data);
      statusEl.textContent = 'Loaded';
      statusEl.className = 'status';
      return;
    }

    if (!items.length) {
      statusEl.textContent = `No ${view.itemLabel} found.`;
      statusEl.className = 'status empty';
      return;
    }

    contentEl.appendChild(renderList(items, contentEl.ownerDocument || document));
    statusEl.textContent = `${items.length} ${view.itemLabel}`;
    statusEl.className = 'status';
  } catch (error) {
    statusEl.textContent = `Error: ${error.message}`;
    statusEl.className = 'status error';
  }
}

function renderSummary(root, summary) {
  const doc = root.ownerDocument || document;
  const dl = doc.createElement('dl');
  dl.className = 'kv';

  Object.entries(summary || {}).forEach(([key, value]) => {
    if (value !== null && typeof value === 'object') {
      return;
    }

    const dt = doc.createElement('dt');
    dt.textContent = key;

    const dd = doc.createElement('dd');
    dd.textContent = String(value);

    dl.append(dt, dd);
  });

  if (!dl.children.length) {
    root.innerHTML = '<p>No summary data available.</p>';
    return;
  }

  root.appendChild(dl);
}

function renderList(items, doc = document) {
  const ul = doc.createElement('ul');

  items.forEach((item) => {
    const li = doc.createElement('li');

    if (typeof item === 'string') {
      li.textContent = item;
    } else {
      const idPart = item.id ? `#${item.id} ` : '';
      const namePart = item.name || item.title || item.label || JSON.stringify(item);
      li.textContent = `${idPart}${namePart}`;
    }

    ul.appendChild(li);
  });

  return ul;
}

export function initDashboard(doc = document) {
  doc.getElementById('api-base').textContent = API_BASE;
  const grid = doc.getElementById('dashboard-grid');
  const template = doc.getElementById('view-template');

  VIEWS.forEach((view) => {
    const node = template.content.firstElementChild.cloneNode(true);
    node.querySelector('h2').textContent = view.title;
    node.querySelector('.endpoint').textContent = view.endpoint;

    node.querySelector('.refresh').addEventListener('click', () => {
      loadView(view, node);
    });

    grid.appendChild(node);
    loadView(view, node);
  });
}

if (typeof window !== 'undefined' && document.getElementById('dashboard-grid')) {
  initDashboard();
}
