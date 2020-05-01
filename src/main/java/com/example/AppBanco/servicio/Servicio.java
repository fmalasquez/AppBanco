package com.example.AppBanco.servicio;

import com.example.AppBanco.dao.Dao;
import com.example.AppBanco.modelo.Movimiento;
import com.example.AppBanco.modelo.RptaMovimiento;
import java.util.List;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.RequestBody;

@Service
public class Servicio {
    
    private final Dao dao;
    
    public Servicio(@Qualifier("dao") Dao __dao) {
        this.dao = __dao;
    }
    
    public RptaMovimiento realizarTransferencia(Movimiento movi) {
        return dao.realizarTransferencia(movi);
    }
    
    public RptaMovimiento getMovimientos(int idClienteLogeado) {
        return dao.getMovimientos(idClienteLogeado);
    }

}