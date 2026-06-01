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
  nombres:              "Marco",
  apellidos:            "Salazar",
  cedula:               "1703876134",
  email:                "marco@hogar.ec",
  password:             "password123",
  password_confirmation: "password123",
  role:                 :organizador
)
org2 = Organization.create!(
  name:        "Hogar de Cristo",
  ruc:         "1703876134001",
  location:    "Guayaquil, Guayas",
  description: "Institución que brinda atención a personas en situación de calle, adicciones y extrema pobreza.",
  user:        rep2
)

# ── Voluntarios ───────────────────────────────────────────────────────────
puts "Creando voluntarios..."

# Voluntarios en Quito (4)
vol1 = User.create!(
  nombres: "Ana", apellidos: "Torres",
  cedula: "1732104425", email: "ana@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol1, score: 9.5,
  skills: %w[primeros_auxilios busqueda_rescate],
  certifications: { "cert_primeros_auxilios" => "1", "cert_rescate" => "1", "cert_enfermeria" => "1" },
  quiz_answers: { "q1"=>4,"q2"=>4,"q3"=>4,"q4"=>3,"q5"=>4,"q6"=>4,"q7"=>3,"q8"=>4,"q9"=>3,"q10"=>3,
                  "q11"=>2,"q12"=>2,"q13"=>3,"q14"=>2,"q15"=>2,"q16"=>2,"q17"=>2,"q18"=>2,"q19"=>1,"q20"=>2,
                  "q21"=>1,"q22"=>1,"q23"=>1,"q24"=>0,"q25"=>1 },
  quiz_completed_at: 1.month.ago,
  country: "Ecuador", city: "Quito", sector: "Iñaquito",
  available: true
)

vol2 = User.create!(
  nombres: "Luis", apellidos: "Pérez",
  cedula: "1701051235", email: "luis@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol2, score: 7.5,
  skills: %w[busqueda_rescate maquinaria_construccion],
  certifications: { "cert_rescate" => "1", "cert_maquinaria" => "1" },
  quiz_answers: { "q1"=>2,"q2"=>2,"q3"=>2,"q4"=>2,"q5"=>1,"q6"=>4,"q7"=>4,"q8"=>3,"q9"=>4,"q10"=>3,
                  "q11"=>1,"q12"=>1,"q13"=>2,"q14"=>1,"q15"=>1,"q16"=>2,"q17"=>2,"q18"=>1,"q19"=>2,"q20"=>2,
                  "q21"=>4,"q22"=>3,"q23"=>4,"q24"=>3,"q25"=>2 },
  quiz_completed_at: 2.months.ago,
  country: "Ecuador", city: "Quito", sector: "Kennedy",
  available: true
)

vol3 = User.create!(
  nombres: "María", apellidos: "Zambrano",
  cedula: "1735210559", email: "maria@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol3, score: 5.5,
  skills: %w[apoyo_psicosocial logistica_abastecimiento],
  certifications: { "cert_pap" => "1" },
  quiz_answers: { "q1"=>2,"q2"=>1,"q3"=>1,"q4"=>2,"q5"=>1,"q6"=>1,"q7"=>0,"q8"=>1,"q9"=>0,"q10"=>1,
                  "q11"=>4,"q12"=>3,"q13"=>4,"q14"=>3,"q15"=>3,"q16"=>3,"q17"=>3,"q18"=>2,"q19"=>2,"q20"=>3,
                  "q21"=>0,"q22"=>0,"q23"=>1,"q24"=>0,"q25"=>0 },
  quiz_completed_at: 3.weeks.ago,
  country: "Ecuador", city: "Quito", sector: "Cotocollao",
  available: true
)

