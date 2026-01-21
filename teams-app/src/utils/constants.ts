// Facultades UCE
export const FACULTADES = [
  { id: 1, name: "Jurisprudencia, Ciencias Políticas y Sociales", code: "JCPS" },
  { id: 2, name: "Ciencias Médicas", code: "CM" },
  { id: 3, name: "Ingeniería y Ciencias Aplicadas", code: "ICA" },
  { id: 4, name: "Filosofía, Letras y Ciencias de la Educación", code: "FLCE" },
  { id: 5, name: "Ciencias Agrícolas", code: "CA" },
  { id: 6, name: "Comunicación Social", code: "CS" },
  { id: 7, name: "Ciencias Químicas", code: "CQ" },
  { id: 8, name: "Ciencias Económicas", code: "CE" },
  { id: 9, name: "Ciencias Psicológicas", code: "CP" },
  { id: 10, name: "Odontología", code: "OD" },
  { id: 11, name: "Arquitectura y Urbanismo", code: "AU" },
  { id: 12, name: "Artes", code: "AR" },
  { id: 13, name: "Ciencias Administrativas", code: "CA" },
  { id: 14, name: "Medicina Veterinaria y Zootecnia", code: "MVZ" },
  { id: 15, name: "Ingeniería en Geología, Minas, Petróleo y Ambiental", code: "IGMPA" },
  { id: 16, name: "Ingeniería Química", code: "IQ" },
  { id: 17, name: "Cultura Física", code: "CF" },
  { id: 18, name: "Ciencias de la Discapacidad, Atención Prehospitalaria y Desastres", code: "CDAPD" },
  { id: 19, name: "Ciencias Biológicas", code: "CB" },
  { id: 20, name: "Ciencias Sociales y Humanas", code: "CSH" },
  { id: 21, name: "Ciencias", code: "C" }
];

// Cafeterías de UCE
export const CAFETERIAS = [
  {
    id: 1,
    name: "Cafetería Central",
    location: "Edificio Principal",
    hours: "7:00 AM - 4:00 PM",
    image: "☕"
  },
  {
    id: 2,
    name: "Cafetería Medicina",
    location: "Facultad de Ciencias Médicas",
    hours: "7:00 AM - 5:00 PM",
    image: "🏥"
  },
  {
    id: 3,
    name: "Cafetería Ingeniería",
    location: "Edificio de Ingeniería",
    hours: "7:00 AM - 4:00 PM",
    image: "⚙️"
  },
  {
    id: 4,
    name: "Cafetería Estudiantes",
    location: "Casa del Estudiante",
    hours: "7:00 AM - 6:00 PM",
    image: "🎓"
  }
];

// Menú por categorías
export const MENU_CATEGORIES = {
  desayunos: {
    name: "Desayunos",
    icon: "🍳",
    items: [
      { id: 1, name: "Huevos Revueltos", price: 2.50, description: "Con pan tostado" },
      { id: 2, name: "Avena", price: 1.50, description: "Avena caliente con frutas" },
      { id: 3, name: "Hotcakes", price: 3.00, description: "3 Hotcakes con miel" },
      { id: 4, name: "Jugo Natural", price: 2.00, description: "Jugo recién hecho" },
      { id: 5, name: "Café Americano", price: 1.50, description: "Café reciente" }
    ]
  },
  empanadas: {
    name: "Empanadas",
    icon: "🥟",
    items: [
      { id: 6, name: "Empanada de Queso", price: 1.00, description: "Rellena de queso fresco" },
      { id: 7, name: "Empanada de Carne", price: 1.20, description: "Carne molida sazonada" },
      { id: 8, name: "Empanada de Verde", price: 0.80, description: "Rellena de verde" },
      { id: 9, name: "Empanada de Atún", price: 1.10, description: "Con atún fresco" }
    ]
  },
  sandwiches: {
    name: "Sándwiches",
    icon: "🥪",
    items: [
      { id: 10, name: "Sándwich de Jamón y Queso", price: 2.50, description: "Pan tostado" },
      { id: 11, name: "Sándwich de Pollo", price: 3.00, description: "Pollo desmenuzado" },
      { id: 12, name: "Sándwich Vegetal", price: 2.00, description: "Lechuga, tomate, cebolla" },
      { id: 13, name: "Sándwich de Atún", price: 3.50, description: "Atún con mayonesa" }
    ]
  },
  almuerzos: {
    name: "Almuerzos",
    icon: "🍱",
    items: [
      { id: 14, name: "Almuerzo Ejecutivo", price: 5.50, description: "Entrada, plato, bebida, postre" },
      { id: 15, name: "Filete a lo Pobre", price: 6.00, description: "Con papas, plátano y huevo" },
      { id: 16, name: "Encebollado", price: 4.50, description: "Especia tradicional ecuatoriana" },
      { id: 17, name: "Arroz con Pollo", price: 5.00, description: "Receta casera" }
    ]
  },
  bebidas: {
    name: "Bebidas",
    icon: "🥤",
    items: [
      { id: 18, name: "Café Expreso", price: 1.50, description: "Café espresso" },
      { id: 19, name: "Cappuccino", price: 2.50, description: "Con leche espumosa" },
      { id: 20, name: "Batido de Frutas", price: 2.00, description: "Fresa, plátano o mora" },
      { id: 21, name: "Refresco", price: 1.00, description: "Varios sabores" },
      { id: 22, name: "Agua", price: 0.50, description: "Agua natural o con gas" }
    ]
  },
  postres: {
    name: "Postres",
    icon: "🍰",
    items: [
      { id: 23, name: "Brownie", price: 2.00, description: "Chocolate derretido" },
      { id: 24, name: "Cheesecake", price: 2.50, description: "Frutos rojos" },
      { id: 25, name: "Pastel de 3 Leches", price: 2.00, description: "Clásico ecuatoriano" },
      { id: 26, name: "Helado", price: 1.50, description: "Varios sabores" }
    ]
  }
};

// Métodos de pago
export const PAYMENT_METHODS = [
  { id: "cash", name: "Efectivo", icon: "💵" },
  { id: "card", name: "Tarjeta de Débito", icon: "💳" },
  { id: "transfer", name: "Transferencia", icon: "📱" },
  { id: "wallet", name: "Billetera Digital", icon: "📲" }
];
