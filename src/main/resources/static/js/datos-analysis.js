// Datos Analysis Interactions
document.addEventListener('DOMContentLoaded', function() {
  const btnPrediccion = document.getElementById('btnPrediccion');
  
  if (btnPrediccion) {
    btnPrediccion.addEventListener('click', executeAnalysis);
  }
});

async function executeAnalysis() {
  const btn = document.getElementById('btnPrediccion');
  const loading = document.getElementById('loading');
  const resultado = document.getElementById('resultado');

  // Disable button and show loading
  btn.disabled = true;
  btn.innerHTML = '<span class="material-symbols-outlined mr-2 inline-block">hourglass_bottom</span> Procesando...';
  loading.classList.remove('hidden');
  resultado.innerHTML = '';

  try {
    const response = await fetch('/weka');

    if (!response.ok) {
      throw new Error(`Error HTTP: ${response.status}`);
    }

    const html = await response.text();
    resultado.innerHTML = `<div class="card p-8">${html}</div>`;

  } catch (error) {
    resultado.innerHTML = `
      <div class="card p-8 border-2 border-red-200 bg-red-50">
        <div class="flex items-start space-x-4">
          <span class="material-symbols-outlined text-red-600 text-4xl">error</span>
          <div>
            <h3 class="font-jakarta font-bold text-red-900 text-lg mb-2">Error en la Conexión</h3>
            <p class="text-red-700 font-work mb-2">No se pudo conectar con el servidor para ejecutar el análisis.</p>
            <p class="text-red-600 text-sm font-work">Error: ${error.message}</p>
            <p class="text-red-600 text-sm font-work">Verifica que el servidor esté ejecutándose correctamente.</p>
          </div>
        </div>
      </div>
    `;
  } finally {
    // Restore button
    btn.disabled = false;
    btn.innerHTML = '<span class="material-symbols-outlined mr-2 inline-block">smart_toy</span> Ejecutar Nuevo Análisis';
    loading.classList.add('hidden');

    // Smooth scroll to results
    if (resultado.innerHTML) {
      resultado.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }
}
