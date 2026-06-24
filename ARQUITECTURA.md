# Arquitectura del Sistema — Mapa Completo

Referencia técnica de todos los archivos, modelos, relaciones, rutas, vistas, servicios y lógica de negocio.

---

## 1. Modelos y relaciones

### Diagrama de relaciones

```
User ──has_one──► VolunteerProfile
User ──has_one──► Organization (como organizador)
User ──has_many─► Enrollments
User ──has_many─► Events (through Enrollments)
User ──has_many─► Notifications
User ──has_many─► Messages

Organization ──has_many──► Events
Organization ──belongs_to─► User (representante/organizador)

Event ──has_many──► Enrollments
Event ──has_many──► Users (through Enrollments)
Event ──has_many──► Messages
Event ──belongs_to─► Organization

Enrollment ──belongs_to──► User
Enrollment ──belongs_to──► Event
Enrollment ──has_one────► EnrollmentReview

EnrollmentReview ──belongs_to──► Enrollment
EnrollmentReview ──belongs_to──► User (reviewer — el organizador)

Message ──belongs_to──► Event
Message ──belongs_to──► User

Notification ──belongs_to──► User
Notification ──belongs_to──► notifiable (polimórfico: Event | Enrollment)
```

---

### `User` — `app/models/user.rb`

**Columnas principales:**
- `email`, `encrypted_password` — Devise
- `nombres`, `apellidos` (virtuales → `name`)
- `cedula` (string, 10 dígitos)
- `role` (integer enum: `admin=0`, `organizador=1`, `voluntario=2`)

**Asociaciones:**
- `has_one :volunteer_profile, dependent: :destroy`
- `has_one :organization` (como representante)
- `has_many :enrollments, dependent: :destroy`
- `has_many :events, through: :enrollments`
- `has_many :notifications, dependent: :destroy`
- `has_many :messages`

**Validaciones:**
- `cedula` validada con `EcuadorValidations` solo para voluntarios
- Email único por Devise

**Métodos clave:**
- `name` → `"#{nombres} #{apellidos}".strip`
- `profile_complete?` → `volunteer_profile&.quiz_completed_at.present?`
- `admin?`, `organizador?`, `voluntario?` → generados por enum

---

### `Organization` — `app/models/organization.rb`

**Columnas:**
- `name` (string)
- `ruc` (string, 13 dígitos)
- `description` (text)
- `location` (string — formato "País, Ciudad, Sector")
- `user_id` (FK → representante/organizador)

**Asociaciones:**
- `belongs_to :user`
- `has_many :events, dependent: :destroy`

**Validaciones:**
- `ruc` validado con `EcuadorValidations#ruc_ecuatoriano_valido`
- `name`, `location` presentes

---

### `Event` — `app/models/event.rb`

**Columnas:**
- `title`, `description`, `date` (datetime)
- `location` (string — "País, Ciudad, Sector")
- `status` (integer enum: `activo=0`, `finalizado=1`, `en_curso=2`, `cancelado=3`)
- `emergency_level` (integer 1–6, nullable)
- `emergency_type` (string)
- `required_skills` (string[], array PostgreSQL)
- `min_score` (float)
- `organization_id` (FK)

**Enum:** `{ activo: 0, finalizado: 1, en_curso: 2, cancelado: 3 }`

**Scopes:**
- `activos` → `where(status: :activo)`
- `en_curso_scope` → `where(status: :en_curso)`
- `vigentes` → `where(status: [:activo, :en_curso])`
- `cancelados` → `where(status: :cancelado)`
- `proximos` → `where("date >= ?", Time.current).order(:date)`

**Callbacks:**
- `after_create_commit :run_matching_if_emergency` → lanza `VolunteerMatchingService` si hay `emergency_level`
- `after_update_commit :broadcast_status_change` → Turbo Stream al cambiar status
- `after_update_commit :notify_volunteers_if_finalizado` → notifica al finalizar

**Métodos de clase:**
- `auto_cancelar_no_iniciados!` → cancela eventos `activo` con `date < 3.days.ago`

**Métodos de instancia:**
- `city_from_location` → `location.split(",")[1]&.strip`
- `country_from_location` → `location.split(",")[0]&.strip`

---

### `Enrollment` — `app/models/enrollment.rb`

