import { faker } from "@faker-js/faker";
import fs from "fs";

// Entrenadores
let entrenadores = "IdEntrenador,Nombres,Apellidos,Especialidad,FechaContratacion,Correo,Telefono,Activo\n";
for (let i = 1; i <= 1000; i++) {
  entrenadores += `${i},${faker.person.firstName()},${faker.person.lastName()},${faker.person.jobTitle()},${faker.date.past().toISOString().split("T")[0]},${faker.internet.email()},${faker.phone.number({ style: "national" }) // genera números simples
},1\n`;
}
fs.writeFileSync("Entrenadores.csv", entrenadores);

// Clases
let clases = "IdClase,NombreClase,Descripcion,Cupo,Nivel\n";
for (let i = 1; i <= 1000; i++) {
  clases += `${i},Clase ${faker.word.noun()},${faker.lorem.sentence()},${faker.number.int({ min: 5, max: 30 })},${faker.helpers.arrayElement(["Básico","Intermedio","Avanzado"])}\n`;
}
fs.writeFileSync("Clases.csv", clases);

// Horarios
let horarios = "IdHorario,IdClase,IdEntrenador,Inicio,Fin,Ubicacion\n";
for (let i = 1; i <= 1000; i++) {
  const inicio = faker.date.future();
  const fin = new Date(inicio.getTime() + 60 * 60 * 1000); // +1 hora
  horarios += `${i},${faker.number.int({ min: 1, max: 1000 })},${faker.number.int({ min: 1, max: 100 })},${inicio.toISOString()},${fin.toISOString()},Sala ${faker.number.int({ min: 1, max: 10 })}\n`;
}
fs.writeFileSync("Horarios.csv", horarios);

// Inscripciones
let inscripciones = "IdInscripcion,IdHorario,IdSocio,FechaInscrito,Estado\n";
for (let i = 1; i <= 1000; i++) {
  inscripciones += `${i},${faker.number.int({ min: 1, max: 1000 })},${faker.number.int({ min: 1, max: 100 })},${faker.date.recent().toISOString()},Inscrito\n`;
}
fs.writeFileSync("Inscripciones.csv", inscripciones);

// Pagos
let pagos = "IdPago,IdSocio,Monto,FechaPago,MetodoPago,Referencia\n";
for (let i = 1; i <= 1000; i++) {
  pagos += `${i},${faker.number.int({ min: 1, max: 1000 })},${faker.finance.amount(10, 200, 2)},${faker.date.recent().toISOString()},${faker.helpers.arrayElement(["Efectivo","Tarjeta","Transferencia"])},${faker.string.uuid()}\n`;
}
fs.writeFileSync("Pagos.csv", pagos);

console.log("CSV generados correctamente 🚀");
