// Mesa Table Interactions
document.addEventListener('DOMContentLoaded', function() {
  const searchInput = document.getElementById('searchInput');
  const mesasContainer = document.getElementById('mesasContainer');

  if (searchInput) {
    searchInput.addEventListener('keyup', function() {
      const searchTerm = this.value.toLowerCase();
      
      document.querySelectorAll('[data-mesa-num]').forEach(mesaCard => {
        const mesaNum = mesaCard.dataset.mesaNum.toLowerCase();
        const mesaEstado = mesaCard.dataset.mesaEstado.toLowerCase();
        
        const matches = mesaNum.includes(searchTerm) || mesaEstado.includes(searchTerm);
        mesaCard.style.display = matches ? 'flex' : 'none';
      });
    });
  }

  // Initialize modals for each mesa
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
