document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('modal-detalle');
    const detalleDiv = document.getElementById('detalle-factura');

    window.cerrarModal = function() {
        modal.style.display = 'none';
        detalleDiv.innerHTML = '';
        document.body.style.overflow = 'auto';
    };

    // Función para imprimir ticket
    window.imprimirTicket = function() {
        const vistaNormal = document.querySelector('.vista-normal');
        const ticketImpresion = document.getElementById('ticket-impresion');

        if (vistaNormal && ticketImpresion) {
            vistaNormal.style.display = 'none';
            ticketImpresion.style.display = 'block';

            setTimeout(() => {
                window.print();

                setTimeout(() => {
                    vistaNormal.style.display = 'block';
                    ticketImpresion.style.display = 'none';
                }, 500);
            }, 100);
        }
    };

    // Función para vista previa
    window.verVistaPrevia = function() {
        const vistaNormal = document.querySelector('.vista-normal');
        const ticketImpresion = document.getElementById('ticket-impresion');

        if (vistaNormal && ticketImpresion) {
            vistaNormal.style.display = 'none';
            ticketImpresion.style.display = 'block';

            const ventanaPrevia = window.open('', '_blank', 'width=400,height=600');
            ventanaPrevia.document.write(`
                <!DOCTYPE html>
                <html>
                    <head>
                        <title>Vista Previa - Ticket SR Kitchen</title>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                margin: 20px;
                                background: #f5f5f5;
                                display: flex;
                                flex-direction: column;
                                align-items: center;
                            }
                            .ticket-preview {
                                width: 80mm;
                                background: white;
                                padding: 15px;
                                margin: 0 auto;
                                box-shadow: 0 0 10px rgba(0,0,0,0.1);
                                border: 1px dashed #ccc;
                                font-family: 'Courier New', monospace;
                            }
                            .controls {
                                margin-top: 20px;
                                text-align: center;
                            }
                            button {
                                padding: 10px 20px;
                                margin: 5px;
                                border: none;
                                border-radius: 5px;
                                cursor: pointer;
                            }
                            .btn-print {
                                background: #007bff;
                                color: white;
                            }
                            .btn-close {
                                background: #6c757d;
                                color: white;
                            }
                        </style>
                    </head>
                    <body>
                        <h3>Vista Previa del Ticket</h3>
                        <div class="ticket-preview">
                            ${ticketImpresion.innerHTML}
                        </div>
                        <div class="controls">
                            <button class="btn-print" onclick="window.print()">🖨️ Imprimir</button>
                            <button class="btn-close" onclick="window.close()">❌ Cerrar</button>
                        </div>
                    </body>
                </html>
            `);
            ventanaPrevia.document.close();

            // Restaurar vista normal
            vistaNormal.style.display = 'block';
            ticketImpresion.style.display = 'none';
        }
    };

    // Event listeners para botones "Ver Detalle"
    document.querySelectorAll('.ver-detalle').forEach(btn => {
        btn.addEventListener('click', () => {
            const facturaId = btn.dataset.id;
            const baseUrl = btn.dataset.url;

            detalleDiv.innerHTML = '<p style="text-align: center; padding: 20px;">Cargando...</p>';
            modal.style.display = 'flex';
            document.body.style.overflow = 'hidden';

            fetch(`${baseUrl}${facturaId}`)
                .then(res => {
                    if (!res.ok) throw new Error(`HTTP ${res.status}`);
                    return res.text();
                })
                .then(html => {
                    detalleDiv.innerHTML = html;
                })
                .catch(err => {
                    console.error("Error al cargar detalle:", err);
                    detalleDiv.innerHTML = '<p style="text-align: center; color: red;">Error al cargar los detalles</p>';
                });
        });
    });

    window.onclick = function(event) {
        if (event.target === modal) {
            cerrarModal();
        }
    };

    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            cerrarModal();
        }
    });
});