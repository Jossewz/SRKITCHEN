package com.example.rskitchen5.weka;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import weka.core.Instance;
import weka.core.Instances;

@Controller
public class WekaController {

    private final PedidoWekaService pedidoWekaService;
    private final WekaModelService wekaModelService;

    public WekaController(PedidoWekaService pedidoWekaService, WekaModelService wekaModelService) {
        this.pedidoWekaService = pedidoWekaService;
        this.wekaModelService = wekaModelService;
    }

    @GetMapping("/weka")
    @ResponseBody
    public String probarModelo() {
        try {
            Instances data = pedidoWekaService.obtenerInstancias();
            if (data == null || data.isEmpty()) return "No hay datos para evaluar";

            // ✅ PARA CLASIFICACIÓN: pagado es la clase (índice 2)
            data.setClassIndex(2);

            // ✅ ANALIZAR TODOS LOS PEDIDOS para calcular impacto
            double totalIngresosReales = 0;
            double totalIngresosPredichos = 0;
            int pedidosAnalizados = 0;
            int pedidosPagadosReales = 0;
            int pedidosPagadosPredichos = 0;

            // Tomar solo los primeros 100 pedidos para no sobrecargar
            int maxPedidos = Math.min(100, data.numInstances());

            for (int i = 0; i < maxPedidos; i++) {
                Instance inst = data.instance(i);
                double prediccion = wekaModelService.predecir(inst);

                double totalReal = inst.value(1);
                boolean pagadoReal = inst.value(2) == 1;
                boolean pagadoPredicho = prediccion == 1;

                // Ingresos reales (solo si realmente está pagado)
                if (pagadoReal) {
                    totalIngresosReales += totalReal;
                    pedidosPagadosReales++;
                }

                // Ingresos predichos (solo si el modelo predice que estará pagado)
                if (pagadoPredicho) {
                    totalIngresosPredichos += totalReal;
                    pedidosPagadosPredichos++;
                }

                pedidosAnalizados++;
            }

            // ✅ CALCULAR PORCENTAJE DE CAMBIO
            double porcentajeCambio = 0;
            double cambioAbsoluto = totalIngresosPredichos - totalIngresosReales;
            String tendencia = "";
            String color = "";
            String icono = "";

            if (totalIngresosReales > 0) {
                porcentajeCambio = (cambioAbsoluto / totalIngresosReales) * 100;

                if (porcentajeCambio > 0) {
                    tendencia = "AUMENTO";
                    color = "green";
                    icono = "📈";
                } else if (porcentajeCambio < 0) {
                    tendencia = "DECREMENTO";
                    color = "red";
                    icono = "📉";
                } else {
                    tendencia = "ESTABLE";
                    color = "blue";
                    icono = "📊";
                }
            }

            StringBuilder sb = new StringBuilder();
            sb.append("<h2>").append(icono).append(" Análisis de Impacto en Ganancias</h2>");

            // ✅ RESUMEN EJECUTIVO
            sb.append("<div style='border: 2px solid ").append(color).append("; padding: 15px; border-radius: 10px; background-color: #f8f9fa; margin-bottom: 20px;'>");
            sb.append("<h3 style='color: ").append(color).append("; margin-top: 0;'>").append(icono).append(" Tendencia: ").append(tendencia).append("</h3>");
            sb.append("<p style='font-size: 18px; margin: 10px 0;'><b>Porcentaje de cambio:</b> <span style='color: ").append(color).append("; font-size: 28px; font-weight: bold;'>")
                    .append(String.format("%.1f", Math.abs(porcentajeCambio))).append("%</span></p>");
            sb.append("<p style='font-size: 16px; margin: 5px 0;'><b>Cambio absoluto:</b> $").append(String.format("%,.0f", Math.abs(cambioAbsoluto))).append("</p>");
            sb.append("</div>");

            // ✅ DETALLES FINANCIEROS
            sb.append("<h3>💰 Detalles Financieros:</h3>");
            sb.append("<table border='1' style='border-collapse: collapse; width: 100%; margin-bottom: 20px;'>");
            sb.append("<tr style='background-color: #e9ecef;'><th style='padding: 12px; text-align: left;'>Concepto</th><th style='padding: 12px; text-align: left;'>Valor</th></tr>");
            sb.append("<tr><td style='padding: 10px;'>Pedidos analizados</td><td style='padding: 10px;'>").append(pedidosAnalizados).append("</td></tr>");
            sb.append("<tr><td style='padding: 10px;'>Pedidos pagados (reales)</td><td style='padding: 10px;'>").append(pedidosPagadosReales).append("</td></tr>");
            sb.append("<tr><td style='padding: 10px;'>Pedidos pagados (predichos)</td><td style='padding: 10px;'>").append(pedidosPagadosPredichos).append("</td></tr>");
            sb.append("<tr><td style='padding: 10px;'>Ingresos reales</td><td style='padding: 10px;'>$").append(String.format("%,.0f", totalIngresosReales)).append("</td></tr>");
            sb.append("<tr><td style='padding: 10px;'>Ingresos predichos</td><td style='padding: 10px;'>$").append(String.format("%,.0f", totalIngresosPredichos)).append("</td></tr>");
            sb.append("<tr><td style='padding: 10px;'><b>Diferencia</b></td><td style='padding: 10px;'><b>$").append(String.format("%,.0f", cambioAbsoluto)).append("</b></td></tr>");
            sb.append("</table>");

            // ✅ INTERPRETACIÓN
            sb.append("<h3>🎯 Interpretación del Análisis:</h3>");
            sb.append("<div style='background-color: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107;'>");
            if (porcentajeCambio > 5) {
                sb.append("<p><b>✅ PERSPECTIVA MUY POSITIVA:</b> El modelo predice un <b>aumento significativo del ").append(String.format("%.1f", porcentajeCambio)).append("%</b> en las ganancias.</p>");
                sb.append("<p>• Las estrategias actuales están funcionando bien</p>");
                sb.append("<p>• Se espera un mejor desempeño en los pagos</p>");
                sb.append("<p>• Posible aumento en la eficiencia de cobranza</p>");
            } else if (porcentajeCambio > 0) {
                sb.append("<p><b>📈 PERSPECTIVA POSITIVA:</b> El modelo predice un <b>aumento del ").append(String.format("%.1f", porcentajeCambio)).append("%</b> en las ganancias.</p>");
                sb.append("<p>• Tendencia positiva en los pagos</p>");
                sb.append("<p>• Leve mejora esperada en los ingresos</p>");
            } else if (porcentajeCambio < -5) {
                sb.append("<p><b>⚠️ ALERTA:</b> El modelo predice una <b>disminución significativa del ").append(String.format("%.1f", Math.abs(porcentajeCambio))).append("%</b> en las ganancias.</p>");
                sb.append("<p>• Se recomienda revisar urgentemente las estrategias de cobro</p>");
                sb.append("<p>• Posible aumento en pedidos no pagados</p>");
                sb.append("<p>• Considerar implementar medidas preventivas</p>");
            } else if (porcentajeCambio < 0) {
                sb.append("<p><b>📉 ATENCIÓN:</b> El modelo predice una <b>disminución del ").append(String.format("%.1f", Math.abs(porcentajeCambio))).append("%</b> en las ganancias.</p>");
                sb.append("<p>• Revisar procesos de seguimiento de pagos</p>");
                sb.append("<p>• Monitorear tendencias de pagos pendientes</p>");
            } else {
                sb.append("<p><b>📊 ESTABILIDAD:</b> Se espera que las ganancias se mantengan <b>estables</b>.</p>");
                sb.append("<p>• Los patrones de pago se mantienen consistentes</p>");
                sb.append("<p>• No se esperan cambios significativos</p>");
            }
            sb.append("</div>");

            // ✅ EJEMPLO DE PREDICCIÓN INDIVIDUAL
            sb.append("<h3>🔍 Ejemplo de Predicción Individual:</h3>");
            Instance instEjemplo = data.instance(0);
            double prediccionEjemplo = wekaModelService.predecir(instEjemplo);
            String clasePredicha = data.classAttribute().value((int)prediccionEjemplo);

            sb.append("<div style='background-color: #e7f3ff; padding: 15px; border-radius: 5px;'>");
            sb.append("<p><b>Mesa:</b> ").append((int)instEjemplo.value(0)).append("</p>");
            sb.append("<p><b>Total del pedido:</b> $").append(String.format("%,.0f", instEjemplo.value(1))).append("</p>");
            sb.append("<p><b>Estado real:</b> ").append(instEjemplo.value(2) == 1 ? "<span style='color: green;'>✅ PAGADO</span>" : "<span style='color: red;'>❌ NO PAGADO</span>").append("</p>");
            sb.append("<p><b>Predicción del modelo:</b> <span style='font-weight: bold;'>").append(clasePredicha).append("</span></p>");
            sb.append("</div>");

            // ✅ RECOMENDACIONES
            sb.append("<h3>💡 Recomendaciones:</h3>");
            sb.append("<ul>");
            if (porcentajeCambio > 0) {
                sb.append("<li>Mantener las estrategias actuales de cobro</li>");
                sb.append("<li>Capitalizar la tendencia positiva</li>");
                sb.append("<li>Monitorear continuamente los indicadores</li>");
            } else {
                sb.append("<li>Reforzar el seguimiento de pagos pendientes</li>");
                sb.append("<li>Revisar políticas de crédito</li>");
                sb.append("<li>Implementar recordatorios de pago</li>");
            }
            sb.append("<li>Actualizar el modelo regularmente con nuevos datos</li>");
            sb.append("<li>Validar predicciones con resultados reales</li>");
            sb.append("</ul>");

            return sb.toString();

        } catch (Exception e) {
            System.out.println("❌ Exception en probarModelo: " + e.getMessage());
            e.printStackTrace();
            return "<div style='color: red; padding: 20px; border: 2px solid red;'><h3>❌ Error</h3><p>" + e.getMessage() + "</p></div>";
        }
    }
}