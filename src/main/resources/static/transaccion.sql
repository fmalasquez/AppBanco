create database AppBanco;
use AppBanco;

create table cliente (
id_cliente int primary key auto_increment,
nomb_cliente varchar (30),
saldo numeric,
nro_cuenta varchar(5),
usuario varchar(20),
clave varchar(64)
);
insert into cliente (nomb_cliente,saldo,nro_cuenta, usuario, clave) values ('Kaka',1000,'10001','kaka',md5(123));
insert into cliente (nomb_cliente,saldo,nro_cuenta, usuario, clave) values ('Neymar',2000,'10002','neymar',md5(123));
insert into cliente (nomb_cliente,saldo,nro_cuenta, usuario, clave) values ('Pizarro',3000,'10003','pizarro',md5(123));
insert into cliente (nomb_cliente,saldo,nro_cuenta, usuario, clave) values ('Gareca',4000,'10004','gareca',md5(123));
insert into cliente (nomb_cliente,saldo,nro_cuenta, usuario, clave) values ('Maradona',5000,'10005','maradona',md5(123));
insert into cliente (nomb_cliente,saldo,nro_cuenta, usuario, clave) values ('Pele',6000,'10006','pele',md5(123));

create table movimiento (
id_movimiento int primary key auto_increment,
id_cliente int,
nro_cuenta varchar(5),
tipo_movi varchar(20),
fecha_movi datetime default current_timestamp,
monto numeric,
tipo_moneda varchar(20));

--http://localhost:8080/api/v1/AppBanco/realizarTransferencia
--{
--	"idCliente" : 1,
--	"idClienteOtro" : 2,
--	"nrCuenta" : "10002",
--	"monto" : 500
--}

SELECT c1.nomb_cliente AS usuario_logeado, 
m.tipo_movi, m.monto,tipo_moneda, 
c2.nomb_cliente AS nomb_cliente_otro, 
c2.nro_cuenta AS nro_cuenta_otro, 
CASE WHEN m.tipo_movi = 'EGR' THEN 'rojo' ELSE 'verde' END AS color 
FROM movimiento m, cliente c1, cliente c2 
WHERE m.id_cliente = c1.id_cliente AND m.nro_cuenta = c2.nro_cuenta AND c1.id_cliente = 5;

--Stored Procedure Login--------------------------------
DELIMITER $$
CREATE PROCEDURE SP_Login(
    in_usuario varchar(20),
    in_clave varchar(64)
)
BEGIN
DECLARE resultado INT;
    SELECT COUNT(*) INTO resultado FROM cliente WHERE usuario LIKE in_usuario AND clave LIKE in_clave;
	IF resultado = 0 THEN
		SELECT -1;
	ELSE
		SELECT * FROM cliente WHERE usuario LIKE in_usuario AND clave LIKE in_clave;
	END IF;
END $$
---------------------------------------


DELIMITER $$
DROP PROCEDURE IF EXISTS realizar_trasnferencia;
CREATE PROCEDURE realizar_trasnferencia(
    IN _p_id_cliente_hace_depo INT,
    IN _p_id_cliente_reci_depo INT,
    IN _p_nro_cuenta_reci_depo VARCHAR(5),
    IN _p_monto                NUMERIC(6,2),
    IN _p_tipo_moneda          VARCHAR(20),
    OUT _p_cod_error           INT,
    OUT _p_msj_error           VARCHAR(100)
)
this_proc:BEGIN
    DECLARE _v_existe INT;
    DECLARE _v_monto_depositado NUMERIC;
    DECLARE _v_cnt_depos INT;
    DECLARE _v_nro_cuenta VARCHAR(5);
    DECLARE _v_saldo_hace NUMERIC;
    DECLARE _v_saldo_reci NUMERIC;
    DECLARE _v_tipo_moneda VARCHAR(20);
    --
    IF _p_monto <= 0 THEN
        SET _p_cod_error = 1;
        SET _p_msj_error = 'El monto tiene que ser un número positivo.';
        LEAVE this_proc;
    END IF;

