document.addEventListener('DOMContentLoaded', () => {
      const inputBusqueda = document.getElementById('busquedaPlatillo');
      const itemsPlatillos = document.querySelectorAll('.platillo-item');

      inputBusqueda.addEventListener('input', () => {
        const filtro = inputBusqueda.value.toLowerCase();
        itemsPlatillos.forEach(item => {
          const nombre = item.querySelector('label strong')?.textContent.toLowerCase() || '';
          item.style.display = nombre.includes(filtro) ? 'block' : 'none';
        });
      });
    });