vol4 = User.create!(
  nombres: "Carlos", apellidos: "Andrade",
  cedula: "1701021550", email: "carlos@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol4, score: 3.0,
  skills: %w[apoyo_psicosocial],
  certifications: {},
  quiz_answers: { "q1"=>1,"q2"=>1,"q3"=>1,"q4"=>1,"q5"=>1,"q6"=>0,"q7"=>0,"q8"=>1,"q9"=>0,"q10"=>0,
                  "q11"=>3,"q12"=>2,"q13"=>3,"q14"=>2,"q15"=>2,"q16"=>1,"q17"=>1,"q18"=>1,"q19"=>0,"q20"=>1,
                  "q21"=>0,"q22"=>0,"q23"=>0,"q24"=>0,"q25"=>0 },
  quiz_completed_at: 2.weeks.ago,
  country: "Ecuador", city: "Quito", sector: "La Magdalena",
  available: true
)

# Voluntarios en Guayaquil (3)
vol5 = User.create!(
  nombres: "Valeria", apellidos: "Mora",
  cedula: "0931301154", email: "valeria@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol5, score: 8.5,
  skills: %w[primeros_auxilios apoyo_psicosocial logistica_abastecimiento],
  certifications: { "cert_primeros_auxilios" => "1", "cert_pap" => "1", "cert_conduccion" => "1" },
  quiz_answers: { "q1"=>4,"q2"=>3,"q3"=>3,"q4"=>4,"q5"=>3,"q6"=>2,"q7"=>2,"q8"=>2,"q9"=>2,"q10"=>2,
                  "q11"=>4,"q12"=>4,"q13"=>4,"q14"=>3,"q15"=>3,"q16"=>4,"q17"=>3,"q18"=>3,"q19"=>3,"q20"=>4,
                  "q21"=>0,"q22"=>0,"q23"=>1,"q24"=>0,"q25"=>0 },
  quiz_completed_at: 1.month.ago,
  country: "Ecuador", city: "Guayaquil", sector: "Urdesa",
  available: true
)

vol6 = User.create!(
  nombres: "Roberto", apellidos: "Cevallos",
  cedula: "0920553054", email: "roberto@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol6, score: 6.0,
  skills: %w[logistica_abastecimiento maquinaria_construccion],
  certifications: { "cert_conduccion" => "1", "cert_maquinaria" => "1" },
  quiz_answers: { "q1"=>1,"q2"=>1,"q3"=>1,"q4"=>1,"q5"=>1,"q6"=>2,"q7"=>2,"q8"=>2,"q9"=>1,"q10"=>2,
                  "q11"=>1,"q12"=>1,"q13"=>2,"q14"=>1,"q15"=>1,"q16"=>3,"q17"=>3,"q18"=>3,"q19"=>4,"q20"=>3,
                  "q21"=>3,"q22"=>2,"q23"=>3,"q24"=>2,"q25"=>2 },
  quiz_completed_at: 5.weeks.ago,
  country: "Ecuador", city: "Guayaquil", sector: "Kennedy",
  available: true
)

vol7 = User.create!(
  nombres: "Diana", apellidos: "Llerena",
  cedula: "0930202205", email: "diana@mail.ec",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol7, score: 2.0,
  skills: [],
  certifications: {},
  quiz_answers: { "q1"=>1,"q2"=>0,"q3"=>0,"q4"=>1,"q5"=>0,"q6"=>0,"q7"=>0,"q8"=>1,"q9"=>0,"q10"=>0,
                  "q11"=>1,"q12"=>0,"q13"=>1,"q14"=>0,"q15"=>0,"q16"=>0,"q17"=>0,"q18"=>0,"q19"=>1,"q20"=>0,
                  "q21"=>0,"q22"=>0,"q23"=>0,"q24"=>0,"q25"=>0 },
  quiz_completed_at: 1.week.ago,
  country: "Ecuador", city: "Guayaquil", sector: "Mapasingue",
  available: true
)

