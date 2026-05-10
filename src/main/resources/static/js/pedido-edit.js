document.addEventListener('DOMContentLoaded', () => {
  const opciones = [...document.querySelectorAll('#platillosList option')];
  const entradas = document.querySelectorAll('.platillo-busqueda');
  const ocultos = document.getElementsByName('nuevosPlatillos');
  const formulario = document.getElementById('editarPedidoForm');

  entradas.forEach((inputBusqueda, index) => {
    const hiddenInput = ocultos[index];
    inputBusqueda.addEventListener('change', () => {
      const seleccionado = opciones.find(opt => opt.value === inputBusqueda.value);
      hiddenInput.value = seleccionado ? seleccionado.dataset.id : '';
    });
  });

  if (!formulario) {
    return;
  }

  formulario.addEventListener('submit', (event) => {
    const inputsInvalidos = [...entradas].filter((input, index) => {
      const hiddenInput = ocultos[index];
      return input.value.trim() !== '' && hiddenInput.value.trim() === '';
    });

    if (inputsInvalidos.length > 0) {
      event.preventDefault();
      alert('Verifica que los nuevos platillos seleccionados sean válidos desde la lista desplegable.');
    }
  });
});