**Columnas:**
- `user_id`, `event_id` (FKs)
- `status` (integer enum: `convocado=0`, `confirmado=1`, `asistio=2`, `cancelado=3`)
- `attended_at` (datetime — hora de asistencia marcada)
- `second_wave` (boolean, default: false)
- `expected_arrival` (datetime — solo para segunda ola)
- `score_snapshot` (float — score del voluntario al momento de inscribirse)

**Callbacks:**
- `before_create :snapshot_volunteer_score` → guarda el score actual del voluntario
- `after_create_commit :inscripcion_confirmada` → notifica si status es `confirmado`

---

### `VolunteerProfile` — `app/models/volunteer_profile.rb`

**Columnas:**
- `user_id` (FK)
- `quiz_answers` (jsonb — respuestas q1..q25, escala 0–4)
- `certifications` (jsonb — flags booleanos de certificaciones)
- `score` (float — score global 0–10)
- `skills` (string[] — habilidades activas)
- `skill_scores` (jsonb — score 0–4 por habilidad)
- `available` (boolean)
- `quiz_completed_at` (datetime)
- `country`, `city`, `sector` (string — ubicación del voluntario)

**Constantes importantes:**
- `SKILLS` — array de 5 nombres de habilidades
- `SKILL_LABELS` — hash nombre → etiqueta legible
- `CERTIFICATIONS` — hash key → {label, points}
- `LEVEL_WEIGHTS` — peso de cada habilidad en score global
- `SKILL_IMMEDIATE_THRESHOLD` — umbrales por nivel (0–4 scale)
- `SKILL_SUPPORT_THRESHOLD` — umbrales por nivel (0–4 scale)
- `IMMEDIATE_THRESHOLD` — umbrales globales (0–10 scale, fallback)
- `SUPPORT_THRESHOLD` — umbrales globales (0–10 scale, fallback)
- `ASSUMED_DURATION_HOURS` — duración estimada por nivel (para cruce de tiempos)
- `SECOND_WAVE_DAYS = 7`

**Métodos de cálculo:**
- `calculate_score!` — calcula desde `quiz_answers`, actualiza `score`, `skills`, `skill_scores`, `quiz_completed_at`
- `update_skills_from_reviews!` — recalcula score desde quiz_answers originales + promedio de reviews (incluye zeros); cert bonus proporcional con tope 2.0
- `tier_for_event(event)` → `:immediate`, `:support`, o `nil`
- `call_level_for(emergency_level)` → fallback legacy usando score global
- `busy_in_active_emergency?(exclude_event: nil)` → true si está activo en otra emergencia
- `conflict_resolution_for(new_event)` → `:convoke`, `:convoke_conflict`, `:second_wave`, `:skip`

---

### `EnrollmentReview` — `app/models/enrollment_review.rb`

**Columnas:**
- `enrollment_id`, `reviewer_id` (FKs)
- `primeros_auxilios_score`, `busqueda_rescate_score`, `apoyo_psicosocial_score`, `logistica_abastecimiento_score`, `maquinaria_construccion_score` (integer 0–4 cada uno)
- `comment` (string, max 500)

**Constantes:**
- `SKILL_ATTRS` — array de los 5 nombres de columnas de score
- `SKILL_LABELS` — hash columna → etiqueta legible

**Callbacks:**
- `after_save :update_volunteer_skills` → llama `volunteer_profile.update_skills_from_reviews!`

---

### `Message` — `app/models/message.rb`

**Columnas:** `content`, `user_id`, `event_id`

**Callbacks:**
- `after_create_commit` → `broadcast_append_to [event, :chat]` (Turbo Stream al chat)

---

### `Notification` — `app/models/notification.rb`

**Columnas:** `user_id`, `message`, `read` (boolean), `notifiable_type`, `notifiable_id` (polimórfico)

**Callbacks:**
- `after_create_commit` → broadcast al stream del usuario (badge + lista)

---

## 2. Concerns

### `EcuadorValidations` — `app/models/concerns/ecuador_validations.rb`

Métodos de clase para validar documentos ecuatorianos:
- `cedula_ecuatoriana_valida(cedula)` — algoritmo módulo 10 del Registro Civil
- `ruc_ecuatoriano_valido(ruc)` — 3 variantes según tercer dígito (0–5, 6, 9)

