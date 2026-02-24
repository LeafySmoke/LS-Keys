const app = document.getElementById('app');
const vehicleLabel = document.getElementById('vehicleLabel');
const actions = document.getElementById('actions');
const closeBtn = document.getElementById('closeBtn');
const keychainList = document.getElementById('keychainList');

let currentPlate = null;
let isKeychain = false;

function post(event, data = {}) {
  fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
}

function setVehicleLabel(payload) {
  if (payload?.plate) {
    vehicleLabel.textContent = `${payload.model || 'Vehicle'} | ${payload.plate}`;
    currentPlate = payload.plate;
  } else {
    vehicleLabel.textContent = 'No vehicle selected';
    currentPlate = null;
  }
}

function renderKeychain(keys = []) {
  keychainList.innerHTML = '';
  if (!keys.length) {
    keychainList.innerHTML = '<div class="key-item"><span>No keys in keychain</span></div>';
    return;
  }

  keys.forEach((k) => {
    const row = document.createElement('div');
    row.className = 'key-item';

    const label = document.createElement('span');
    label.textContent = `${k.model || 'Vehicle'} | ${k.plate}`;

    const button = document.createElement('button');
    button.textContent = 'SELECT';
    button.addEventListener('click', () => {
      isKeychain = false;
      keychainList.classList.add('hidden');
      actions.classList.remove('hidden');
      setVehicleLabel(k);
    });

    row.append(label, button);
    keychainList.appendChild(row);
  });
}

window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};

  if (action === 'open') {
    app.classList.remove('hidden');

    isKeychain = !!payload?.keychain;
    if (isKeychain) {
      actions.classList.add('hidden');
      keychainList.classList.remove('hidden');
      vehicleLabel.textContent = 'Keychain';
      renderKeychain(payload.keys || []);
      return;
    }

    keychainList.classList.add('hidden');
    actions.classList.remove('hidden');
    setVehicleLabel(payload || {});
  }

  if (action === 'close') {
    app.classList.add('hidden');
    currentPlate = null;
  }
});

actions.addEventListener('click', (e) => {
  const btn = e.target.closest('button[data-action]');
  if (!btn || !currentPlate) return;

  post('doAction', {
    action: btn.dataset.action,
    plate: currentPlate
  });
});

closeBtn.addEventListener('click', () => post('close'));

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    post('close');
  }
});
