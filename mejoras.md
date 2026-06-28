# Mejoras aplicadas al proyecto

Análisis y refactoring de la plataforma de coordinación de voluntariado. Este documento registra qué se cambió, dónde, por qué, y qué se mantuvo deliberadamente sin tocar.

---

## Cambios aplicados

### 1. Número mágico eliminado — `Event#auto_cancelar_no_iniciados!`
**Archivo:** `app/models/event.rb` — método `auto_cancelar_no_iniciados!`

**Problema:** `update_all(status: 3) # 3 = cancelado` usaba un entero literal. Si el orden del enum cambia, el número silenciosamente apunta al estado equivocado.

**Principio:** Clean Code — sin números mágicos; el código debe ser autoexplicativo.

**Cambio:**
```ruby
# Antes
.update_all(status: 3)  # 3 = cancelado

# Después
.update_all(status: statuses[:cancelado])
```
`statuses[:cancelado]` lee el valor desde el enum de Rails, que es la fuente de verdad. Se eliminó el comentario porque ya no hace falta.

---

### 2. DRY — Constante `SECTION_MAP` extraída en `VolunteerProfile`
**Archivo:** `app/models/volunteer_profile.rb`

**Problema:** El mismo hash que mapea habilidades a preguntas del quiz estaba definido literalmente en dos métodos distintos del mismo modelo: `calculate_score!` (línea ~59) y `update_skills_from_reviews!` (línea ~115). Si se agrega o renombra una sección, hay que actualizar dos lugares.

