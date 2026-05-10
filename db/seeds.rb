puts "Limpiando datos anteriores..."
Enrollment.destroy_all
Message.destroy_all
Notification.destroy_all
Event.destroy_all
Organization.destroy_all
User.destroy_all

# ── Admin ──────────────────────────────────────────────────────────────────
puts "Creando admin..."
admin = User.create!(
  nombres:              "Super",
  apellidos:            "Admin",
  email:                "admin@voluntariado.ec",
  password:             "password123",
  password_confirmation: "password123",
  role:                 :admin
)

# ── Organizaciones + representantes ───────────────────────────────────────
puts "Creando organizaciones..."

rep1 = User.create!(
  nombres:              "Karla",
  apellidos:            "Mendoza",
  cedula:               "1713175071",
  email:                "karla@cruzroja.ec",
  password:             "password123",
  password_confirmation: "password123",
  role:                 :organizador
)
org1 = Organization.create!(
  name:        "Cruz Roja Ecuatoriana",
  ruc:         "1713175071001",
  location:    "Quito, Pichincha",
  description: "Organización humanitaria que brinda asistencia en emergencias, desastres y situaciones de vulnerabilidad.",
  user:        rep1
)

rep2 = User.create!(
  nombres:              "Diego",
  apellidos:            "Salazar",
  cedula:               "1720461224",
  email:                "diego@hogar.ec",
  password:             "password123",
  password_confirmation: "password123",
  role:                 :organizador
)
org2 = Organization.create!(
  name:        "Hogar de Cristo",
  ruc:         "1720461224001",
  location:    "Guayaquil, Guayas",
  description: "Institución que brinda atención a personas en situación de calle, adicciones y extrema pobreza.",
  user:        rep2
)

rep3 = User.create!(
  nombres:              "Sofía",
  apellidos:            "Vega",
  cedula:               "1756108896",
  email:                "sofia@tejiendo.ec",
  password:             "password123",
  password_confirmation: "password123",
  role:                 :organizador
)
org3 = Organization.create!(
  name:        "Tejiendo Redes",
  ruc:         "1756108896001",
  location:    "Cuenca, Azuay",
  description: "Fundación orientada al fortalecimiento comunitario en zonas rurales de la sierra ecuatoriana.",
  user:        rep3
)

# ── Voluntarios ───────────────────────────────────────────────────────────
puts "Creando voluntarios..."

voluntarios_data = [
  { nombres: "Ana",     apellidos: "Torres",   cedula: "0102345678", email: "ana@mail.ec"     },
  { nombres: "Luis",    apellidos: "Pérez",    cedula: "0201234567", email: "luis@mail.ec"    },
  { nombres: "María",   apellidos: "Zambrano", cedula: "1300123456", email: "maria@mail.ec"   },
  { nombres: "Carlos",  apellidos: "Andrade",  cedula: "0901234567", email: "carlos@mail.ec"  },
  { nombres: "Valeria", apellidos: "Mora",     cedula: "1712345678", email: "valeria@mail.ec" },
]

voluntarios = voluntarios_data.map do |v|
  User.create!(
    nombres:              v[:nombres],
    apellidos:            v[:apellidos],
    cedula:               v[:cedula],
    email:                v[:email],
    password:             "password123",
    password_confirmation: "password123",
    role:                 :voluntario
  )
end

# ── Eventos ───────────────────────────────────────────────────────────────
puts "Creando eventos..."

evento1 = Event.create!(
  title:        "Jornada de Primeros Auxilios",
  description:  "Capacitación práctica en técnicas de primeros auxilios para la comunidad. Se cubren RCP, manejo de heridas y traslado de accidentados.",
  date:         2.weeks.from_now,
  location:     "Parque La Carolina, Quito",
  status:       :activo,
  organization: org1
)

evento2 = Event.create!(
  title:        "Reparto de Kits Alimentarios",
  description:  "Distribución de cajas con alimentos básicos para familias en situación de vulnerabilidad en el sector norte de Guayaquil.",
  date:         1.week.from_now,
  location:     "Sector Mapasingue, Guayaquil",
  status:       :activo,
  organization: org2
)

evento3 = Event.create!(
  title:        "Reforestación Comunitaria",
  description:  "Siembra de 500 árboles nativos en las laderas del río Tomebamba junto a familias del sector.",
  date:         3.weeks.from_now,
  location:     "Río Tomebamba, Cuenca",
  status:       :activo,
  organization: org3
)

evento4 = Event.create!(
  title:        "Simulacro de Evacuación",
  description:  "Entrenamiento en procedimientos de evacuación ante sismos para voluntarios de zona norte de Quito.",
  date:         1.month.ago,
  status:       :finalizado,
  location:     "Cotocollao, Quito",
  organization: org1
)

# ── Inscripciones de ejemplo ───────────────────────────────────────────────
puts "Creando inscripciones..."

Enrollment.create!(user: voluntarios[0], event: evento1, status: :inscrito)
Enrollment.create!(user: voluntarios[1], event: evento1, status: :inscrito)
Enrollment.create!(user: voluntarios[2], event: evento2, status: :inscrito)
Enrollment.create!(user: voluntarios[3], event: evento2, status: :cancelado)
Enrollment.create!(user: voluntarios[4], event: evento3, status: :inscrito)
Enrollment.create!(user: voluntarios[0], event: evento4, status: :asistio,
                   check_in_time: 1.month.ago + 9.hours,
                   latitude: -0.1054, longitude: -78.5018)
Enrollment.create!(user: voluntarios[1], event: evento4, status: :asistio,
                   check_in_time: 1.month.ago + 9.hours + 5.minutes,
                   latitude: -0.1057, longitude: -78.5021)

puts ""
puts "═══════════════════════════════════════════════"
puts "  Seeds cargados. Credenciales de acceso:"
puts "═══════════════════════════════════════════════"
puts "  Admin:         admin@voluntariado.ec / password123"
puts "  Organizador 1: karla@cruzroja.ec    / password123"
puts "  Organizador 2: diego@hogar.ec       / password123"
puts "  Voluntario 1:  ana@mail.ec          / password123"
puts "  Voluntario 2:  luis@mail.ec         / password123"
puts "═══════════════════════════════════════════════"
