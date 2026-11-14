// Factura Table Interactions
document.addEventListener('DOMContentLoaded', function() {
  // Initialize modals
  const modalManager = new ModalManager();
  modalManager.register('facturaDetailModal');
  window.modals = window.modals || {};
  window.modals['facturaDetailModal'] = modalManager;
});

// Open detail modal
function openDetailModal(button) {
  const facturaid = button.dataset.id;
  const baseUrl = button.dataset.url;
  const fullUrl = baseUrl + facturaid;

  fetch(fullUrl)
    .then(response => response.text())
    .then(html => {
      const contentDiv = document.getElementById('detalleFacturaContent');
      if (contentDiv) {
        contentDiv.innerHTML = html;
      }
      openModal('facturaDetailModal');
    })
    .catch(error => {
      console.error('Error loading factura details:', error);
      alert('Error cargando los detalles de la factura');
    });
}