**Principio:** DRY (Don't Repeat Yourself) — una sola fuente de verdad para cada pieza de conocimiento.

**Cambio:** Se extrajo el hash a la constante de clase `SECTION_MAP` y ambos métodos ahora la referencian.

```ruby
# Antes: hash definido dos veces, una por método
section_map = {
  "primeros_auxilios" => %w[q1 q2 q3 q4 q5],
  ...
}

# Después: constante de clase, definida una vez
SECTION_MAP = {
  "primeros_auxilios" => %w[q1 q2 q3 q4 q5],
  ...
}.freeze
```

---

### 3. DRY — Métodos duplicados en `NotificationService`
**Archivo:** `app/services/notification_service.rb`

**Problema:** `convocado_con_conflicto` y `segunda_ola` tenían implementaciones idénticas: ambos simplemente llamaban a `Notification.create!` con los mismos parámetros. Toda la diferencia semántica estaba en el nombre del método y en el mensaje que recibían por parámetro.

**Principio:** DRY — no repetir fragmentos de código idénticos.
**Patrón:** Facade — `NotificationService` sigue siendo una fachada simple, pero ahora su implementación interna también es limpia.

**Cambio:** Se extrajo un método privado de clase `create_for` que ejecuta la creación. Los métodos públicos conservan sus nombres (la semántica del negocio importa para quien los llama), pero delegan al método privado compartido. Se aprovechó también para simplificar `event_finalizado`, `inscripcion_confirmada` y `voluntario_convocado` con la misma utilidad.

```ruby
# Antes: implementación duplicada
def self.convocado_con_conflicto(enrollment, message)
  Notification.create!(user: enrollment.user, notifiable: enrollment, message: message)
end

def self.segunda_ola(enrollment, message)
  Notification.create!(user: enrollment.user, notifiable: enrollment, message: message)
end

# Después: implementación compartida, interfaz pública sin cambios
def self.convocado_con_conflicto(enrollment, message) = create_for(enrollment, message)
def self.segunda_ola(enrollment, message)             = create_for(enrollment, message)

private_class_method def self.create_for(enrollment, message, notifiable: enrollment)
  Notification.create!(user: enrollment.user, notifiable: notifiable, message: message)
end
```

---

### 4. DRY — `user_params` unificado en `Admin::UsersController`
**Archivo:** `app/controllers/admin/users_controller.rb`

**Problema:** `user_create_params` y `user_update_params` eran métodos privados con implementaciones byte-por-byte idénticas. Cualquier cambio en los atributos permitidos requería actualizarlo en dos lugares.

**Principio:** DRY.

**Cambio:** Se fusionaron en un único método `user_params`. En el método `update`, la línea que elimina la contraseña cuando viene vacía se simplificó a una sola expresión.

```ruby
# Antes: dos métodos idénticos
def user_create_params = params.require(:user).permit(:nombres, ...)
def user_update_params = params.require(:user).permit(:nombres, ...)

# Después: un solo método
def user_params = params.require(:user).permit(:nombres, ...)
```

---

### 5. DRY — `user_registration_params` unificado en `Users::RegistrationsController`
**Archivo:** `app/controllers/users/registrations_controller.rb`

**Problema:** `voluntario_params` y `representante_params` eran idénticos. El mismo conjunto de atributos se describía dos veces.

**Principio:** DRY.

**Cambio:** Se definió `user_registration_params` como método base y se crearon alias con los nombres semánticos originales para no perder claridad en los métodos que los llaman.

```ruby
def user_registration_params
  params.require(:user).permit(:email, :password, :password_confirmation,
                               :nombres, :apellidos, :cedula)
end
alias_method :voluntario_params,    :user_registration_params
alias_method :representante_params, :user_registration_params
```

---

### 6. SRP — Extracción de `load_volunteer_event_data` en `EventsController#index`
**Archivo:** `app/controllers/events_controller.rb`

**Problema:** La acción `index` tenía dos responsabilidades mezcladas: (1) cargar y autorizar la lista de eventos, y (2) calcular tres conjuntos adicionales de datos específicos para voluntarios con perfil completo. El método era largo y difícil de leer a primera vista.

**Principio:** SRP (Single Responsibility Principle) — cada método debe tener una sola razón para cambiar.

**Cambio:** El bloque de voluntario se extrajo al método privado `load_volunteer_event_data`. El `index` ahora es una sola línea condicional.

```ruby
# Antes: index con 15 líneas mezcladas
def index
  @events = policy_scope(Event)
  authorize Event
  if current_user&.voluntario? && current_user.profile_complete?
    profile = current_user.volunteer_profile
    convocado_enrollments = ...
    @convocados  = ...
    @segunda_ola = ...
    @disponibles = ...
  end
end

# Después: índice limpio, lógica encapsulada
def index
  @events = policy_scope(Event)
  authorize Event
  load_volunteer_event_data if current_user&.voluntario? && current_user.profile_complete?
end
```

---

### 7. Concern innecesario eliminado — `EcuadorValidations`
**Archivo:** `app/models/concerns/ecuador_validations.rb`

**Problema:** El módulo usaba `extend ActiveSupport::Concern` pero nunca aprovechaba ninguna de sus características (`included do ... end`, `class_methods do ... end`, hooks de inclusión). El módulo solo contiene métodos de clase puros (`def self.cedula_valida?`, `def self.ruc_valido?`) y se llama directamente como `EcuadorValidations.cedula_valida?(cedula)`, sin ser incluido en ningún modelo.

**Principio:** Simplicity — no usar infraestructura que no se necesita. Agregar `extend ActiveSupport::Concern` a un módulo sin usarlo es ruido que confunde al lector haciéndole pensar que hay mixins en juego.

**Cambio:** Se eliminó la línea `extend ActiveSupport::Concern`. El módulo sigue funcionando exactamente igual.

---

## Código mantenido y por qué

### Nombres en español (métodos, variables, enums)
Los nombres `activo`, `finalizado`, `en_curso`, `cancelado`, `convocado`, `asistio`, `cedula_ecuatoriana_valida`, `auto_cancelar_no_iniciados!`, etc., están en español porque el dominio del sistema es Ecuador y la nomenclatura mapea directamente a términos legales y operativos locales. Cambiarlos a inglés requeriría migrar rutas, vistas, seeds, y romper la legibilidad del dominio. Se reconoce como deuda técnica según los estándares de la industria, pero no se toca en esta pasada por el riesgo de regresión.

### `VolunteerProfile` como clase con múltiples responsabilidades
El modelo contiene cálculo de score, cálculo de tier, resolución de conflictos (delegada) y constantes de umbrales. En un sistema más grande, cada responsabilidad podría ir a un servicio (`ScoreCalculator`, `TierEvaluator`). Se mantuvo así porque:
- Los métodos privados (`skill_tier_for`, `global_tier_for`, `times_overlap?`) solo tienen sentido en contexto del perfil.
- Las constantes (`IMMEDIATE_THRESHOLD`, `SKILL_IMMEDIATE_THRESHOLD`, etc.) son datos del dominio, no lógica de negocio separable.
- Extraer servicios en este punto añadiría indirección sin simplificar el código.

### `EmergencyConflictResolver::Result` (Struct)
Se mantiene. Es el patrón **Value Object** aplicado correctamente: un objeto inmutable que transporta datos de resultado sin estado mutable. La llamada `Result.new(action: ..., message: ...)` es más expresiva que retornar un array o hash crudo.

### Callbacks de ActiveRecord (`after_create_commit`, `after_update_commit`)
Los modelos `Event`, `Enrollment`, `Notification` y `Message` usan callbacks para broadcasts de Turbo y notificaciones. Se mantienen porque es el patrón **Observer** estándar de Rails/Hotwire — mover esas llamadas a los controladores no simplificaría nada y rompería la separación de concerns.

### Pundit policies
Las políticas de autorización (`EventPolicy`, `EnrollmentPolicy`, `OrganizationPolicy`, `MessagePolicy`) son correctas e implementan el patrón **Strategy**: cada política encapsula las reglas de autorización de un recurso de forma intercambiable. La base `ApplicationPolicy` aplica el principio **ISP** (Interface Segregation): define la interfaz mínima y cada política solo implementa lo que necesita.

### `Admin::BaseController` con herencia
`Admin::BaseController < ApplicationController` y luego `Admin::EventsController < Admin::BaseController` es la aplicación del principio **LSP** (Liskov Substitution): los controladores admin pueden sustituir al ApplicationController sin romper el comportamiento base (autenticación, Pundit), y agregan la capa de autorización por rol sin modificar la base.

### Duplicación de `event_params` entre `EventsController` y `Admin::EventsController`
Se reconoce como duplicación, pero se decidió mantenerla porque:
- Los dos contextos (público y admin) evolucionan de forma independiente.
- Compartirlos mediante un concern requeriría un módulo con lógica de parámetros, lo que sería una abstracción prematura para dos métodos idénticos hoy pero que pueden divergir mañana.
- En Rails, duplicar un método params en dos controllers es convención aceptada.

### Comentarios de fórmulas en `VolunteerProfile`
Los bloques `### formula de calculo de score` y las secciones con guiones `# ─────────────────────` se mantienen porque documentan decisiones matemáticas no triviales (ponderación de habilidades, mezcla 40/60 quiz/reviews). El "por qué" de esas fórmulas no es evidente del código. Nota: el triple `###` no es sintaxis estándar de Ruby (lo correcto es `#`) — se registra como deuda de limpieza menor.

### `badge_html` en `Notification`
El método genera HTML directamente en el modelo para el broadcast de Turbo. Es un acoplamiento de vista/modelo que viola SRP, pero en el contexto de Turbo Streams (donde el servidor emite fragmentos HTML) es el patrón estándar de Rails. Moverlo a un helper o partial requeriría un `render` desde el modelo, que es igual o más acoplado.

---

## Patrones de diseño identificados (existentes)

| Patrón | Dónde | Descripción |
|--------|-------|-------------|
| **Observer** | `Event`, `Enrollment`, `Notification`, `Message` | ActiveRecord callbacks (`after_create_commit`, `after_update_commit`) + Turbo Streams notifican a todos los suscriptores automáticamente al cambiar estado |
| **Service Object** | `VolunteerMatchingService`, `NotificationService`, `EmergencyConflictResolver` | Objetos Ruby puros que encapsulan lógica de negocio compleja fuera de modelos y controladores |
| **Strategy** | Pundit policies (`EventPolicy`, `EnrollmentPolicy`, etc.) | Cada política encapsula las reglas de autorización de un recurso; son intercambiables desde `ApplicationPolicy` |
| **Value Object** | `EmergencyConflictResolver::Result` | Struct inmutable que transporta el resultado de la resolución de conflicto sin estado mutable |
| **Facade** | `NotificationService` | Interfaz simple para la creación de notificaciones; oculta los detalles de `Notification.create!` |
| **Template Method** | `ApplicationPolicy` → subpolicies | La clase base define la estructura (`index?`, `show?`, ...) y las subclases implementan el comportamiento específico |
| **Query Scope** | `Event.vigentes`, `Event.proximos`, `Notification.unread` | Named scopes encapsulan consultas reutilizables (variante del patrón Query Object) |

---

## Análisis SOLID

| Principio | Estado | Notas |
|-----------|--------|-------|
| **S** — Responsabilidad única | Parcial | `VolunteerProfile` concentra demasiada lógica; el resto de clases están bien delimitadas |
| **O** — Abierto/Cerrado | Bueno | Agregar un tipo de evento o política no requiere modificar código existente; `NotificationService` es el caso más débil |
| **L** — Sustitución de Liskov | Bueno | `Admin::BaseController`, subpolicies y `Users::RegistrationsController < Devise::RegistrationsController` cumplen el contrato de sus bases |
| **I** — Segregación de interfaces | Bueno | Pundit separa las políticas por recurso; ningún cliente depende de métodos que no usa |
| **D** — Inversión de dependencias | Parcial | `VolunteerMatchingService` instancia `EmergencyConflictResolver` directamente; `Event` llama a `VolunteerMatchingService.new(self)` desde un callback. En Rails esto es convención aceptada pero crea acoplamiento concreto |

---

## Mejoras recomendadas (no aplicadas — requieren decisión de equipo)

1. **Extraer `ScoreCalculator`** — La lógica de `calculate_score!` y `update_skills_from_reviews!` en `VolunteerProfile` podría ir a un servicio dedicado. El modelo quedaría como orquestador y el cálculo sería testeable de forma aislada.

2. **Idioma del código** — Migrar nombres de métodos, variables y enums al inglés (`active` en vez de `activo`, `enrolled` en vez de `convocado`, etc.) siguiendo el estándar universal de la industria. Requiere migrar vistas, rutas y seeds en simultaneo.

3. **Query Object para el dashboard de admin** — `Admin::DashboardController#index` carga cuatro modelos sin paginación. Con datasets grandes, esto se vuelve lento. Un Query Object o Pagy/Kaminari resolverían el problema.

4. **Test suite** — El proyecto no tiene tests. Implementar RSpec + FactoryBot para modelos (`VolunteerProfile`, `Event`) y tests de integración para el flujo de matching.

5. **Concern `event_params` compartido** — Si `EventsController` y `Admin::EventsController` siguen sincronizados, se puede extraer a un concern privado `EventParamsSanitizer`.
