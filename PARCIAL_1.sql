SET SERVEROUTPUT ON;

DECLARE -- Declare variables and parameters
  periodo VARCHAR2(7) := :periodo;
  rut_empleado VARCHAR2(11);
  nombre VARCHAR2(30);
  ventas NUMBER;
  total_ventas NUMBER;
  porcentaje NUMBER; -- Categorization percentage
  porcentaje_incentivo1 NUMBER := :porcentaje_incentivo1; -- 10 or more sales 
  porcentaje_incentivo2 NUMBER := :porcentaje_incentivo2; -- Between 5 and 9 sales
  porcentaje_incentivo3 NUMBER := :porcentaje_incentivo3; -- Between 1 and 4 sales
  incentivo NUMBER;
  total_incentivos NUMBER;
  
  -- Cursor for sales and incentive calculations
  CURSOR cur_incentivo IS 
    SELECT TO_CHAR(FECHA_BOLETA, 'MM-YYYY') AS PERIODO, 
            e.rut_empleado AS RUT_EMPLEADO, 
            (e.apellidos ||' '|| e.nombres) AS NOMBRE, 
            COUNT(*) AS VENTAS, 
            SUM(d.cantidad * p.precio) AS TOTAL_VENTAS,
            c.porcentaje AS PORCENTAJE,
            ROUND(SUM(d.cantidad * p.precio) * (c.porcentaje/100)) +
            ROUND(SUM(d.cantidad * p.precio) *
            CASE
                WHEN COUNT(*) >= 10 THEN (porcentaje_incentivo1/100)
                WHEN COUNT(*) BETWEEN 5 AND 9 THEN (porcentaje_incentivo2/100)
                WHEN COUNT(*) BETWEEN 1 AND 4 THEN (porcentaje_incentivo3/100)
                ELSE 0
            END) AS TOTAL_INCENTIVOS
    FROM BOLETA b
    JOIN DETALLEBOLETA d ON b.id_boleta = d.id_boleta
    JOIN PRODUCTO p ON d.id_producto = p.id_producto
    JOIN EMPLEADO e ON b.id_empleado = e.id_empleado
    JOIN CATEGORIZACION c ON e.id_categorizacion = c.id_categorizacion
    WHERE TO_CHAR(fecha_boleta, 'MM-YYYY') = periodo
    GROUP BY TO_CHAR(fecha_boleta, 'MM-YYYY'), e.rut_empleado, e.nombres, e.apellidos,  c.porcentaje
    ORDER BY TO_NUMBER(e.rut_empleado) ASC;
BEGIN
  -- Clear existing records before inserting new data
  EXECUTE IMMEDIATE 'TRUNCATE TABLE INCENTIVO_EMPLEADO_SE_NAVARRETE';
  
  -- Loop through cursor records
  FOR rec_incentivo IN cur_incentivo LOOP
    periodo := rec_incentivo.PERIODO;
    rut_empleado := rec_incentivo.RUT_EMPLEADO;
    porcentaje := rec_incentivo.PORCENTAJE;
    nombre := rec_incentivo.NOMBRE;
    total_ventas := rec_incentivo.TOTAL_VENTAS; 
    total_incentivos := rec_incentivo.TOTAL_INCENTIVOS;
       
    -- Insert processed data into target table
    INSERT INTO INCENTIVO_EMPLEADO_SE_NAVARRETE (PERIODO, RUT_EMPLEADO, NOMBRE, TOTAL_VENTAS, TOTAL_INCENTIVOS)
    VALUES (periodo, rut_empleado, nombre, total_ventas, total_incentivos);
  END LOOP;
END;
/
