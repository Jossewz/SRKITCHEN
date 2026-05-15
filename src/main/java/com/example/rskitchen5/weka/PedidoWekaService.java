package com.example.rskitchen5.weka;

import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.PedidoRep;
import org.springframework.stereotype.Service;
import weka.core.Attribute;
import weka.core.DenseInstance;
import weka.core.Instances;

import java.util.ArrayList;
import java.util.List;

@Service
public class PedidoWekaService {

    private final PedidoRep pedidoRepository;

    public PedidoWekaService(PedidoRep pedidoRepository) {
        this.pedidoRepository = pedidoRepository;
    }

    public Instances obtenerInstancias() {
        try {
            List<Pedido> pedidos = pedidoRepository.findAll();

            if (pedidos == null || pedidos.isEmpty()) {
                System.out.println("No hay pedidos en la base de datos.");
                return null;
            }

            ArrayList<Attribute> atributos = new ArrayList<>();
            atributos.add(new Attribute("mesaNum"));

            // ✅ pagado como predictor
            ArrayList<String> valoresPagado = new ArrayList<>();
            valoresPagado.add("NO_PAGADO");
            valoresPagado.add("PAGADO");
            atributos.add(new Attribute("pagado", valoresPagado));

            // ✅ total como CLASE (para regresión)
            atributos.add(new Attribute("total"));

            Instances data = new Instances("PedidosDataset", atributos, pedidos.size());
            // ✅ Clase en índice 2 (total)
            data.setClassIndex(2);

            for (Pedido p : pedidos) {
                double[] vals = new double[3];

                vals[0] = p.getMesaNum();
                vals[1] = p.isPagado() ? 1 : 0; // Predictor
                vals[2] = p.getTotal();          // Clase (valor a predecir)

                data.add(new DenseInstance(1.0, vals));
            }

            System.out.println("✅ Dataset para REGRESIÓN creado: " + data.numInstances() +
                    " instancias | Clase: total");
            return data;

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}