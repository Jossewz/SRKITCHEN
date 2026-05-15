package com.example.rskitchen5.weka;

import org.springframework.stereotype.Service;
import weka.classifiers.Classifier;
import weka.core.Attribute;
import weka.core.DenseInstance;
import weka.core.Instance;
import weka.core.Instances;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.util.ArrayList;

@Service
public class WekaModelService {

    private Classifier model;
    private Instances datasetStructure;

    public WekaModelService() {
        try {

            String projectPath = System.getProperty("user.dir");
            String modelPath = projectPath + "/src/main/resources/weka/modeloPedido2.model";

            System.out.println("🔍 Buscando modelo en: " + modelPath);

            File modelFile = new File(modelPath);
            InputStream is = null;

            if (modelFile.exists()) {
                System.out.println("✅ Archivo encontrado con File");
                is = new FileInputStream(modelFile);
            } else {

                System.out.println("🔍 Buscando en classpath...");
                is = getClass().getResourceAsStream("/weka/modeloPedido2.model");

                if (is == null) {
                    System.err.println("❌ No se encontró el archivo del modelo en ninguna ubicación");
                    return;
                }
                System.out.println("✅ Archivo encontrado en classpath");
            }

            ObjectInputStream ois = new ObjectInputStream(is);
            model = (Classifier) ois.readObject();
            ois.close();
            is.close();

            System.out.println("✅ Modelo cargado correctamente");

            ArrayList<Attribute> attributes = new ArrayList<>();
            attributes.add(new Attribute("mesaNum"));
            attributes.add(new Attribute("num_items"));
            attributes.add(new Attribute("total"));

            ArrayList<String> pagadoValues = new ArrayList<>();
            pagadoValues.add("NO_PAGADO");
            pagadoValues.add("PAGADO");
            attributes.add(new Attribute("pagado", pagadoValues));

            datasetStructure = new Instances("ModelStructure", attributes, 0);
            datasetStructure.setClassIndex(3);

            System.out.println("Modelo cargado - Espera 4 atributos - Clase: pagado");

        } catch (Exception e) {
            System.err.println(" Error al cargar el modelo: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public double predecir(Instance instance) throws Exception {
        if (model == null) throw new Exception("El modelo no se cargó");

        Instance instanciaAdaptada = adaptarInstancia(instance);

        System.out.println("=== DEBUG WEKAMODELSERVICE ===");
        System.out.println("Instancia adaptada:");
        System.out.println("  mesaNum: " + instanciaAdaptada.value(0));
        System.out.println("  num_items: " + instanciaAdaptada.value(1));
        System.out.println("  total: " + instanciaAdaptada.value(2));
        System.out.println("  pagado: " + instanciaAdaptada.value(3));
        System.out.println("Dataset de la instancia: " + (instanciaAdaptada.dataset() != null ? "SÍ" : "NO"));

        double prediccion = model.classifyInstance(instanciaAdaptada);

        System.out.println("Predicción del modelo: " + prediccion);
        System.out.println("Es NaN?: " + Double.isNaN(prediccion));

        return prediccion;
    }

    public double[] distribucion(Instance instance) throws Exception {
        if (model == null) throw new Exception("El modelo no se cargó");

        Instance instanciaAdaptada = adaptarInstancia(instance);

        return model.distributionForInstance(instanciaAdaptada);
    }

    private Instance adaptarInstancia(Instance original) {
        Instance adaptada = new DenseInstance(4);

        adaptada.setValue(0, original.value(0)); // mesaNum
        adaptada.setValue(2, original.value(1)); // total (se mueve al índice 2)
        adaptada.setValue(3, original.value(2)); // pagado (se mueve al índice 3)

        double numItemsEstimado = Math.max(1, original.value(1) / 10000.0);
        adaptada.setValue(1, numItemsEstimado);

        adaptada.setDataset(datasetStructure);
        return adaptada;
    }

    public boolean isModeloCargado() {
        return model != null;
    }
}