# Voluntario en Bogotá (Colombia)
vol8 = User.create!(
  nombres: "Sebastián", apellidos: "Ríos",
  cedula: "1721420527", email: "sebas@mail.co",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol8, score: 7.0,
  skills: %w[busqueda_rescate primeros_auxilios],
  certifications: { "cert_rescate" => "1", "cert_bombero" => "1" },
  quiz_answers: { "q1"=>3,"q2"=>3,"q3"=>3,"q4"=>2,"q5"=>3,"q6"=>4,"q7"=>3,"q8"=>3,"q9"=>3,"q10"=>3,
                  "q11"=>2,"q12"=>2,"q13"=>3,"q14"=>2,"q15"=>2,"q16"=>2,"q17"=>2,"q18"=>1,"q19"=>1,"q20"=>2,
                  "q21"=>1,"q22"=>1,"q23"=>2,"q24"=>1,"q25"=>1 },
  quiz_completed_at: 6.weeks.ago,
  country: "Colombia", city: "Bogotá", sector: "Chapinero",
  available: true
)

# Voluntario en Lima (Perú)
vol9 = User.create!(
  nombres: "Patricia", apellidos: "Quispe",
  cedula: "0914053228", email: "patricia@mail.pe",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol9, score: 4.5,
  skills: %w[apoyo_psicosocial primeros_auxilios],
  certifications: { "cert_primeros_auxilios" => "1" },
  quiz_answers: { "q1"=>2,"q2"=>2,"q3"=>2,"q4"=>2,"q5"=>2,"q6"=>1,"q7"=>0,"q8"=>1,"q9"=>0,"q10"=>1,
                  "q11"=>3,"q12"=>2,"q13"=>3,"q14"=>2,"q15"=>2,"q16"=>1,"q17"=>1,"q18"=>1,"q19"=>0,"q20"=>1,
                  "q21"=>0,"q22"=>0,"q23"=>0,"q24"=>0,"q25"=>0 },
  quiz_completed_at: 3.weeks.ago,
  country: "Perú", city: "Lima", sector: "Miraflores",
  available: true
)

# Voluntario en Buenos Aires (Argentina)
vol10 = User.create!(
  nombres: "Martín", apellidos: "Fernández",
  cedula: "1741500050", email: "martin@mail.ar",
  password: "password123", password_confirmation: "password123",
  role: :voluntario
)
VolunteerProfile.create!(
  user: vol10, score: 6.5,
  skills: %w[maquinaria_construccion logistica_abastecimiento],
  certifications: { "cert_construccion" => "1", "cert_maquinaria" => "1" },
  quiz_answers: { "q1"=>1,"q2"=>1,"q3"=>1,"q4"=>1,"q5"=>1,"q6"=>2,"q7"=>2,"q8"=>2,"q9"=>2,"q10"=>2,
                  "q11"=>1,"q12"=>1,"q13"=>2,"q14"=>1,"q15"=>1,"q16"=>3,"q17"=>3,"q18"=>3,"q19"=>2,"q20"=>3,
                  "q21"=>4,"q22"=>4,"q23"=>3,"q24"=>3,"q25"=>3 },
  quiz_completed_at: 2.months.ago,
  country: "Argentina", city: "Buenos Aires", sector: "Palermo",
  available: true
)

voluntarios = [vol1, vol2, vol3, vol4, vol5, vol6, vol7, vol8, vol9, vol10]

# ── Eventos ───────────────────────────────────────────────────────────────
puts "Creando eventos..."

# Evento T2 en Quito - debería convocar a vol1, vol2, vol3 (con score >= 5.0 en Quito)
evento_t2 = Event.create!(
  title:           "Accidente Vial Multiple - Av. Occidental",
  description:     "Colisión múltiple en la Av. Occidental con varios heridos graves. Se requieren voluntarios con conocimientos de primeros auxilios y logística.",
  date:            3.hours.from_now,
  location:        "Ecuador, Quito, Kennedy",
  status:          :activo,
  organization:    org1,
  emergency_level: 2,
  emergency_type:  "accidente_vial",
  required_skills: %w[primeros_auxilios logistica_abastecimiento],
  min_score:       5.0
)

