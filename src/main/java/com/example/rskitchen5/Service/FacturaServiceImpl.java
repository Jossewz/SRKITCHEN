package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Repository.FacturaRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class FacturaServiceImpl implements FacturaService {

    @Autowired
    private FacturaRep facturaRep;

    @Override
    public List<Factura> getAll() {
        return facturaRep.findAll();
    }

    @Override
    public Factura getById(String id) {
        Optional<Factura> optionalFactura = facturaRep.findById(id);
        return optionalFactura.orElse(null);
    }
}