Usados en `User` y `Organization` como validadores custom.

---

## 3. Controladores

### `ApplicationController` — `app/controllers/application_controller.rb`
- Incluye `Pundit::Authorization`
- `rescue_from Pundit::NotAuthorizedError` → redirige a root con alerta

### `HomeController` — `app/controllers/home_controller.rb`
- `index` — carga `@eventos_count`, `@organizaciones_count`, `@voluntarios_count` para la landing

### `EventsController` — `app/controllers/events_controller.rb`

| Action | Ruta | Descripción |
|--------|------|-------------|
| `index` | `GET /events` | Lista eventos (con lógica de tiers para voluntarios) |
| `show` | `GET /events/:id` | Muestra evento (bifurca en 3 vistas según status) |
| `new` | `GET /events/new` | Formulario nuevo evento |
| `create` | `POST /events` | Crea evento; fuerza org del organizador |
| `edit` | `GET /events/:id/edit` | Formulario editar |
| `update` | `PATCH /events/:id` | Actualiza; fuerza org del organizador |
| `destroy` | `DELETE /events/:id` | Elimina |
| `iniciar` | `PATCH /events/:id/iniciar` | Pasa a `en_curso` (solo si `activo`) |
| `finalizar` | `PATCH /events/:id/finalizar` | Pasa a `finalizado` (solo si `en_curso`) |

`before_action :auto_cancelar_expirados` → cancela activos expirados en cada carga.

### `EnrollmentsController` — `app/controllers/enrollments_controller.rb`

| Action | Ruta | Descripción |
|--------|------|-------------|
| `create` | `POST /events/:event_id/enrollments` | Inscribe voluntario |
| `update` | `PATCH /events/:event_id/enrollments/:id` | Confirma inscripción (convocado→confirmado) |
| `destroy` | `DELETE /events/:event_id/enrollments/:id` | Cancela inscripción |
| `mark_attendance` | `PATCH .../enrollments/:id/mark_attendance` | Marca asistencia (org/admin) → `asistio` + `attended_at` |

### `EventReviewsController` — `app/controllers/event_reviews_controller.rb`

| Action | Ruta | Descripción |
|--------|------|-------------|
| `new` | `GET /events/:event_id/reviews/new` | Lista asistentes para calificar (ruta legacy) |
| `create` | `POST /events/:event_id/reviews` | Guarda calificaciones bulk (reviews[enrollment_id][attr]) |

`before_action :authorize_reviewer!` → solo admin o dueño de la organización.

### `QuizController` — `app/controllers/quiz_controller.rb`

| Action | Ruta | Descripción |
|--------|------|-------------|
| `show` | `GET /quiz` | Muestra quiz (formulario si no completado, lectura si ya completado) |
| `update` | `PATCH /quiz` | Guarda respuestas (bloqueado si ya fue completado) |
| `toggle_availability` | `PATCH /quiz/toggle_availability` | Activa/pausa disponibilidad |

### `ProfilesController` — `app/controllers/profiles_controller.rb`

- `show` → `GET /perfil` — carga `@user`, `@profile`, `@participaciones` (con reviews), `@avg_scores`, `@total_reviews`

### `MessagesController` — `app/controllers/messages_controller.rb`

- `create` → `POST /events/:event_id/messages` — crea mensaje de chat

### `NotificationsController` — `app/controllers/notifications_controller.rb`

- `index` → lista notificaciones del usuario
- `mark_as_read` → marca una como leída
- `mark_all_as_read` → marca todas como leídas

### `OrganizationsController` — `app/controllers/organizations_controller.rb`

CRUD estándar para organizaciones. `new`/`create` disponibles para organizadores (crean la suya), `index`/`show` públicos.

### Namespace `Admin::`

| Controlador | Archivo | Descripción |
|-------------|---------|-------------|
| `BaseController` | `admin/base_controller.rb` | `before_action :require_admin!` |
| `DashboardController` | `admin/dashboard_controller.rb` | Panel + acciones destroy + update_user_role |
| `UsersController` | `admin/users_controller.rb` | new/create/edit/update de usuarios |
| `OrganizationsController` | `admin/organizations_controller.rb` | new/create/edit/update de orgs + representante |
| `EventsController` | `admin/events_controller.rb` | new/create de eventos (redirige al dashboard); `available_volunteers` (JSON) |
| `EnrollmentsController` | `admin/enrollments_controller.rb` | new/create con dropdown en cascada |