# Evento T4 en Guayaquil - debería convocar a vol5, vol6 (con score >= 6.5 en Guayaquil)
evento_t4 = Event.create!(
  title:           "Inundación Urbana - Bastión Popular",
  description:     "Inundación severa en sector Bastión Popular por lluvias intensas. Se requieren voluntarios para rescate, logística y apoyo psicosocial.",
  date:            1.hour.from_now,
  location:        "Ecuador, Guayaquil, Bastión Popular",
  status:          :activo,
  organization:    org2,
  emergency_level: 4,
  emergency_type:  "inundacion_urbana",
  required_skills: %w[busqueda_rescate logistica_abastecimiento],
  min_score:       6.5
)

# Evento T6 - catástrofe en Quito
evento_t6 = Event.create!(
  title:           "Terremoto 6.8 - Quito",
  description:     "Sismo de magnitud 6.8 con epicentro en Quito Norte. Múltiples edificaciones colapsadas, búsqueda y rescate en curso.",
  date:            30.minutes.from_now,
  location:        "Ecuador, Quito, Iñaquito",
  status:          :activo,
  organization:    org1,
  emergency_level: 6,
  emergency_type:  "terremoto",
  required_skills: %w[busqueda_rescate maquinaria_construccion primeros_auxilios],
  min_score:       8.0
)

# Evento normal sin emergencia
evento_normal = Event.create!(
  title:           "Jornada de Primeros Auxilios Comunitaria",
  description:     "Capacitación práctica en técnicas de primeros auxilios para la comunidad. Se cubren RCP, manejo de heridas y traslado de accidentados.",
  date:            2.weeks.from_now,
  location:        "Parque La Carolina, Quito",
  status:          :activo,
  organization:    org1
)

# Evento finalizado (se crea con date futura y luego se actualiza para evitar validación)
evento_finalizado = Event.new(
  title:           "Simulacro de Evacuación",
  description:     "Entrenamiento en procedimientos de evacuación ante sismos para voluntarios de zona norte de Quito.",
  date:            1.month.ago,
  status:          :finalizado,
  location:        "Cotocollao, Quito",
  organization:    org1
)
evento_finalizado.save!(validate: false)

# Inscripciones de ejemplo en evento finalizado
Enrollment.create!(user: vol1, event: evento_finalizado, status: :asistio, attended_at: 1.month.ago + 9.hours)
Enrollment.create!(user: vol2, event: evento_finalizado, status: :asistio, attended_at: 1.month.ago + 9.hours + 5.minutes)

puts ""
puts "═══════════════════════════════════════════════"
puts "  Seeds cargados. Credenciales de acceso:"
puts "═══════════════════════════════════════════════"
puts "  Admin:         admin@voluntariado.ec  / password123"
puts "  Organizador 1: karla@cruzroja.ec     / password123"
puts "  Organizador 2: marco@hogar.ec        / password123"
puts "  Voluntario 1:  ana@mail.ec           / password123 (score 9.5, Quito)"
puts "  Voluntario 2:  luis@mail.ec          / password123 (score 7.5, Quito)"
puts "  Voluntario 3:  maria@mail.ec         / password123 (score 5.5, Quito)"
puts "  Voluntario 4:  carlos@mail.ec        / password123 (score 3.0, Quito)"
puts "  Voluntario 5:  valeria@mail.ec       / password123 (score 8.5, Guayaquil)"
puts "  Voluntario 6:  roberto@mail.ec       / password123 (score 6.0, Guayaquil)"
puts "  Voluntario 7:  diana@mail.ec         / password123 (score 2.0, Guayaquil)"
puts "  Voluntario 8:  sebas@mail.co         / password123 (score 7.0, Bogotá)"
puts "  Voluntario 9:  patricia@mail.pe      / password123 (score 4.5, Lima)"
puts "  Voluntario 10: martin@mail.ar        / password123 (score 6.5, Buenos Aires)"
puts "═══════════════════════════════════════════════"
puts "  Eventos de emergencia:"
puts "  - T2 Accidente Vial (Quito) → convocar score >= 5.0"
puts "  - T4 Inundación (Guayaquil) → convocar score >= 6.5"
puts "  - T6 Terremoto (Quito)      → convocar score >= 8.0"
puts "═══════════════════════════════════════════════"
