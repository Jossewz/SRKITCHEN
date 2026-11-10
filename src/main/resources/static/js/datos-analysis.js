
document.addEventListener('DOMContentLoaded', () => {
  const btn = document.getElementById('btnPrediccion');
  if (btn) btn.addEventListener('click', ejecutarAnalisis);
});

async function ejecutarAnalisis() {
  const btn = document.getElementById('btnPrediccion');
  const loading = document.getElementById('loading');
  const res = document.getElementById('resultado');

  btn.disabled = true;
  btn.innerHTML = '<span class="material-symbols-outlined mr-2 inline-block">hourglass_bottom</span> Calculando...';
  loading.classList.remove('hidden');
  res.innerHTML = '';

  try {
    const [realtime, optimo, ranking] = await Promise.all([
      fetchJSON('/datos/api/realtime'),
      fetchJSON('/datos/api/optimo'),
      fetchJSON('/datos/api/ranking?top=5'),
    ]);
    res.innerHTML = renderTodo(realtime, optimo, ranking);
    inicializarEvaluador();
  } catch (err) {
    res.innerHTML = renderError(err.message);
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<span class="material-symbols-outlined mr-2 inline-block">smart_toy</span> Ejecutar Nuevo Análisis';
    loading.classList.add('hidden');
    res.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}
function renderTodo(rt, optimo, ranking) {
  const hayDatos = rt.totalPedidos > 0;
  return `

    <!-- Sección: datos reales de la BD -->
    <div class="mb-2">
      <p class="text-xs font-semibold uppercase tracking-wide text-gray-400 font-work mb-3 flex items-center gap-2">
        <span class="material-symbols-outlined text-sm">storage</span>
        Datos reales de la base de datos (PostgreSQL)
      </p>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        ${kpiCard('receipt_long', 'Pedidos registrados', fmt(rt.totalPedidos, 0) + ' pedidos', 'text-gray-500')}
        ${kpiCard('restaurant_menu', 'Platos fuertes vendidos', fmt(rt.x1VendidosReal, 0) + ' und', 'text-blue-600')}
        ${kpiCard('lunch_dining', 'Platos sencillos vendidos', fmt(rt.x2VendidosReal, 0) + ' und', 'text-amber-600')}
        ${kpiCard('payments', 'Ingreso registrado', '$' + fmt(rt.ingresoReal, 2), 'text-emerald-600')}
      </div>
    </div>

    <!-- Top platillos vendidos -->
    ${rt.platillosMasVendidos && rt.platillosMasVendidos.length > 0 ? `
    <div class="card p-6 mb-8">
      <h3 class="text-lg font-jakarta font-bold text-primary mb-4 flex items-center gap-2">
        <span class="material-symbols-outlined text-orange-500">local_fire_department</span>
        Platillos más vendidos (datos reales)
      </h3>
      <div class="space-y-2">
        ${rt.platillosMasVendidos.map((p, i) => {
    const pct = rt.platillosMasVendidos[0].unidades > 0
      ? Math.round((p.unidades / rt.platillosMasVendidos[0].unidades) * 100) : 0;
    return `
          <div class="flex items-center gap-3">
            <span class="text-xs text-gray-400 w-4 font-work">${i + 1}</span>
            <span class="text-sm font-work text-gray-700 w-40 truncate">${p.nombre}</span>
            <div class="flex-1 bg-gray-100 rounded-full h-2">
              <div class="bg-blue-500 h-2 rounded-full" style="width:${pct}%"></div>
            </div>
            <span class="text-sm font-semibold font-work text-gray-700 w-12 text-right">${p.unidades}</span>
          </div>`;
  }).join('')}
      </div>
    </div>` : ''}

    <!-- Separador: modelo PL -->
    <p class="text-xs font-semibold uppercase tracking-wide text-gray-400 font-work mb-3 flex items-center gap-2">
      <span class="material-symbols-outlined text-sm">function</span>
      Resultado del modelo de programación lineal
    </p>

    <!-- KPIs del modelo -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      ${kpiCard('monetization_on', 'Utilidad máxima (modelo)', '$' + fmt(optimo.utilidadMaxima, 2), 'text-green-600')}
      ${kpiCard('restaurant_menu', 'X1 óptimo (platos fuertes)', fmt(optimo.x1PlatosFuertes, 0) + ' platos', 'text-blue-600')}
      ${kpiCard('lunch_dining', 'X2 óptimo (platos sencillos)', fmt(optimo.x2PlatosSencillos, 0) + ' platos', 'text-amber-600')}
    </div>

    <!-- Comparación real vs óptimo -->
    ${hayDatos ? `
    <div class="card p-6 mb-8">
      <h3 class="text-lg font-jakarta font-bold text-primary mb-4 flex items-center gap-2">
        <span class="material-symbols-outlined text-indigo-500">compare_arrows</span>
        Real vs Óptimo
      </h3>
      <div class="overflow-x-auto">
        <table class="w-full text-sm font-work">
          <thead>
            <tr class="text-left text-gray-400 border-b border-gray-100">
              <th class="pb-2"></th>
              <th class="pb-2">Platos fuertes (X1)</th>
              <th class="pb-2">Platos sencillos (X2)</th>
              <th class="pb-2">Utilidad/Ingreso</th>
            </tr>
          </thead>
          <tbody>
            <tr class="border-b border-gray-50">
              <td class="py-3 font-medium text-gray-600">Realidad (BD)</td>
              <td class="py-3">${fmt(optimo.x1Real, 0)}</td>
              <td class="py-3">${fmt(optimo.x2Real, 0)}</td>
              <td class="py-3 text-gray-700">$${fmt(optimo.utilidadMaxima - optimo.diferenciaPotencial, 2)}</td>
            </tr>
            <tr class="bg-green-50">
              <td class="py-3 font-semibold text-green-800">Óptimo (modelo)</td>
              <td class="py-3 font-semibold text-green-800">${fmt(optimo.x1PlatosFuertes, 0)}</td>
              <td class="py-3 font-semibold text-green-800">${fmt(optimo.x2PlatosSencillos, 0)}</td>
              <td class="py-3 font-semibold text-green-800">$${fmt(optimo.utilidadMaxima, 2)}</td>
            </tr>
            <tr class="border-t border-gray-100">
              <td class="py-3 text-gray-500">Mejora potencial</td>
              <td class="py-3"></td><td class="py-3"></td>
              <td class="py-3 font-semibold ${optimo.diferenciaPotencial > 0 ? 'text-green-600' : 'text-gray-500'}">
                ${optimo.diferenciaPotencial > 0 ? '+' : ''}$${fmt(optimo.diferenciaPotencial, 2)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>` : ''}

    <!-- Restricciones + solución -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
      <div class="card p-6">
        <h3 class="text-lg font-jakarta font-bold text-primary mb-3 flex items-center gap-2">
          <span class="material-symbols-outlined text-green-500">check_circle</span>
          Solución óptima
        </h3>
        <p class="text-gray-500 font-work text-sm mb-4">${optimo.interpretacion}</p>
        <div class="space-y-3">
          ${metricRow('Función objetivo', 'Max Z = 12·X1 + 10·X2')}
          ${metricRow('X1 platos fuertes', fmt(optimo.x1PlatosFuertes, 0) + ' und')}
          ${metricRow('X2 platos sencillos', fmt(optimo.x2PlatosSencillos, 0) + ' und')}
          ${metricRow('Total platillos', fmt(optimo.totalPlatillos, 0) + ' und')}
          ${metricRow('Costo de insumos', '$' + fmt(optimo.costoTotal, 2))}
          ${metricRow('Utilidad generada', '<span class="font-bold text-green-600">$' + fmt(optimo.utilidadMaxima, 2) + '</span>')}
        </div>
      </div>
      <div class="card p-6">
        <h3 class="text-lg font-jakarta font-bold text-primary mb-3 flex items-center gap-2">
          <span class="material-symbols-outlined text-blue-500">rule</span>
          Verificación de restricciones
        </h3>
        <div class="space-y-2">
          ${Object.entries(optimo.restricciones).map(([k, v]) => restriccionRow(k, v)).join('')}
        </div>
      </div>
    </div>

    <!-- Top 5 -->
    <div class="card p-6 mb-8">
      <h3 class="text-lg font-jakarta font-bold text-primary mb-4 flex items-center gap-2">
        <span class="material-symbols-outlined text-amber-500">leaderboard</span>
        Top 5 combinaciones más rentables
      </h3>
      <div class="overflow-x-auto">
        <table class="w-full text-sm font-work">
          <thead>
            <tr class="border-b border-gray-200 text-left text-gray-400">
              <th class="pb-3 pr-4">#</th>
              <th class="pb-3 pr-4">Platos fuertes (X1)</th>
              <th class="pb-3 pr-4">Platos sencillos (X2)</th>
              <th class="pb-3">Utilidad</th>
            </tr>
          </thead>
          <tbody>
            ${ranking.map((r, i) => `
              <tr class="border-b border-gray-100 ${i === 0 ? 'bg-green-50 font-semibold' : ''}">
                <td class="py-2 pr-4">${i === 0 ? '🥇' : r.posicion}</td>
                <td class="py-2 pr-4">${r.x1PlatosFuertes}</td>
                <td class="py-2 pr-4">${r.x2PlatosSencillos}</td>
                <td class="py-2 text-green-700 font-semibold">$${fmt(r.utilidad, 2)}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>
    </div>

    <!-- Evaluador -->
    <div class="card p-6" id="evaluadorCard">
      <h3 class="text-lg font-jakarta font-bold text-primary mb-4 flex items-center gap-2">
        <span class="material-symbols-outlined text-indigo-500">calculate</span>
        Evaluar combinación personalizada
      </h3>
      <div class="flex flex-wrap gap-4 items-end mb-4">
        <div>
          <label class="block text-xs text-gray-500 font-work mb-1">Platos fuertes (X1)</label>
          <input id="inputX1" type="number" min="0" max="100" value="60"
            class="border border-gray-300 rounded-lg px-3 py-2 w-28 text-sm font-work focus:outline-none focus:ring-2 focus:ring-primary/30">
        </div>
        <div>
          <label class="block text-xs text-gray-500 font-work mb-1">Platos sencillos (X2)</label>
          <input id="inputX2" type="number" min="0" max="100" value="60"
            class="border border-gray-300 rounded-lg px-3 py-2 w-28 text-sm font-work focus:outline-none focus:ring-2 focus:ring-primary/30">
        </div>
        <button id="btnEvaluar" class="btn-primary px-5 py-2 text-sm inline-flex items-center gap-1">
          <span class="material-symbols-outlined text-base">play_arrow</span>Evaluar
        </button>
      </div>
      <div id="evalResultado"></div>
    </div>
  `;
}
function inicializarEvaluador() {
  document.getElementById('btnEvaluar').addEventListener('click', async () => {
    const x1 = parseFloat(document.getElementById('inputX1').value) || 0;
    const x2 = parseFloat(document.getElementById('inputX2').value) || 0;
    const div = document.getElementById('evalResultado');
    div.innerHTML = '<p class="text-sm text-gray-400 font-work">Evaluando...</p>';
    try {
      const data = await fetchJSON(`/datos/api/evaluar?x1=${x1}&x2=${x2}`);
      const c = data.factible ? 'green' : 'red';
      const icon = data.factible ? 'check_circle' : 'cancel';
      div.innerHTML = `
        <div class="border rounded-lg p-4 border-${c}-200 bg-${c}-50">
          <div class="flex items-center gap-2 mb-3">
            <span class="material-symbols-outlined text-${c}-600">${icon}</span>
            <span class="font-jakarta font-semibold text-${c}-800">
              ${data.factible ? 'Combinación factible' : 'Combinación infactible'}
            </span>
            <span class="ml-auto font-work text-sm font-semibold text-${c}-700">
              Utilidad: $${fmt(data.utilidad, 2)}
            </span>
          </div>
          <div class="grid grid-cols-2 gap-1 text-xs font-work">
            ${Object.entries(data.detalle).map(([k, v]) => `
              <span class="text-gray-500">${k}</span>
              <span class="${v.startsWith('✓') ? 'text-green-600' : 'text-red-600'} font-medium">${v}</span>
            `).join('')}
          </div>
        </div>`;
    } catch (e) {
      div.innerHTML = `<p class="text-sm text-red-500">Error: ${e.message}</p>`;
    }
  });
}
function kpiCard(icon, label, value, colorClass) {
  return `<div class="card p-5 flex items-center gap-3">
    <span class="material-symbols-outlined text-3xl ${colorClass}">${icon}</span>
    <div>
      <p class="text-xs text-gray-400 font-work uppercase tracking-wide">${label}</p>
      <p class="text-xl font-jakarta font-bold text-primary">${value}</p>
    </div>
  </div>`;
}
function metricRow(label, value) {
  return `<div class="flex justify-between items-center py-2 border-b border-gray-100 last:border-0">
    <span class="text-sm text-gray-500 font-work">${label}</span>
    <span class="text-sm font-semibold text-gray-800 font-work">${value}</span>
  </div>`;
}
function restriccionRow(label, cumple) {
  return `<div class="flex items-center gap-2 py-1">
    <span class="material-symbols-outlined text-sm ${cumple ? 'text-green-500' : 'text-red-500'}">${cumple ? 'check' : 'close'}</span>
    <span class="text-sm font-work ${cumple ? 'text-gray-700' : 'text-red-600'}">${label}</span>
  </div>`;
}
function renderError(msg) {
  return `<div class="card p-8 border-2 border-red-200 bg-red-50">
    <div class="flex items-start gap-4">
      <span class="material-symbols-outlined text-red-600 text-4xl">error</span>
      <div>
        <h3 class="font-jakarta font-bold text-red-900 text-lg mb-2">Error al ejecutar el modelo</h3>
        <p class="text-red-700 font-work text-sm">${msg}</p>
      </div>
    </div>
  </div>`;
}
function fmt(n, dec = 0) {
  return Number(n).toLocaleString('es-CO', {
    minimumFractionDigits: dec, maximumFractionDigits: dec
  });
}
async function fetchJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}
