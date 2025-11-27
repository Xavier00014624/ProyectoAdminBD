# 🏋️‍♂️ Sistema de Reservas de Gimnasio  
---
Estudiantes: 
- **Christopher Alejandro Madrid Arrazabal #00063824,
- **Juan Alberto Bustillo Rodríguez #00099223,
- **Hector Ernesto Argueta Constanza #00012424,
- **Xavier Ernesto Garcia Villacorta #00014624
---
### Proyecto Administracion de bases de datos — SQL Server + Power BI

Este proyecto implementa un sistema completo de gestión para un gimnasio, incluyendo el manejo de **socios, clases, horarios, inscripciones y pagos**, con **auditoría, seguridad, índices e integración directa con Power BI** para análisis empresarial.

---
## 📚 Contenido del proyecto
- **Modelo relacional del gimnasio**  
- **Scripts SQL completos**: creación, inserción, índices, auditoría y roles  
- **Modelo de datos para Power BI**  
- **Dashboard interactivo** conectado a SQL Server  
- **Documento técnico** (diccionario de datos, diagramas, backup, etc.)  
- **Diagrama entidad–relación (ERD)**  
- **Pruebas de rendimiento e índices**

---
## 🧱 Arquitectura general

El proyecto se divide en tres capas principales:
### 1. Base de Datos — SQL Server
Incluye:
- Creación de tablas bajo el esquema `gimnasio`  
- Auditoría mediante triggers y el esquema `auditoria`  
- Relaciones 1:N entre entidades principales  
- Carga masiva (`BULK INSERT`) desde archivos CSV  
- Seguridad por **roles**, **usuarios** y **permisos mínimos**  
- Índices para optimización (correo, fecha de pago, IdClase, etc.)  
- Funciones ventana (`OVER`, `RANK`, `AVG`, `PARTITION BY`)

### 2. Modelo Entidad–Relación (ERD)
Incluye tablas:
- **Socios**
- **Entrenadores**
- **Clases**
- **Horarios**
- **Inscripciones**
- **Pagos**

Con cardinalidades correctas y normalización.

### 3. Dashboard — Power BI
Conexión directa a SQL Server para visualización interactiva:

- Ingresos totales  
- Pagos por método  
- Socios activos  
- Top 10 socios  
- Clases más ocupadas  
- Ingresos por mes  
- Ingresos acumulados  

Medidas DAX personalizadas:
```DAX
TotalIngresos = SUM('gimnasio Pagos'[Monto])

PromedioPago = AVERAGE('gimnasio Pagos'[Monto])

SociosActivos = CALCULATE(COUNTROWS('gimnasio Socios'), 'gimnasio Socios'[Estado] = 1)

IngresosPorMes = CALCULATE([TotalIngresos], VALUES(Calendario[Month]))

IngresosAcumulados =
CALCULATE(
    [TotalIngresos],
    FILTER(
        ALL(Calendario),
        Calendario[Date] <= MAX(Calendario[Date])
    )
)
