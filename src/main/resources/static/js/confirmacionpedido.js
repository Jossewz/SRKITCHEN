document.addEventListener("DOMContentLoaded", () => {
  const enlacesEliminar = document.querySelectorAll("a[href*='/pedidos/eliminar/']");

  enlacesEliminar.forEach(enlace => {
    enlace.addEventListener("click", e => {
      e.preventDefault(); // Evita que vaya directamente al enlace
      mostrarConfirmacion(enlace.href);
    });
  });
});

function mostrarConfirmacion(url) {
  // Evitar duplicar modales
  if (document.querySelector(".modal-confirmacion")) return;

  const modal = document.createElement("div");
  modal.className = "modal-confirmacion activo";

  modal.innerHTML = `
    <div class="modal-contenido">
      <h3>¿Eliminar pedido?</h3>
      <p>Esta acción no se puede deshacer.</p>
      <div class="modal-botones">
        <button class="btn-si">Sí, eliminar</button>
        <button class="btn-no">Cancelar</button>
      </div>
    </div>
  `;

  document.body.appendChild(modal);

  // Acción de los botones
  modal.querySelector(".btn-si").addEventListener("click", () => {
    modal.remove();
    window.location.href = url; // Redirige al enlace original
  });

  modal.querySelector(".btn-no").addEventListener("click", () => {
    modal.classList.remove("activo");
    setTimeout(() => modal.remove(), 300);
  });
}
