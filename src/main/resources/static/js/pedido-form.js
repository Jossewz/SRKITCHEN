// Pedido Form Interactions
document.addEventListener('DOMContentLoaded', function() {
  const searchInput = document.getElementById('busquedaPlatillo');
  const platillosContainer = document.getElementById('platillosContainer');

  // Search functionality
  if (searchInput) {
    searchInput.addEventListener('keyup', function() {
      const searchTerm = this.value.toLowerCase();
      
      document.querySelectorAll('.platillo-item').forEach(platillo => {
        const name = platillo.dataset.platilloName.toLowerCase();
        const matches = name.includes(searchTerm);
        platillo.style.display = matches ? 'block' : 'none';
      });
    });
  }

  // Initialize modals if any
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

// Toggle platillo selection and show/hide quantity section
function togglePlatillo(checkbox) {
  const platilloItem = checkbox.closest('.platillo-item');
  const cantidadSection = platilloItem.querySelector('.cantidad-section');
  
  if (checkbox.checked) {
    cantidadSection.classList.remove('hidden');
  } else {
    cantidadSection.classList.add('hidden');
  }
}

// Increment quantity
function incrementQuantity(button) {
  const input = button.parentElement.querySelector('input[type="number"]');
  input.value = parseInt(input.value) + 1;
}

// Decrement quantity
function decrementQuantity(button) {
  const input = button.parentElement.querySelector('input[type="number"]');
  if (parseInt(input.value) > 1) {
    input.value = parseInt(input.value) - 1;
  }
}

// Update mesa info (placeholder)
function updateMesaInfo() {
  console.log('Mesa selection changed');
}
