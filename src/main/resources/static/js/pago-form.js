document.addEventListener('DOMContentLoaded', () => {
  const pagoForm = document.getElementById('pagoForm');
  const montoInput = document.getElementById('monto');

  if (!pagoForm || !montoInput) {
    return;
  }

  pagoForm.addEventListener('submit', (event) => {
    const monto = parseFloat(montoInput.value);
    if (Number.isNaN(monto) || monto <= 0) {
      event.preventDefault();
      montoInput.focus();
      alert('Ingresa un monto válido para procesar el pago.');
    }
  });
});