### `Users::RegistrationsController` — `app/controllers/users/registrations_controller.rb`

Sobreescribe `Devise::RegistrationsController`. Despacha a `create_voluntario` o `create_organizacion` según `params[:registration_type]`. La creación de organización usa `ActiveRecord::Base.transaction`.

---

## 4. Servicios

### `VolunteerMatchingService` — `app/services/volunteer_matching_service.rb`

Convoca voluntarios al crear una emergencia.

```
VolunteerMatchingService.new(event).call
  → candidate_profiles (available=true, quiz completado)
  → para cada perfil:
      tier = profile.tier_for_event(event)
      si tier nil → saltar
      si busy_in_active_emergency?
        → conflict_resolution_for(event) → :convoke | :convoke_conflict | :second_wave | :skip
      si no busy → agregar a listas immediate/support
  → top 20 immediate + top 50 support → crear Enrollments
```

### `EmergencyConflictResolver` — `app/services/emergency_conflict_resolver.rb`

Encapsula la lógica de conflicto. Dado un evento nuevo y un perfil ocupado:
- Genera `Result.new(action:, message:)` con el resultado y el texto de notificación
- Delega al método `VolunteerProfile#conflict_resolution_for`

### `NotificationService` — `app/services/notification_service.rb`

Métodos de clase estáticos:
- `event_finalizado(event)` — notifica a todos los inscritos no cancelados
- `inscripcion_confirmada(enrollment)` — notifica al voluntario
- `voluntario_convocado(enrollment)` — notifica convocatoria estándar
- `convocado_con_conflicto(enrollment, message)` — notifica con mensaje de conflicto
- `segunda_ola(enrollment, message)` — notifica misión internacional

---

## 5. Políticas (Pundit)

### `EventPolicy` — `app/policies/event_policy.rb`

| Método | Regla |
|--------|-------|
| `index?` | Siempre `true` |
| `show?` | Admin ∨ (organizador y evento propio) ∨ (voluntario y evento vigente) |
| `create?` | Admin ∨ organizador |
| `update?` | Admin ∨ (organizador y evento propio) |
| `destroy?` | Admin ∨ (organizador y evento propio) |
| `Scope#resolve` | Admin → todos; Organizador → solo los suyos; Voluntario → `vigentes` |

### `EnrollmentPolicy` — `app/policies/enrollment_policy.rb`

| Método | Regla |
|--------|-------|
| `create?` | Voluntario + evento vigente + quiz completo + tier ≠ nil (si es emergencia) |
| `destroy?` | Voluntario y dueño del enrollment |
| `update?` | Voluntario + dueño + evento activo |
| `mark_attendance?` | (Organizador y dueño de la org) ∨ admin |

### `OrganizationPolicy` — `app/policies/organization_policy.rb`

Lectura pública. Edición solo para admin o el organizador dueño. Creación solo desde registro o por admin.

### `MessagePolicy` — `app/policies/message_policy.rb`

Creación de mensajes solo para participantes del evento (inscritos activos) o admin/organizador del evento.

---

## 6. Vistas

### Layout principal — `app/views/layouts/application.html.erb`
- Navbar: logo, links con estado activo (inline style), campana de notificaciones, avatar → perfil, botón salir
- Flash messages con borde izquierdo de color
- Banner de perfil incompleto para voluntarios sin quiz

### Home — `app/views/home/index.html.erb`
- Hero split: texto + CTAs (izquierda), escala T1–T6 (derecha)
- Stats: eventos activos, organizaciones, voluntarios
- Sección "Cómo funciona" (4 pasos)
- Cards de features (matching, chat, alertas)

### Eventos