--
    IF (_p_tipo_moneda != 'Dolares' OR 'Soles') THEN
        SET _p_cod_error = 8;
        SET _p_msj_error = 'El tipo de moneda solo pueden ser:Soles o Dolares.';
    END IF;
    --
    SELECT COUNT(1)
      INTO _v_existe
      FROM cliente c
     WHERE c.id_cliente = _p_id_cliente_hace_depo;
    --
    IF _v_existe = 0 THEN
        SET _p_cod_error = 2;
        SET _p_msj_error = CONCAT('El cliente con el id ', _p_id_cliente_hace_depo, ' no existe.');
        LEAVE this_proc;
    END IF;
    --
    SELECT COALESCE(SUM(m.monto), 0)
      INTO _v_monto_depositado
      FROM movimiento m
     WHERE m.id_cliente = _p_id_cliente_hace_depo
       AND m.tipo_movi  = 'EGR'
       AND DATE(m.fecha_movi) = CURRENT_DATE
    ;
    IF ( _v_monto_depositado + _p_monto > 1500) THEN
        SET _p_cod_error = 3;
        SET _p_msj_error = 'El cliente supera el límite de depósito del día.';
        LEAVE this_proc;
    END IF;
    --
    SELECT COUNT(1)
      INTO _v_cnt_depos
      FROM movimiento m
     WHERE m.id_cliente = _p_id_cliente_hace_depo
       AND m.tipo_movi = 'EGR'
       AND DATE(m.fecha_movi) = CURRENT_DATE
    ;
    IF _v_cnt_depos + 1 >= 5 THEN
        SET _p_cod_error = 4;
        SET _p_msj_error = 'El cliente ha llegado al límite de transferencias diarias.';
        LEAVE this_proc;
    END IF;
    --
    SELECT COUNT(1)
      INTO _v_existe
      FROM cliente c
     WHERE c.id_cliente = _p_id_cliente_reci_depo;
    --
    IF _v_existe = 0 THEN
        SET _p_cod_error = 5;
        SET _p_msj_error = CONCAT('El cliente con el id ', _p_id_cliente_reci_depo, ' no existe.');
        LEAVE this_proc;
    END IF;
    --
    SELECT nro_cuenta
      INTO _v_nro_cuenta
      FROM cliente
     WHERE id_cliente = _p_id_cliente_hace_depo;
    IF _v_nro_cuenta = _p_nro_cuenta_reci_depo THEN
        SET _p_cod_error = 6;
        SET _p_msj_error = 'No se puede depositar a si mismo.';
        LEAVE this_proc;
    END IF;
    --
    SELECT saldo
      INTO _v_saldo_hace
      FROM cliente
     WHERE id_cliente = _p_id_cliente_hace_depo;
    IF _p_monto > _v_saldo_hace THEN
        SET _p_cod_error = 7;
        SET _p_msj_error = 'El cliente no tiene el saldo suficiente.';
        LEAVE this_proc;
    END IF;
    --
    --
    SELECT saldo
      INTO _v_saldo_reci
      FROM cliente
     WHERE id_cliente = _p_id_cliente_reci_depo;
    --
    INSERT INTO movimiento (id_cliente, nro_cuenta, tipo_movi, monto,tipo_moneda)
        VALUES (_p_id_cliente_hace_depo, _p_nro_cuenta_reci_depo, 'EGR', _p_monto, _p_tipo_moneda);
    INSERT INTO movimiento (id_cliente, nro_cuenta, tipo_movi, monto,tipo_moneda)
        VALUES (_p_id_cliente_reci_depo, _v_nro_cuenta, 'ING', _p_monto,_p_tipo_moneda);
    UPDATE cliente SET saldo = ( _v_saldo_hace - _p_monto )
     WHERE id_cliente = _p_id_cliente_hace_depo;
    UPDATE cliente SET saldo = ( _v_saldo_reci + _p_monto )
     WHERE id_cliente = _p_id_cliente_reci_depo;
    SET _p_cod_error = 0;
    SET _p_msj_error = 'El depósito fue realizado correctamente.';
END$$
DELIMITER ;