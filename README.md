# Plataforma de Coordinación de Voluntariado

Sistema web para la gestión y coordinación de emergencias en tiempo real. Permite a organizaciones publicar emergencias que requieran voluntarios especializados y coordinar la respuesta de forma automática según las habilidades, score y disponibilidad de cada voluntario.

---

## Tabla de contenidos

1. [Flujo general del sistema](#flujo-general-del-sistema)
2. [Tecnologías](#tecnologías)
3. [Instalación](#instalación)
4. [Datos de prueba (seeds)](#datos-de-prueba-seeds)
5. [Deploy](#deploy)
6. [Roles de usuario](#roles-de-usuario)
7. [Modelos y relaciones](#modelos-y-relaciones)
8. [Sistema de convocatoria automática](#sistema-de-convocatoria-automática)
9. [Ciclo de vida de un evento](#ciclo-de-vida-de-un-evento)
10. [Ciclo de vida de una inscripción](#ciclo-de-vida-de-una-inscripción)
11. [Chat en tiempo real](#chat-en-tiempo-real)
12. [Notificaciones en tiempo real](#notificaciones-en-tiempo-real)
13. [Panel de administración](#panel-de-administración)
14. [Rutas principales](#rutas-principales)
15. [Servicios](#servicios)
16. [Políticas de autorización (Pundit)](#políticas-de-autorización-pundit)
17. [Controladores Stimulus](#controladores-stimulus)
18. [Validaciones ecuatorianas](#validaciones-ecuatorianas)
19. [Arquitectura y diseño](#arquitectura-y-diseño)

---

## Flujo general del sistema

1. Una **organización** se registra con su RUC y datos de un representante (rol `organizador`).
2. El organizador crea **eventos o emergencias** (T1–T6) con fecha, ubicación, nivel de emergencia y habilidades requeridas.
3. Al crear una emergencia, el sistema lanza automáticamente la **convocatoria por matching** — selecciona los voluntarios más capacitados y les envía notificación inmediata.
4. Los **voluntarios** reciben la convocatoria, confirman asistencia y se comunican con la organización por el **chat en tiempo real**.
5. El día del evento, el organizador lo **inicia manualmente** y toma lista de asistencia.
6. Al finalizar, califica a cada voluntario en las 5 habilidades. Esas calificaciones **actualizan el score** del voluntario para futuras convocatorias.
7. El **administrador** gestiona usuarios, organizaciones, eventos e inscripciones desde un panel dedicado.

---

## Tecnologías

| Categoría | Tecnología |
|---|---|
| Framework | Ruby on Rails 8.1 |
| Lenguaje | Ruby 3.2 |
| Base de datos | PostgreSQL |
| Autenticación | Devise ~5.0 |
| Autorización | Pundit |
| Frontend reactivo | Hotwire (Turbo + Stimulus) |
| WebSockets | Action Cable + Solid Cable |
| CSS | Tailwind CSS v4 |
| Asset pipeline | Propshaft + importmap-rails |
| Background jobs | Solid Queue |
| Cache | Solid Cache |
| Servidor | Puma |

---

## Instalación

**Requisitos previos:** Ruby 3.2+ y PostgreSQL 14+

```bash
git clone <repo>
cd voluntariado_app

bundle install

bin/rails db:create db:migrate db:seed

bin/rails server
```

En otra terminal (para compilar Tailwind en modo watch):

```bash
bin/rails tailwindcss:watch
```

---

## Datos de prueba (seeds)

El comando `db:seed` crea un conjunto de datos de demostración:

| Rol | Email | Contraseña |
|---|---|---|
| **Admin** | `admin@voluntariado.ec` | `123456` |
| Organizador (Cruz Roja) | `karla@cruzroja.ec` | `123456` |
| Organizador (Hogar de Cristo) | `diego@hogar.ec` | `123456` |
| Voluntario | `ana@mail.ec` | `123456` |
| Voluntario | `luis@mail.ec` | `123456` |
| + 8 voluntarios adicionales con perfiles completos |

Incluye 2 organizaciones, 5 eventos (3 emergencias T2/T4/T6 + 2 normales) y voluntarios con perfiles de habilidades completos para demostrar el matching.

---

## Deploy

> **URL de producción:** _(pendiente de configurar)_

Variables de entorno requeridas:

- `DATABASE_URL` — cadena de conexión PostgreSQL
- `SECRET_KEY_BASE` — generada con `bin/rails secret`
- `RAILS_ENV=production`

---

## Roles de usuario

| Rol | Enum | Descripción |
|---|---|---|
| `admin` | 0 | Acceso total — panel de administración completo |
| `organizador` | 1 | Representa una organización — crea y gestiona eventos |
| `voluntario` | 2 | Se inscribe en eventos — recibe convocatorias automáticas (rol por defecto) |

---

## Modelos y relaciones

```
User ──has_one──► VolunteerProfile
User ──has_one──► Organization (como representante)
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

### Columnas clave por modelo

**`User`**
- `email`, `encrypted_password` — Devise
- `nombres`, `apellidos` (componen el virtual `name`)
- `cedula` — 10 dígitos, validada para voluntarios
- `role` — enum `admin=0`, `organizador=1`, `voluntario=2`

**`Event`**
- `title`, `description`, `date`, `location`
- `status` — enum `activo=0`, `finalizado=1`, `en_curso=2`, `cancelado=3`
- `emergency_level` — integer 1–6 (nullable; nil = evento normal)
- `required_skills` — `string[]` PostgreSQL
- `organization_id`

**`Enrollment`**
- `status` — enum `convocado=0`, `confirmado=1`, `asistio=2`, `cancelado=3`
- `second_wave` — boolean (segunda ola internacional)
- `expected_arrival` — datetime (solo segunda ola)
- `score_snapshot` — float (score del voluntario al momento de inscribirse)
- `attended_at` — datetime (hora de asistencia marcada)

**`VolunteerProfile`**
- `quiz_answers` — jsonb (respuestas q1..q25, escala 0–4)
- `certifications` — jsonb (flags booleanos)
- `score` — float 0–10
- `skills` — `string[]` (habilidades activas)
- `skill_scores` — jsonb (score 0–4 por habilidad)
- `available` — boolean
- `quiz_completed_at` — datetime
- `country`, `city`, `sector`

**`EnrollmentReview`**
- `primeros_auxilios_score`, `busqueda_rescate_score`, `apoyo_psicosocial_score`, `logistica_abastecimiento_score`, `maquinaria_construccion_score` — integer 0–4
- `comment` — string max 500

---

## Sistema de convocatoria automática

### Calificación del voluntario

#### Cuestionario inicial (único e irrepetible)

Cada voluntario completa **una sola vez** un cuestionario de 25 preguntas divididas en 5 secciones. Una vez enviado se bloquea — el score evoluciona solo a través del historial real de participación.

Escala de respuesta (0–4):

| Valor | Significado |
|-------|-------------|
| 0 | Nunca / Sin experiencia |
| 1 | Algo / Conocimiento básico |
| 2 | Con práctica / Competente |
| 3 | Con experiencia / Avanzado |
| 4 | Experto / Formación formal |

#### Secciones y pesos en el score global

| Sección | Preguntas | Peso |
|---------|-----------|------|
| Primeros Auxilios | q1–q5 | 1.2 |
| Búsqueda y Rescate | q6–q10 | **1.5** (mayor peso) |
| Apoyo Psicosocial | q11–q15 | 0.8 |
| Logística y Abastecimiento | q16–q20 | 0.9 |
| Maquinaria / Construcción | q21–q25 | 1.3 |

#### Fórmula del score inicial

```
score_habilidad = (suma de las 5 respuestas / 20) × 4         # escala 0–4
base_score      = (Σ (score_habilidad/4 × peso) / Σ pesos) × 10
score_final     = min(base_score + cert_bonus, 10.0)
```

Una habilidad queda **activa** si `score_habilidad ≥ 1.0`.

#### Bonus por certificaciones (al completar el quiz)

| Certificación | Puntos |
|---------------|--------|
| Primeros Auxilios (Cruz Roja / Defensa Civil) | +1.0 |
| Rescate en espacios confinados o altura | +1.5 |
| Primeros Auxilios Psicológicos (PAP) | +1.0 |
| Licencia de conducción tipo C o D | +0.5 |
| Operador de maquinaria pesada certificado | +2.0 |
| Técnico o ingeniero civil / construcción | +1.5 |
| Técnico en enfermería o paramédico | +2.0 |
| Bombero voluntario formado | +2.0 |

#### Evolución del score con reviews (40% quiz + 60% campo)

Cada vez que un organizador califica a un voluntario, el sistema recalcula su score:

1. Recalcula `quiz_raw` desde las respuestas originales del quiz (nunca desde valores almacenados — evita compounding).
2. Promedia **todas** las calificaciones recibidas, incluyendo ceros (`0 = "No aplicó"` es un dato real).
3. Mezcla por habilidad: `merged = quiz_raw × 0.4 + review_avg × 0.6`
4. Score global con la misma fórmula ponderada × 10.
5. Bonus de certificaciones proporcional con **tope de 2.0 puntos** — evita que acumular certs lleve el score a 10 independientemente del desempeño real en campo.

```
score_final = min(score_ponderado + cert_bonus_proporcional, 10.0)
```

#### Snapshot del score en cada inscripción

Al inscribirse o ser convocado, se guarda `enrollment.score_snapshot` con el score de ese instante, permitiendo mostrar la evolución antes/después de la calificación.

---

### Proceso de convocatoria automática

#### Disparador

`Event` tiene `after_create_commit :run_matching_if_emergency`. Se ejecuta **síncronamente** al crear un evento con `emergency_level` presente. No se vuelve a ejecutar al editar el evento.

#### Pool de candidatos

`VolunteerMatchingService` filtra perfiles con `available: true` y `quiz_completed_at` no nulo. No hay filtro geográfico — cualquier voluntario del mundo puede ser convocado (la geografía solo importa al resolver conflictos).

#### Clasificación por tier

Para cada candidato se evalúa `VolunteerProfile#tier_for_event(event)`:

**Si el evento tiene `required_skills`** — se comparan los `skill_scores` del voluntario:

| Nivel | Inmediato (score habilidad ≥) | Apoyo (score habilidad ≥) |
|-------|:---:|:---:|
| T1 — Leve | 1.5 | 0.5 |
| T2 — Moderada | 2.0 | 1.0 |
| T3 — Media | 2.5 | 1.5 |
| T4 — Alta | 3.0 | 2.0 |
| T5 — Crítica | 3.2 | 2.5 |
| T6 — Catástrofe | 3.5 | 3.0 |

- `:immediate` → **TODAS** las habilidades requeridas superan el umbral inmediato
- `:support` → **AL MENOS UNA** habilidad requerida supera el umbral de apoyo
- `nil` → ninguna alcanza el mínimo → excluido

**Si el evento no tiene `required_skills` (fallback)** — se compara el score global:

| Nivel | Inmediato (score global ≥) | Apoyo (score global ≥) |
|-------|:---:|:---:|
| T1 | 4.0 | 2.0 |
| T2 | 5.0 | 3.0 |
| T3 | 5.5 | 4.0 |
| T4 | 6.5 | 5.0 |
| T5 | 7.0 | 6.0 |
| T6 | 8.0 | 7.0 |

#### Resolución de conflictos (voluntario ya activo en otra emergencia)

Se ejecutan 3 comparaciones en orden:

**1 — País:**
- País del voluntario ≠ país del nuevo evento → `:second_wave`
- Se crea enrollment con `second_wave: true`, `expected_arrival: 7.days.from_now`

**2 — Cruce de tiempos** (usando duraciones estimadas por nivel):

| Nivel | Duración estimada |
|-------|:-----------------:|
| T1 | 4 h |
| T2 | 6 h |
| T3 | 12 h |
| T4 | 24 h |
| T5 | 48 h |
| T6 | 72 h |

- Sin cruce temporal → `:convoke` (puede atender ambas)
- Con cruce → pasa a la comparación 3

**3 — Prioridad por nivel:**

| Diferencia de nivel | Resultado |
|--------------------|-----------|
| Nueva ≥ 2 niveles mayor | `:convoke_conflict` — se convoca con notificación de conflicto |
| Nueva 1 nivel mayor | `:convoke_conflict` |
| Igual o menor | `:skip` — no se convoca |

#### Inscripciones generadas por el matching

```
Top 20 :immediate (por score descendente) → Enrollment(status: convocado)
Top 50 :support   (por score descendente) → Enrollment(status: convocado)
Segunda ola                               → Enrollment(status: convocado, second_wave: true)
Conflict                                  → Enrollment(status: convocado) + notificación especial
```

#### Visibilidad del tier en la lista de eventos

| Estado | Badge | Acción |
|--------|-------|--------|
| Ya convocado / confirmado | 🚨 Ya convocado | Ver evento |
| Tier `:immediate` | ✓ Podés inscribirte | Inscripción directa |
| Tier `:support` | 🤝 Podés dar apoyo | Inscripción como apoyo |
| Tier `nil` (fuera de rango) | Sin nivel requerido | Solo lectura |
| Evento normal (sin emergencia) | — | Inscripción libre |

---

## Ciclo de vida de un evento

```
activo
  │
  ├──[organizador → "Iniciar"]──► en_curso
  │                                   │
  │                                   ├──[organizador → "Finalizar"]──► finalizado
  │                                   │                                      │
  │                                   │                           [calificación voluntarios]
  │
  └──[3 días sin iniciar]──► cancelado (automático, sin impacto en scores)
```

| Estado | Descripción |
|--------|-------------|
| `activo` | Convocando — acepta inscripciones y matching automático |
| `en_curso` | El organizador inició el evento — toma lista de asistencia |
| `finalizado` | Evento terminado — habilita calificación de asistentes |
| `cancelado` | Nunca se inició — sin impacto en ningún voluntario |

La auto-cancelación se ejecuta en cada carga de `events#index` y `events#show` mediante `Event.auto_cancelar_no_iniciados!`.

---

## Ciclo de vida de una inscripción

```
convocado → [voluntario confirma] → confirmado
confirmado → [organizador marca asistencia] → asistio
asistio → [organizador califica] → EnrollmentReview guardado → score recalculado
```

Solo voluntarios con status `asistio` aparecen en el formulario de calificación.

---

## Chat en tiempo real

Cada evento tiene un canal de chat exclusivo para participantes. Usa Turbo Streams con Action Cable (Solid Cable como broker, sin Redis).

```
POST /events/:event_id/messages → MessagesController#create
→ Message#after_create_commit → broadcast_append_to [event, :chat]
→ todos los navegadores suscritos reciben el mensaje instantáneamente
```

---

## Notificaciones en tiempo real

Las notificaciones son persistentes (`notifications` table) y se entregan vía Turbo Streams al navbar de cada usuario.

| Trigger | Destinatario | Método |
|---------|-------------|--------|
| Voluntario convocado a emergencia | El voluntario | `NotificationService.voluntario_convocado` |
| Convocado con conflicto de prioridad | El voluntario (con contexto) | `NotificationService.convocado_con_conflicto` |
| Segunda ola (otro país) | El voluntario (con fecha estimada) | `NotificationService.segunda_ola` |
| Evento finalizado | Todos los inscritos no cancelados | `NotificationService.event_finalizado` |
| Inscripción confirmada | El voluntario | `NotificationService.inscripcion_confirmada` |

---

## Panel de administración

`/admin/dashboard` — solo para `admin`.

Cuatro pestañas:
- **Usuarios** — CRUD completo con cambio de rol inline
- **Organizaciones** — crea/edita org + representante en un solo formulario transaccional
- **Eventos** — lista con estado, organización e inscritos; crear desde contexto admin redirige al dashboard
- **Inscripciones** — lista con estado, asistencia y eliminación

---

## Rutas principales

```
GET    /                                       home#index
GET    /events                                 events#index
GET    /events/:id                             events#show
POST   /events                                 events#create
PATCH  /events/:id                             events#update
DELETE /events/:id                             events#destroy
PATCH  /events/:id/iniciar                     events#iniciar
PATCH  /events/:id/finalizar                   events#finalizar
POST   /events/:event_id/enrollments           enrollments#create
PATCH  /events/:event_id/enrollments/:id       enrollments#update
DELETE /events/:event_id/enrollments/:id       enrollments#destroy
PATCH  .../enrollments/:id/mark_attendance     enrollments#mark_attendance
POST   /events/:event_id/messages              messages#create
POST   /events/:event_id/reviews               event_reviews#create
GET    /quiz                                   quiz#show
PATCH  /quiz                                   quiz#update
PATCH  /quiz/toggle_availability               quiz#toggle_availability
GET    /perfil                                 profiles#show
GET    /notifications                          notifications#index
PATCH  /notifications/:id/mark_as_read         notifications#mark_as_read
PATCH  /notifications/mark_all_as_read         notifications#mark_all_as_read
GET    /organizations                          organizations#index
GET    /organizations/:id                      organizations#show
GET    /admin/dashboard                        admin/dashboard#index
GET    /admin/users/new                        admin/users#new
GET    /admin/users/:id/edit                   admin/users#edit
GET    /admin/organizations/new                admin/organizations#new
GET    /admin/events/new                       admin/events#new
GET    /admin/enrollments/new                  admin/enrollments#new
GET    /admin/events/:id/available_volunteers  admin/events#available_volunteers (JSON)
```

---

## Servicios

### `VolunteerMatchingService` — `app/services/volunteer_matching_service.rb`

Orquesta la convocatoria automática al crear una emergencia.

```ruby
VolunteerMatchingService.new(event).call
  # → candidate_profiles (available=true, quiz completado)
  # → para cada perfil: tier_for_event → :immediate / :support / nil
  # → si busy_in_active_emergency? → EmergencyConflictResolver
  # → Top 20 immediate + Top 50 support → crear Enrollments
```

### `EmergencyConflictResolver` — `app/services/emergency_conflict_resolver.rb`

Encapsula la lógica de conflicto. Recibe el nuevo evento y el perfil ocupado; devuelve un `Result` (Value Object):

```ruby
Result = Struct.new(:action, :message, keyword_init: true)
# action: :convoke | :convoke_conflict | :second_wave | :skip
```

### `NotificationService` — `app/services/notification_service.rb`

Fachada estática para creación de notificaciones. Todos los métodos públicos delegan a un método privado `create_for` que ejecuta el `Notification.create!`:

```ruby
NotificationService.event_finalizado(event)
NotificationService.inscripcion_confirmada(enrollment)
NotificationService.voluntario_convocado(enrollment)
NotificationService.convocado_con_conflicto(enrollment, message)
NotificationService.segunda_ola(enrollment, message)
```

---

## Políticas de autorización (Pundit)

### `EventPolicy`

| Acción | Regla |
|--------|-------|
| `index?` | Siempre `true` |
| `show?` | Admin ∨ (organizador y evento propio) ∨ (voluntario y evento vigente) |
| `create?` | Admin ∨ organizador |
| `update?` / `destroy?` | Admin ∨ (organizador y evento propio) |
| `Scope#resolve` | Admin → todos; Organizador → solo los suyos; Voluntario → `vigentes` |

### `EnrollmentPolicy`

| Acción | Regla |
|--------|-------|
| `create?` | Voluntario + evento vigente + quiz completo + tier ≠ nil si es emergencia |
| `destroy?` | Voluntario y dueño del enrollment |
| `update?` | Voluntario + dueño + evento activo |
| `mark_attendance?` | (Organizador y dueño de la org) ∨ admin |

### `OrganizationPolicy`

Lectura pública. Edición para admin o el organizador dueño. Creación solo por admin o al registrarse.

### `MessagePolicy`

`create?` = `true` para cualquier usuario autenticado participante del evento.

---

## Controladores Stimulus

| Controlador | Archivo | Función |
|-------------|---------|---------|
| `address-select` | `address_select_controller.js` | Cascade País→Ciudad→Sector; actualiza hidden field `location` |
| `emergency-level` | `emergency_level_controller.js` | Auto-rellena `min_score` según nivel T1–T6 seleccionado |
| `enrollment-select` | `enrollment_select_controller.js` | En admin: carga voluntarios disponibles por AJAX al cambiar evento |
| `tabs` | `tabs_controller.js` | Sistema genérico de pestañas (admin dashboard) |
| `registration-tabs` | `registration_tabs_controller.js` | Pestaña voluntario ∨ organización en el registro |

---

## Validaciones ecuatorianas

El módulo `EcuadorValidations` (`app/models/concerns/ecuador_validations.rb`) implementa algoritmos de validación de documentos oficiales:

**Cédula (`cedula_valida?`):**
- 10 dígitos, provincia 01–24, tercer dígito < 6
- Checksum módulo 10 del Registro Civil ecuatoriano

**RUC (`ruc_valido?`):**
- 13 dígitos, provincia 01–24
- Tres variantes según tercer dígito:
  - `0–5` → Persona natural (primeros 10 dígitos = cédula válida + `001`)
  - `6` → Entidad pública
  - `9` → Sociedad privada/extranjera

---

## Arquitectura y diseño

### Patrones de diseño aplicados

| Patrón | Implementación |
|--------|---------------|
| **Observer** | Callbacks de ActiveRecord + Turbo Streams en `Event`, `Enrollment`, `Notification`, `Message` — notifican automáticamente al cambiar estado |
| **Service Object** | `VolunteerMatchingService`, `NotificationService`, `EmergencyConflictResolver` — lógica de negocio compleja fuera de modelos y controladores |
| **Strategy** | Pundit policies — cada recurso tiene su propia política de autorización intercambiable desde `ApplicationPolicy` |
| **Value Object** | `EmergencyConflictResolver::Result` (Struct inmutable) — transporta resultado de resolución sin estado mutable |
| **Facade** | `NotificationService` — interfaz unificada y simple que oculta los detalles de `Notification.create!` |
| **Template Method** | `ApplicationPolicy` define la estructura (`index?`, `show?`, ...); las subpolicies implementan el comportamiento específico |
| **Query Scope** | Named scopes en `Event` (`vigentes`, `proximos`, `activos`) y `Notification` (`unread`, `recent`) — encapsulan consultas reutilizables |

### Principios SOLID

| Principio | Aplicación |
|-----------|-----------|
| **S** — Responsabilidad única | La lógica de matching está en `VolunteerMatchingService`; la de conflictos en `EmergencyConflictResolver`; la de autorización en las Pundit policies; los controladores solo coordinan el flujo HTTP |
| **O** — Abierto/Cerrado | Nuevos tipos de evento o política de autorización se agregan sin modificar código existente |
| **L** — Sustitución de Liskov | `Admin::BaseController`, las subpolicies y `Users::RegistrationsController` extienden sus bases sin romper su contrato |
| **I** — Segregación de interfaces | Cada Pundit policy cubre solo el recurso que le corresponde; ningún controlador depende de métodos de política que no usa |
| **D** — Inversión de dependencias | Los servicios dependen de abstracciones (modelos ActiveRecord), no de implementaciones concretas de persistencia |

### Estructura de directorios clave

```
app/
├── controllers/
│   ├── admin/                        # Namespace admin (BaseController + CRUD)
│   ├── users/registrations_controller.rb
│   ├── events_controller.rb
│   ├── enrollments_controller.rb
│   ├── event_reviews_controller.rb
│   ├── quiz_controller.rb
│   ├── profiles_controller.rb
│   ├── messages_controller.rb
│   └── notifications_controller.rb
├── models/
│   ├── concerns/ecuador_validations.rb
│   ├── user.rb
│   ├── organization.rb
│   ├── event.rb
│   ├── enrollment.rb
│   ├── enrollment_review.rb
│   ├── volunteer_profile.rb
│   ├── notification.rb
│   └── message.rb
├── services/
│   ├── volunteer_matching_service.rb  # Orquesta la convocatoria automática
│   ├── notification_service.rb        # Fachada para creación de notificaciones
│   └── emergency_conflict_resolver.rb # Resuelve conflictos entre emergencias
└── policies/
    ├── application_policy.rb
    ├── event_policy.rb
    ├── enrollment_policy.rb
    ├── organization_policy.rb
    └── message_policy.rb
```

### Dónde está cada cálculo crítico

| Cálculo | Archivo | Método |
|---------|---------|--------|
| Score desde quiz | `app/models/volunteer_profile.rb` | `calculate_score!` |
| Score desde reviews | `app/models/volunteer_profile.rb` | `update_skills_from_reviews!` |
| Tier del voluntario para un evento | `app/models/volunteer_profile.rb` | `tier_for_event(event)` |
| Disponibilidad en otra emergencia | `app/models/volunteer_profile.rb` | `busy_in_active_emergency?` |
| Resolución de conflicto | `app/models/volunteer_profile.rb` | `conflict_resolution_for(event)` |
| Cruce de tiempos | `app/models/volunteer_profile.rb` | `times_overlap?(a, b)` (privado) |
| Matching completo | `app/services/volunteer_matching_service.rb` | `call` |
| Mensaje de notificación de conflicto | `app/services/emergency_conflict_resolver.rb` | `resolve` |
| Auto-cancelación de eventos | `app/models/event.rb` | `auto_cancelar_no_iniciados!` |
| Validación cédula | `app/models/concerns/ecuador_validations.rb` | `cedula_valida?` |
| Validación RUC | `app/models/concerns/ecuador_validations.rb` | `ruc_valido?` |

---

## Documentación técnica adicional

- [`SISTEMA_CONVOCATORIA.md`](SISTEMA_CONVOCATORIA.md) — scoring, matching, resolución de conflictos, tablas de umbrales completas
- [`ARQUITECTURA.md`](ARQUITECTURA.md) — mapa detallado de modelos, controladores, vistas, rutas, servicios y políticas con referencias a líneas de código
- [`CORE_CONVOCATORIA.md`](CORE_CONVOCATORIA.md) — flujo técnico completo fase por fase con diagrama y tabla de archivos/líneas
- [`mejoras.md`](mejoras.md) — registro del refactoring: qué se cambió, qué se mantuvo, por qué, patrones identificados, análisis SOLID y deuda técnica pendiente
