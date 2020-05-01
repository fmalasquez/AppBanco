package com.example.AppBanco.dao;
import com.example.AppBanco.modelo.Movimiento;
import com.example.AppBanco.modelo.RptaMovimiento;

public interface IDao {
    RptaMovimiento realizarTransferencia(Movimiento movi);
    RptaMovimiento getMovimientos(int idClienteLogeado);
    int existeCliente(int idCliente);
}