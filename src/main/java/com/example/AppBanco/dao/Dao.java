package com.example.AppBanco.dao;

import com.example.AppBanco.modelo.Movimiento;
import com.example.AppBanco.modelo.RptaMovimiento;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository("dao")
public class Dao implements IDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public RptaMovimiento realizarTransferencia(Movimiento movi) {
        RptaMovimiento rpta = new RptaMovimiento();
        try {
            System.err.println("realizarTransferencia....");
            String sql = "call realizar_trasnferencia(?, ?, ?, ?, ?, ?,?)";
            Connection connection = jdbcTemplate.getDataSource().getConnection();
            CallableStatement callableSt = connection.prepareCall(sql);
            callableSt.setInt(1, movi.getIdCliente());
            callableSt.setInt(2, movi.getIdClienteOtro());
            callableSt.setString(3, movi.getNrCuenta());
            callableSt.setDouble(4, movi.getMonto());
            callableSt.setString(5, movi.getTipo_moneda());

            callableSt.registerOutParameter(6, Types.INTEGER);
            callableSt.registerOutParameter(7, Types.VARCHAR);

            callableSt.executeUpdate();
            rpta.setCodigo_error(callableSt.getInt(6));
            rpta.setMsj_error(callableSt.getString(7));
            System.err.println("retorno: " + rpta.getCodigo_error() + " -- " + rpta.getMsj_error());
        } catch (Exception e) {
            e.printStackTrace();
            rpta.setCodigo_error(-1);
            rpta.setMsj_error(e.getMessage());
        }
        return rpta;
    }

    @Override
    public RptaMovimiento getMovimientos(int idClienteLogeado) {
        RptaMovimiento rpta = new RptaMovimiento();
        int existe = existeCliente(idClienteLogeado);
        if (existe == 0) {
            rpta.setCodigo_error(1);
            rpta.setMsj_error("El cliente con el id " + idClienteLogeado + " no existe.");
            return rpta;
        }
        String sql = "SELECT c1.nomb_cliente AS usuario_logeado,\n"
                + "       m.tipo_movi,\n"
                + "       m.monto,\n"
                + "       m.tipo_moneda,\n"
                + "       c2.nomb_cliente AS nomb_cliente_otro,\n"
                + "       c2.nro_cuenta AS nro_cuenta_otro, \n"
                + "       CASE WHEN m.tipo_movi = 'EGR' THEN 'rojo' ELSE 'verde' END AS color\n"
                + "  FROM movimiento m,\n"
                + "       cliente c1,\n"
                + "       cliente c2\n"
                + " WHERE m.id_cliente = c1.id_cliente\n"
                + "   AND m.nro_cuenta = c2.nro_cuenta\n"
                + "   AND c1.id_cliente = ?";
        List<Movimiento> lstMovi = jdbcTemplate.query(sql,
                new Object[]{idClienteLogeado},
                (rs, rNum)
                -> new Movimiento(0,
                        0,
                        null,
                        rs.getString("nro_cuenta_otro"),
                        rs.getString("tipo_movi"),
                        rs.getDouble("monto"),
                        rs.getString("tipo_moneda"),
                        rs.getString("color"),
                        rs.getString("nomb_cliente_otro"),
                        rs.getString("usuario_logeado")
                )
        );
        rpta.setCodigo_error(0);
        rpta.setMsj_error("Lista de movimientos correcta");
        rpta.setLstMovimientos(lstMovi);
        return rpta;
    }

    @Override
    public int existeCliente(int idCliente) {
        String sql = "SELECT COUNT(1) AS existe FROM cliente WHERE id_cliente = ?";
        return jdbcTemplate.queryForObject(sql, new Object[]{idCliente}, Integer.class);
    }
}