| Archivo | Descripción |
|---------|-------------|
| `events/index.html.erb` | Grid de cards con colores por tier; secciones convocados / segunda ola / apoyo |
| `events/show.html.erb` | Router: renderiza partial según `@event.status` |
| `events/_show_activo.html.erb` | Inscripción + chat + panel de voluntarios + botón "Iniciar" + editar/eliminar |
| `events/_show_en_curso.html.erb` | Lista de voluntarios + chat (org/admin) ∨ estado + chat (voluntario) |
| `events/_show_finalizado.html.erb` | Calificación uno a uno con `<details>/<summary>` (org/admin) ∨ score recibido (voluntario) |
| `events/_event_header.html.erb` | Header con banner de emergencia T3+ (color según nivel) + metadata en pills |
| `events/_enrollment_section.html.erb` | Bloque de inscripción con 7 estados distintos |
| `events/_form.html.erb` | Formulario dos columnas: info general + categoría emergencia; org fijada para organizador |
| `events/new.html.erb` | Wrapper `max-w-5xl mx-auto` + link volver |
| `events/edit.html.erb` | Igual a new |
| `events/_message_form.html.erb` | Input de chat |

### Inscripciones

| Archivo | Descripción |
|---------|-------------|
| `enrollments/_enrollment.html.erb` | Card de voluntario en panel de org: avatar, skills, score, badges, botón asistencia |

### Perfil y quiz

| Archivo | Descripción |
|---------|-------------|
| `quiz/show.html.erb` | Formulario 25 preguntas (solo si no completado) ∨ vista lectura con skills y score |
| `profiles/show.html.erb` | Dos columnas: info + score + skills ∨ historial con calificaciones recibidas y snapshot |

### Reviews

| Archivo | Descripción |
|---------|-------------|
| `event_reviews/new.html.erb` | Vista legacy (accesible desde ruta, pero la calificación normal ocurre en `_show_finalizado`) |

### Admin

| Archivo | Descripción |
|---------|-------------|
| `admin/dashboard/index.html.erb` | Stats con íconos + 4 tabs (usuarios/organizaciones/eventos/inscripciones) |
| `admin/users/new.html.erb` | Formulario nuevo usuario |
| `admin/users/edit.html.erb` | Formulario editar usuario |
| `admin/users/_form.html.erb` | Partial: nombres, apellidos, cédula, email, rol, contraseña |
| `admin/organizations/new.html.erb` | Wrapper para _form |
| `admin/organizations/edit.html.erb` | Wrapper para _form |
| `admin/organizations/_form.html.erb` | Org data + representante data en secciones |
| `admin/events/new.html.erb` | Formulario evento (redirige al dashboard al crear) |
| `admin/enrollments/new.html.erb` | Dropdown en cascada: evento → voluntarios disponibles (AJAX) |

### Compartidos

| Archivo | Descripción |
|---------|-------------|
| `shared/_location_select.html.erb` | Selector en cascada país → ciudad → sector con hidden field para location |
| `notifications/_notification.html.erb` | Item de notificación |
| `notifications/index.html.erb` | Lista de notificaciones |
| `messages/_message.html.erb` | Burbuja de chat |

### Devise

| Archivo | Descripción |
|---------|-------------|
| `devise/sessions/new.html.erb` | Login con email + contraseña |
| `devise/registrations/new.html.erb` | Registro dual: pestaña voluntario ∨ pestaña organización |
| `devise/registrations/edit.html.erb` | Editar cuenta + toggle disponibilidad para voluntarios |

---

## 7. Controladores Stimulus

| Controlador | Archivo | Función |
|-------------|---------|---------|
| `address-select` | `address_select_controller.js` | Cascade País→Ciudad→Sector; actualiza hidden field `location` |
| `emergency-level` | `emergency_level_controller.js` | Auto-rellena `min_score` según nivel T1–T6 seleccionado |
| `enrollment-select` | `enrollment_select_controller.js` | En admin/enrollments: carga voluntarios disponibles por AJAX al cambiar evento |
| `tabs` | `tabs_controller.js` | Sistema genérico de pestañas (admin dashboard) |
| `registration-tabs` | `registration_tabs_controller.js` | Pestaña voluntario ∨ organización en el registro |

---

## 8. Rutas principales

