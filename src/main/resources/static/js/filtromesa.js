function filtrarMesas() {
      const input = document.getElementById('barraBusqueda');
      const filter = input.value.toLowerCase();
      const listaMesas = document.getElementById('listaMesas');
      const mesas = listaMesas.getElementsByClassName('mesa-card');

      for (let i = 0; i < mesas.length; i++) {
        let mesa = mesas[i];
        const numeroMesaElem = mesa.querySelector('h3');
        const estadoElem = mesa.querySelector('p strong + span') || mesa.querySelector('p span');
        const textoMesa = (numeroMesaElem?.innerText || "") + " " + (estadoElem?.innerText || "");
        mesa.style.display = textoMesa.toLowerCase().includes(filter) ? "" : "none";
      }
    }