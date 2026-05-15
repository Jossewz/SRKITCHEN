// Mobile Menu Toggle
document.addEventListener('DOMContentLoaded', function() {
  const menuToggle = document.getElementById('menu-toggle');
  const sidebar = document.querySelector('div[class*="lg:left-64"]');
  
  if (menuToggle && sidebar) {
    menuToggle.addEventListener('click', function() {
      sidebar.classList.toggle('hidden');
    });
    
    // Close menu when a link is clicked
    document.querySelectorAll('.sidebar-item').forEach(item => {
      item.addEventListener('click', function() {
        sidebar.classList.add('hidden');
      });
    });
  }

  // Update page title based on current URL
  const pageTitle = document.getElementById('page-title');
  if (pageTitle) {
    const path = window.location.pathname;
    const titles = {
      '/mesa': 'Gestión de Mesas',
      '/pedidos': 'Gestión de Pedidos',
      '/factura': 'Facturas',
      '/mesero': 'Gestión de Meseros',
      '/platillos': 'Gestión de Platillos',
      '/datos': 'Datos y Reportes',
      '/start': 'Inicio',
    };
    pageTitle.textContent = titles[path] || 'Dashboard';
  }

  // Auto-remove messages after 5 seconds
  document.querySelectorAll('[id*="message"]').forEach(message => {
    setTimeout(() => {
      if (message.parentElement) {
        message.parentElement.remove();
      }
    }, 5000);
  });
});
