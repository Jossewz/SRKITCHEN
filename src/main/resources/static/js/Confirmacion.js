
document.addEventListener("DOMContentLoaded", () => {
  /* 🔹 CONFIRMACIÓN DE ELIMINACIÓN (tu código original) */
  const forms = document.querySelectorAll("form[action*='/platillos/eliminar']");

  forms.forEach(form => {
    form.addEventListener("submit", e => {
      e.preventDefault(); // Evita eliminación directa
      mostrarConfirmacion(form);
    });
  });

  /* 🔹 FORMATEO AUTOMÁTICO DE NÚMEROS (nuevo código) */
  const campoPrecio = document.querySelector("input[name='price']");
  if (campoPrecio) {
    campoPrecio.addEventListener("input", () => {
      // Guardar posición del cursor
      const posicion = campoPrecio.selectionStart;

      // Eliminar cualquier carácter que no sea dígito
      let valor = campoPrecio.value.replace(/\D/g, '');

      // Agregar puntos cada tres dígitos
      valor = valor.replace(/\B(?=(\d{3})+(?!\d))/g, '.');

      campoPrecio.value = valor;

      // Restaurar posición del cursor (opcional)
      campoPrecio.setSelectionRange(posicion, posicion);
    });

    // 🔸 Antes de enviar el formulario, eliminar los puntos para enviar el número limpio al backend
    const formPlatillo = campoPrecio.closest("form");
    if (formPlatillo) {
      formPlatillo.addEventListener("submit", () => {
        campoPrecio.value = campoPrecio.value.replace(/\./g, '');
      });
    }
  }
});

/* 🔹 FUNCIÓN DE CONFIRMACIÓN (sin tocar lo tuyo) */
function mostrarConfirmacion(form) {
  // Evitar crear múltiples modales
  if (document.querySelector(".modal-confirmacion")) return;

  const modal = document.createElement("div");
  modal.className = "modal-confirmacion activo";

  modal.innerHTML = `
    <div class="modal-contenido">
      <h3>¿Eliminar platillo?</h3>
      <p>Esta acción no se puede deshacer.</p>
      <div class="modal-botones">
        <button class="btn-si">Sí, eliminar</button>
        <button class="btn-no">Cancelar</button>
      </div>
    </div>
  `;

  document.body.appendChild(modal);

  // Botones
  modal.querySelector(".btn-si").addEventListener("click", () => {
    modal.remove();
    form.submit();
  });

  modal.querySelector(".btn-no").addEventListener("click", () => {
    modal.classList.remove("activo");
    setTimeout(() => modal.remove(), 300); // animación suave al cerrar
  });
}
