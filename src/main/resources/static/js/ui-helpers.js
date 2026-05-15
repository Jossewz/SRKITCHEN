// Modal Management
class ModalManager {
  constructor() {
    this.modals = new Map();
  }

  register(modalId) {
    const modal = document.getElementById(modalId);
    if (!modal) return;

    this.modals.set(modalId, modal);

    // Setup close buttons
    modal.querySelectorAll('[data-modal-close]').forEach(btn => {
      btn.addEventListener('click', () => this.close(modalId));
    });

    // Close on overlay click
    const overlay = modal.querySelector('[data-modal-overlay]');
    if (overlay) {
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) this.close(modalId);
      });
    }

    // Close on Escape key
    modal.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') this.close(modalId);
    });
  }

  open(modalId) {
    const modal = this.modals.get(modalId);
    if (!modal) {
      console.warn(`Modal ${modalId} not registered`);
      return;
    }
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.style.overflow = 'hidden';
  }

  close(modalId) {
    const modal = this.modals.get(modalId);
    if (!modal) return;
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.style.overflow = '';
  }
}

// Form Validation
class FormValidator {
  static validateRequired(input) {
    if (!input.value.trim()) {
      this.showError(input, 'Este campo es requerido');
      return false;
    }
    this.clearError(input);
    return true;
  }

  static validateEmail(input) {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(input.value)) {
      this.showError(input, 'Email inválido');
      return false;
    }
    this.clearError(input);
    return true;
  }

  static validateNumber(input, min = null, max = null) {
    const num = parseFloat(input.value);
    if (isNaN(num)) {
      this.showError(input, 'Debe ser un número');
      return false;
    }
    if (min !== null && num < min) {
      this.showError(input, `Debe ser mayor a ${min}`);
      return false;
    }
    if (max !== null && num > max) {
      this.showError(input, `Debe ser menor a ${max}`);
      return false;
    }
    this.clearError(input);
    return true;
  }

  static showError(input, message) {
    input.classList.add('ring-2', 'ring-red-500');
    let errorDiv = input.nextElementSibling;
    if (!errorDiv || !errorDiv.classList.contains('error-message')) {
      errorDiv = document.createElement('p');
      errorDiv.className = 'error-message text-red-600 text-sm mt-1';
      input.parentElement.insertBefore(errorDiv, input.nextElementSibling);
    }
    errorDiv.textContent = message;
  }

  static clearError(input) {
    input.classList.remove('ring-2', 'ring-red-500');
    const errorDiv = input.nextElementSibling;
    if (errorDiv && errorDiv.classList.contains('error-message')) {
      errorDiv.remove();
    }
  }
}

// Confirmation Dialog
function confirmAction(message) {
  return confirm(message || '¿Está seguro de esta acción?');
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
  // Initialize all modals
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

// Global function to open modals
function openModal(modalId) {
  if (!window.modals || !window.modals[modalId]) {
    const manager = new ModalManager();
    manager.register(modalId);
    if (!window.modals) window.modals = {};
    window.modals[modalId] = manager;
  }
  window.modals[modalId].open(modalId);
}

// Global function to close modals
function closeModal(modalId) {
  if (window.modals && window.modals[modalId]) {
    window.modals[modalId].close(modalId);
  }
}
