package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Factura;
import java.util.List;

public interface FacturaService {
    List<Factura> getAll();
    Factura getById(String id);
}