```
GET    /                                      home#index
GET    /events                                events#index
GET    /events/:id                            events#show
PATCH  /events/:id/iniciar                    events#iniciar
PATCH  /events/:id/finalizar                  events#finalizar
POST   /events/:event_id/enrollments          enrollments#create
PATCH  .../enrollments/:id                    enrollments#update
DELETE .../enrollments/:id                    enrollments#destroy
PATCH  .../enrollments/:id/mark_attendance    enrollments#mark_attendance
POST   /events/:event_id/messages             messages#create
POST   /events/:event_id/reviews              event_reviews#create
GET    /quiz                                  quiz#show
PATCH  /quiz                                  quiz#update
PATCH  /quiz/toggle_availability              quiz#toggle_availability
GET    /perfil                                profiles#show
GET    /notifications                         notifications#index
GET    /admin/dashboard                       admin/dashboard#index
GET    /admin/users/new                       admin/users#new
GET    /admin/organizations/new               admin/organizations#new
GET    /admin/events/new                      admin/events#new
GET    /admin/enrollments/new                 admin/enrollments#new
GET    /admin/events/:id/available_volunteers admin/events#available_volunteers (JSON)
```

---

## 9. Cálculos y lógica crítica

### Dónde está cada cálculo

| Cálculo | Archivo | Método |
|---------|---------|--------|
| Score desde quiz | `app/models/volunteer_profile.rb` | `calculate_score!` |
| Score desde reviews | `app/models/volunteer_profile.rb` | `update_skills_from_reviews!` |
| Tier del voluntario para un evento | `app/models/volunteer_profile.rb` | `tier_for_event(event)` |
| Disponibilidad en otra emergencia | `app/models/volunteer_profile.rb` | `busy_in_active_emergency?` |
| Resolución de conflicto | `app/models/volunteer_profile.rb` | `conflict_resolution_for(event)` |
| Cruce de tiempos | `app/models/volunteer_profile.rb` | `times_overlap?(a, b)` (privado) |
| Matching completo | `app/services/volunteer_matching_service.rb` | `call` |
| Texto de notificación de conflicto | `app/services/emergency_conflict_resolver.rb` | `resolve` |
| Auto-cancelación de eventos | `app/models/event.rb` | `auto_cancelar_no_iniciados!` |
| Validación cédula | `app/models/concerns/ecuador_validations.rb` | `cedula_ecuatoriana_valida` |
| Validación RUC | `app/models/concerns/ecuador_validations.rb` | `ruc_ecuatoriano_valido` |

### Dónde están los formularios

| Formulario | Archivo |
|------------|---------|
| Crear/editar evento | `app/views/events/_form.html.erb` |
| Quiz de habilidades | `app/views/quiz/show.html.erb` |
| Calificación de voluntarios (uno a uno) | `app/views/events/_show_finalizado.html.erb` |
| Calificación legacy (bulk) | `app/views/event_reviews/new.html.erb` |
| Nuevo usuario (admin) | `app/views/admin/users/_form.html.erb` |
| Nueva organización (admin) | `app/views/admin/organizations/_form.html.erb` |
| Nueva inscripción (admin) | `app/views/admin/enrollments/new.html.erb` |
| Registro voluntario | `app/views/devise/registrations/new.html.erb` |
| Editar cuenta | `app/views/devise/registrations/edit.html.erb` |
| Login | `app/views/devise/sessions/new.html.erb` |
| Selector de ubicación (partial) | `app/views/shared/_location_select.html.erb` |
| Chat (input) | `app/views/events/_message_form.html.erb` |

---

## 10. Migraciones relevantes

| Archivo | Qué agrega |
|---------|------------|
| `*_refactor_enrollments_remove_geo_add_attended_at.rb` | Quita GPS, agrega `attended_at` |
| `*_add_emergency_fields_to_events.rb` | `emergency_level`, `emergency_type`, `required_skills`, `min_score` |
| `*_create_volunteer_profiles.rb` | Tabla `volunteer_profiles` completa |
| `*_add_en_curso_status_to_events.rb` | Enum value `en_curso=2` |
| `*_create_enrollment_reviews.rb` | Tabla `enrollment_reviews` con 5 skill scores + comment |
| `*_add_skill_scores_to_volunteer_profiles.rb` | Columna `skill_scores :jsonb` |
| `*_add_second_wave_fields_to_enrollments.rb` | `second_wave :boolean`, `expected_arrival :datetime` |
| `*_add_cancelado_status_to_events.rb` | Documenta enum value `cancelado=3` |
| `*_add_score_snapshot_to_enrollments.rb` | `score_snapshot :float` |
