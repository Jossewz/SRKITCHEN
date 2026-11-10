// Platillos Table Interactions
document.addEventListener('DOMContentLoaded', function() {
  const searchInput = document.getElementById('searchPlatillos');
  const platillosGrid = document.getElementById('platillosGrid');

  if (searchInput) {
    searchInput.addEventListener('keyup', function() {
      const searchTerm = this.value.toLowerCase();
      
      document.querySelectorAll('[data-platillo-name]').forEach(platillo => {
        const name = platillo.dataset.platilloName.toLowerCase();
        const matches = name.includes(searchTerm);
        platillo.style.display = matches ? 'block' : 'none';
      });
    });
  }

  // Initialize modals for each platillo
  document.querySelectorAll('[data-modal-id]').forEach(modal => {
    const modalManager = new ModalManager();
    const modalId = modal.id;
    if (modalId) {
      modalManager.register(modalId);
      window.modals = window.modals || {};
      window.modals[modalId] = modalManager;
    }
  });
});
