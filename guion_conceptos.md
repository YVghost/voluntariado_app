# Guión — Buenas Prácticas, Patrones de Diseño y SOLID
## Plataforma de Coordinación de Voluntariado · Ruby on Rails

> **Cómo leer este documento:**
> Es un guión narrativo. Cada sección explica el concepto, luego lo muestra con código real del proyecto.
> Los textos en **[corchetes]** son indicaciones de pantalla — no se dicen en voz alta.
> Duración estimada: **25–30 minutos**

---

## PORTADA

**[Pantalla: título del proyecto]**

Hola. En este video vamos a recorrer tres grandes pilares del desarrollo de software profesional: las buenas prácticas de Clean Code, los cinco principios SOLID y los patrones de diseño clásicos.

Lo que hace especial este recorrido es que no vamos a usar ejemplos teóricos inventados. Vamos a usar código real — el de esta plataforma de coordinación de voluntariado que construí en Ruby on Rails.

Cada concepto que expliquemos va a tener un ejemplo concreto del proyecto. Así podés ver cómo se ve un patrón o un principio aplicado en un sistema real, no en un libro de texto.

Empecemos.

---

# PARTE 1
# Buenas Prácticas — Clean Code

---

## ¿Qué es Clean Code?

**[Pantalla: editor vacío]**

Clean Code, o código limpio, es un conjunto de prácticas que buscan que el código sea fácil de leer, entender y modificar. No es solo que funcione — es que cualquier desarrollador pueda leerlo mañana y entender qué hace sin necesitar que se lo expliquen.

La idea central la resume bien Robert C. Martin, autor del libro Clean Code:

> "El código se lee mucho más veces de las que se escribe."

Vamos a ver cuatro prácticas concretas: nombres descriptivos, funciones pequeñas, sin números mágicos y sin comentarios innecesarios.

---

## Práctica 1 — Nombres descriptivos

**[Pantalla: app/models/volunteer_profile.rb — constantes al inicio]**

Un nombre bien elegido hace que el código se explique solo.

Mirá estas constantes en el modelo `VolunteerProfile`:

```ruby
SKILLS = %w[
  primeros_auxilios
  busqueda_rescate
  apoyo_psicosocial
  logistica_abastecimiento
  maquinaria_construccion
].freeze

SKILL_IMMEDIATE_THRESHOLD = { 1 => 1.5, 2 => 2.0, 3 => 2.5, 4 => 3.0, 5 => 3.2, 6 => 3.5 }.freeze
SKILL_SUPPORT_THRESHOLD   = { 1 => 0.5, 2 => 1.0, 3 => 1.5, 4 => 2.0, 5 => 2.5, 6 => 3.0 }.freeze
```

Sin leer ni una línea de documentación ya sabés qué hace cada cosa. `SKILL_IMMEDIATE_THRESHOLD` es el umbral de score de habilidad para ser convocado como inmediato. `SKILL_SUPPORT_THRESHOLD` es el umbral para ser convocado como apoyo.

Comparalo con cómo se vería si los nombres fueran malos:

```ruby
# Versión con nombres malos ❌
T1 = { 1 => 1.5, 2 => 2.0 ... }
T2 = { 1 => 0.5, 2 => 1.0 ... }
```

¿Qué es `T1`? ¿Qué es `T2`? Imposible saberlo sin contexto.

**La regla: un nombre tiene que revelar la intención. Si necesitás un comentario para explicar qué hace una variable, el nombre está mal.**

---

## Práctica 2 — Funciones pequeñas con una sola responsabilidad

**[Pantalla: app/models/notification.rb]**

Una función pequeña hace una sola cosa. Mirá este método en el modelo `Notification`:

```ruby
def mark_as_read!
  update!(read: true)
end
```

Una línea. Una responsabilidad. Marca la notificación como leída. No hace nada más.

Ahora mirá este otro en `VolunteerProfile`:

```ruby
def tier_for_event(event)
  return nil unless available? && quiz_completed_at.present?
  return nil unless event.emergency_level.present?

  level    = event.emergency_level.to_i
  required = Array(event.required_skills).compact.reject(&:empty?)

  if required.any?
    skill_tier_for(required, level)
  else
    global_tier_for(level)
  end
end
```

Este método también hace una sola cosa: determinar el tier de un voluntario para un evento específico. Pero es más complejo — entonces delega la complejidad a métodos privados `skill_tier_for` y `global_tier_for`. Eso es correcto: el método orquesta, los métodos privados ejecutan.

**La regla: si una función hace dos cosas, tiene que ser dos funciones.**

---

## Práctica 3 — Sin números mágicos

**[Pantalla: app/models/event.rb — método auto_cancelar_no_iniciados!]**

Un número mágico es un valor literal en el código sin contexto. Es una de las peores prácticas porque parece inofensivo y rompe todo silenciosamente.

Este fue un problema real en el proyecto. El método que cancela eventos expirados tenía esto:

```ruby
# ANTES — con número mágico ❌
def self.auto_cancelar_no_iniciados!
  where(status: :activo)
    .where("date < ?", 3.days.ago)
    .update_all(status: 3)  # 3 = cancelado
end
```

El `3` representa el estado `:cancelado` en el enum. Pero, ¿cómo saber eso sin memorizar el enum? Y peor: si alguien reordena los valores del enum, ese `3` silenciosamente va a apuntar al estado incorrecto. Sin error. Sin advertencia.

```ruby
# DESPUÉS — código autoexplicativo ✅
def self.auto_cancelar_no_iniciados!
  where(status: :activo)
    .where("date < ?", 3.days.ago)
    .update_all(status: statuses[:cancelado])
end
```

`statuses[:cancelado]` lee el valor directamente del enum de Rails. El comentario desaparece porque el código ya dice todo.

**La regla: si escribís un comentario que explica qué hace un número, el número está mal. Nombralo.**

---

## Práctica 4 — Sin comentarios innecesarios

**[Pantalla: app/services/volunteer_matching_service.rb]**

Existe una distinción importante entre comentarios que explican el *qué* y comentarios que explican el *por qué*.

Los comentarios que explican el *qué* son innecesarios si el código está bien escrito:

```ruby
# Malo ❌ — el comentario repite lo que el código ya dice
# Crea la inscripción del voluntario
enrollment = @event.enrollments.create!(user: profile.user, status: :convocado)
```

Los comentarios que explican el *por qué* son valiosos — documentan decisiones no evidentes:

```ruby
# Bueno ✅ — el comentario explica una decisión de diseño
# Si ya hay skill_scores de reviews, mezclamos: 40% quiz + 60% reviews
merged = new_skill_scores.merge(skill_scores || {}) { |_skill, quiz_val, review_val|
  ((quiz_val * 0.4) + (review_val.to_f * 0.6)).round(2)
}
```

Ese comentario explica *por qué* la mezcla es 40/60, no *qué* hace el código. Eso sí tiene valor — un futuro desarrollador que lea esa fórmula va a entender la decisión de diseño.

**La regla: el código explica el qué. Los comentarios explican el por qué. Si el qué no es claro, reescribí el código.**

---

## Práctica 5 — DRY (Don't Repeat Yourself)

**[Pantalla: app/models/volunteer_profile.rb — constante SECTION_MAP]**

DRY es quizás el principio más conocido del desarrollo de software: cada pieza de conocimiento debe tener una única representación en el sistema.

En el proyecto, el mapa de habilidades a preguntas del quiz estaba escrito dos veces — una en `calculate_score!` y otra en `update_skills_from_reviews!`. Si alguien agrega una habilidad nueva, tenía que actualizarlo en dos lugares. Si solo actualiza uno, el sistema calcula scores de forma inconsistente.

La solución: extraerlo como constante de clase.

```ruby
SECTION_MAP = {
  "primeros_auxilios"        => %w[q1 q2 q3 q4 q5],
  "busqueda_rescate"         => %w[q6 q7 q8 q9 q10],
  "apoyo_psicosocial"        => %w[q11 q12 q13 q14 q15],
  "logistica_abastecimiento" => %w[q16 q17 q18 q19 q20],
  "maquinaria_construccion"  => %w[q21 q22 q23 q24 q25]
}.freeze
```

Ahora ambos métodos referencian `SECTION_MAP`. Si se agrega una habilidad, se cambia en un solo lugar y ambos métodos se actualizan automáticamente.

**La regla: si copiaste y pegaste código, algo está mal. Encapsulalo.**

---

# PARTE 2
# Los 5 Principios SOLID

---

## ¿Qué son los principios SOLID?

**[Pantalla: fondo oscuro con letras S-O-L-I-D]**

SOLID es un acrónimo de cinco principios de diseño orientado a objetos formulados por Robert C. Martin. Juntos guían hacia sistemas que son fáciles de extender, mantener y entender.

- **S** — Single Responsibility (Responsabilidad Única)
- **O** — Open/Closed (Abierto/Cerrado)
- **L** — Liskov Substitution (Sustitución de Liskov)
- **I** — Interface Segregation (Segregación de Interfaces)
- **D** — Dependency Inversion (Inversión de Dependencias)

Vamos uno por uno, con ejemplos del proyecto.

---

## S — Single Responsibility Principle

**[Pantalla: app/controllers/events_controller.rb]**

**Una clase o método debe tener una sola razón para cambiar.**

En términos prácticos: cada unidad de código debe hacer una sola cosa. Si tenés que cambiarla por dos razones distintas, tiene dos responsabilidades y debe dividirse.

Ejemplo de violación — la acción `index` del `EventsController` antes del refactoring:

```ruby
# ANTES ❌ — dos responsabilidades mezcladas
def index
  @events = policy_scope(Event)      # Responsabilidad 1: cargar eventos
  authorize Event

  if current_user&.voluntario? && current_user.profile_complete?
    profile = current_user.volunteer_profile
    convocado_enrollments = current_user.enrollments
                                        .joins(:event)
                                        .where(status: :convocado) ...
    @convocados  = Event.where(...)   # Responsabilidad 2: datos específicos
    @segunda_ola = Event.where(...)   # del voluntario
    @disponibles = Event.vigentes ... #
  end
end
```

Después del refactoring:

```ruby
# DESPUÉS ✅ — cada método, una responsabilidad
def index
  @events = policy_scope(Event)
  authorize Event
  load_volunteer_event_data if current_user&.voluntario? && current_user.profile_complete?
end

private

def load_volunteer_event_data
  # todo el bloque del voluntario aquí, con nombre que revela su intención
end
```

Si cambia la lógica de autorización, modificás `index`. Si cambia la lógica de datos del voluntario, modificás `load_volunteer_event_data`. **Dos razones de cambio, dos métodos.**

**El test mental del SRP: ¿podés describir qué hace este método en una sola oración sin usar "y"? Si no, tiene más de una responsabilidad.**

---

## O — Open/Closed Principle

**[Pantalla: app/policies/application_policy.rb y app/policies/event_policy.rb]**

**El código debe estar abierto para extensión pero cerrado para modificación.**

Esto significa que deberías poder agregar nuevas funcionalidades sin modificar el código existente que ya funciona.

El ejemplo más claro del proyecto son las políticas de Pundit. `ApplicationPolicy` define la estructura base:

```ruby
class ApplicationPolicy
  def index?   = false
  def show?    = false
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false
end
```

Cada recurso nuevo — un evento, una inscripción, una organización — extiende esa base sin tocarla:

```ruby
class EventPolicy < ApplicationPolicy
  def index? = true

  def show?
    user.admin? ||
      (user.organizador? && own_event?) ||
      (user.voluntario? && (record.activo? || record.en_curso?))
  end

  def create? = user.admin? || user.organizador?
end
```

Si mañana el sistema necesita un recurso nuevo — por ejemplo, una `DonationPolicy` — se crea una clase nueva que hereda de `ApplicationPolicy`. **No se toca ningún código existente.**

**La violación típica del OCP es el `if` gigante que crece cada vez que se agrega un caso nuevo. La solución es polimorfismo y herencia.**

---

## L — Liskov Substitution Principle

**[Pantalla: app/controllers/admin/base_controller.rb y app/controllers/admin/events_controller.rb]**

**Los objetos de un programa deben ser reemplazables por instancias de sus subtipos sin alterar el correcto funcionamiento del programa.**

En términos simples: una subclase debe cumplir el contrato de su clase base. No puede romper lo que la base prometía.

En el proyecto, la jerarquía de controladores admin sigue este principio correctamente:

```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path, alert: "Acceso restringido." unless current_user.admin?
  end
end
```

```ruby
class Admin::EventsController < Admin::BaseController
  def new
    @event = Event.new
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    authorize @event
    # ...
  end
end
```

`Admin::EventsController` puede sustituir a `Admin::BaseController` en cualquier contexto — hereda la autenticación, hereda Pundit, agrega funcionalidad nueva sin romper nada de lo que ya existía.

Lo mismo pasa con `Users::RegistrationsController < Devise::RegistrationsController`. Extiende el comportamiento de Devise — agrega la lógica de creación de organizaciones — pero respeta completamente el contrato de la clase base.

**La violación del LSP es cuando una subclase fuerza a los llamadores a saber de qué tipo concreto se trata para comportarse diferente. Eso rompe el polimorfismo.**

---

## I — Interface Segregation Principle

**[Pantalla: app/policies — los cuatro archivos de policies]**

**Es mejor tener muchas interfaces específicas que una sola interfaz general. Ningún módulo debe depender de métodos que no usa.**

En Ruby y Rails no hay interfaces explícitas como en Java, pero el principio se aplica igualmente a través de módulos y la estructura de las clases.

El ejemplo más claro es, de nuevo, Pundit. En lugar de tener una sola clase de autorización con todas las reglas de todos los recursos:

```ruby
# Violación del ISP ❌ — todo en un solo lugar
class Policy
  def can_create_event?(user) ...
  def can_edit_event?(user, event) ...
  def can_create_enrollment?(user, event) ...
  def can_mark_attendance?(user, enrollment) ...
  def can_create_organization?(user) ...
  # ... 20 métodos más
end
```

El proyecto tiene políticas separadas por recurso. Cada controlador solo depende de la política del recurso que maneja:

```ruby
class EventPolicy < ApplicationPolicy       # solo reglas de eventos
class EnrollmentPolicy < ApplicationPolicy  # solo reglas de inscripciones
class OrganizationPolicy < ApplicationPolicy # solo reglas de orgs
class MessagePolicy < ApplicationPolicy     # solo reglas de mensajes
```

`EventsController` solo conoce `EventPolicy`. No sabe que existe `EnrollmentPolicy`. **Cada cliente depende solo de la interfaz que necesita.**

**El ISP evita que cambiar las reglas de autorización de inscripciones afecte accidentalmente a la lógica de eventos.**

---

## D — Dependency Inversion Principle

**[Pantalla: app/services/volunteer_matching_service.rb]**

**Los módulos de alto nivel no deben depender de los módulos de bajo nivel. Ambos deben depender de abstracciones.**

Este es el principio más sutil. La idea es que el código que orquesta (alto nivel) no debe estar atado a implementaciones concretas (bajo nivel).

En el proyecto, `VolunteerMatchingService` orquesta todo el proceso de convocatoria. Cuando un voluntario tiene conflicto, delega a `EmergencyConflictResolver`:

```ruby
# En VolunteerMatchingService
resolver = EmergencyConflictResolver.new(@event, profile)
result   = resolver.resolve

case result.action
when :convoke_conflict
  convoke!(profile, conflict_message: result.message)
when :second_wave
  convoke_second_wave!(profile, result.message)
end
```

El servicio de matching habla con `EmergencyConflictResolver` a través de la interfaz que este expone: el método `.resolve` y el `Result` que devuelve. No le importa cómo implementa internamente la resolución.

Si mañana quisiéramos cambiar la lógica de conflictos — por ejemplo, agregar una cuarta comparación — solo modificamos `EmergencyConflictResolver`. El `VolunteerMatchingService` no se toca.

**El estado parcial de este principio en el proyecto es que `EmergencyConflictResolver` se instancia directamente. En un sistema más grande, se inyectaría como dependencia para poder reemplazarlo fácilmente en tests. En Rails, la convención acepta esta forma.**

---

# PARTE 3
# Patrones de Diseño

---

## ¿Qué son los patrones de diseño?

**[Pantalla: fondo oscuro]**

Los patrones de diseño son soluciones reutilizables a problemas comunes en el diseño de software. No son código que se copia — son plantillas, ideas que se adaptan al contexto.

Los formularon Christopher Alexander y luego los popularizó el libro "Design Patterns" del Gang of Four en 1994.

Se dividen en tres categorías:
- **Creacionales** — cómo se crean objetos
- **Estructurales** — cómo se organizan y ensamblan
- **De comportamiento** — cómo se comunican y distribuyen responsabilidades

El proyecto usa siete patrones. Los vemos uno por uno.

---

## PATRONES CREACIONALES

---

## Builder — construcción paso a paso

**[Pantalla: app/controllers/admin/organizations_controller.rb]**

El patrón **Builder** permite construir objetos complejos paso a paso, especialmente cuando la creación involucra múltiples pasos interdependientes.

En el proyecto, la creación de una organización es un proceso de dos pasos dentro de una transacción: primero se crea el representante, luego la organización vinculada a él. Si cualquiera de los dos falla, ambos se revierten.

```ruby
def create
  ActiveRecord::Base.transaction do
    @rep = User.new(representante_params)
    @rep.role = :organizador
    @rep.save!                         # Paso 1: crear el representante

    @organization = Organization.new(org_params)
    @organization.user = @rep
    @organization.save!                # Paso 2: crear la org vinculada
  end

  redirect_to admin_dashboard_index_path(tab: "organizaciones"),
              notice: "Organización creada correctamente."
rescue ActiveRecord::RecordInvalid
  # si cualquier paso falla, ambos se revierten
  render :new, status: :unprocessable_entity
end
```

La transacción garantiza atomicidad — o ambos se crean juntos o no se crea ninguno. Eso es construcción secuencial de un objeto complejo con integridad garantizada.

---

## PATRONES ESTRUCTURALES

---

## Facade — interfaz simplificada

**[Pantalla: app/services/notification_service.rb]**

El patrón **Facade** provee una interfaz simple a un conjunto complejo de operaciones. Oculta los detalles internos y expone solo lo que los clientes necesitan saber.

`NotificationService` es una facade perfecta. Desde afuera, crear una notificación es llamar un método descriptivo:

```ruby
NotificationService.voluntario_convocado(enrollment)
NotificationService.event_finalizado(event)
NotificationService.convocado_con_conflicto(enrollment, message)
```

Cada método tiene un nombre que revela el caso de uso del negocio. El cliente no sabe — ni necesita saber — cómo se crea la notificación internamente, qué campos lleva, o qué tabla usa.

Adentro del servicio, todos esos métodos delegan a un método privado `create_for`:

```ruby
private_class_method def self.create_for(enrollment, message, notifiable: enrollment)
  Notification.create!(user: enrollment.user, notifiable: notifiable, message: message)
end
```

**La facade absorbe la complejidad. Los clientes obtienen una interfaz clara. Si cambia la implementación interna — por ejemplo, se migra a notificaciones por email — los llamadores no se tocan.**

---

## Adapter — conectar interfaces incompatibles

**[Pantalla: app/models/concerns/ecuador_validations.rb]**

El patrón **Adapter** permite que dos interfaces que no son compatibles trabajen juntas.

En el proyecto, `EcuadorValidations` actúa como adapter entre los modelos de Rails (que esperan métodos de validación estándar) y los algoritmos de documentos ecuatorianos (que son lógica pura, sin relación con ActiveRecord).

```ruby
module EcuadorValidations
  def self.cedula_valida?(cedula)
    return false unless cedula.to_s.match?(/^\d{10}$/)
    provincia = cedula[0..1].to_i
    return false unless provincia.between?(1, 24)
    # ... algoritmo módulo 10 del Registro Civil
  end

  def self.ruc_valido?(ruc)
    # ... algoritmo del SRI
  end
end
```

Los modelos lo usan como si fuera su propio código:

```ruby
# En User
def cedula_ecuatoriana_valida
  errors.add(:cedula, "no es válida") unless EcuadorValidations.cedula_valida?(cedula)
end

# En Organization
def ruc_ecuatoriano_valido
  errors.add(:ruc, "no es válido") unless EcuadorValidations.ruc_valido?(ruc)
end
```

**El adapter traduce entre el mundo de Rails (validaciones personalizadas) y el mundo del dominio ecuatoriano (algoritmos específicos del Registro Civil y el SRI).**

---

## PATRONES DE COMPORTAMIENTO

---

## Observer — notificación automática de cambios

**[Pantalla: app/models/event.rb y app/models/notification.rb]**

El patrón **Observer** define una relación de uno a muchos donde, cuando un objeto cambia de estado, todos sus dependientes son notificados automáticamente.

Este es el patrón más usado en el proyecto, y Rails lo implementa de forma elegante con los callbacks de ActiveRecord y Turbo Streams.

Cuando un evento cambia de estado:

```ruby
# En Event
after_update_commit :broadcast_status_change, if: :saved_change_to_status?
after_update_commit :notify_volunteers_if_finalizado, if: -> { saved_change_to_status? && finalizado? }
```

Cuando se crea un mensaje de chat:

```ruby
# En Message
after_create_commit do
  broadcast_append_to [event, :chat],
    target: "messages",
    partial: "messages/message",
    locals: { message: self }
end
```

Cuando se crea una notificación:

```ruby
# En Notification
after_create_commit :broadcast_to_user
```

El modelo es el sujeto observable. Los navegadores de los usuarios suscriptos son los observadores. El evento dispara el cambio, y todos los observadores — todas las pestañas abiertas — reciben la actualización en tiempo real sin que nadie lo haya pedido explícitamente.

**El Observer desacopla al emisor del receptor. El modelo `Event` no sabe cuántos navegadores están escuchando. Solo anuncia el cambio.**

---

## Strategy — algoritmos intercambiables

**[Pantalla: app/policies/event_policy.rb y app/policies/enrollment_policy.rb]**

El patrón **Strategy** define una familia de algoritmos, los encapsula individualmente y los hace intercambiables. El algoritmo puede variar independientemente de los clientes que lo usan.

Las políticas de Pundit son Strategy aplicado a la autorización.

`ApplicationPolicy` define la interfaz — los métodos que toda política debe implementar:

```ruby
class ApplicationPolicy
  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false
end
```

Cada política concreta implementa su propio algoritmo de autorización:

```ruby
# EventPolicy — su propio algoritmo
def show?
  user.admin? ||
    (user.organizador? && own_event?) ||
    (user.voluntario? && (record.activo? || record.en_curso?))
end

# EnrollmentPolicy — algoritmo completamente diferente
def create?
  return false unless user.voluntario?
  return false unless record.event.activo? || record.event.en_curso?
  profile = user.volunteer_profile
  return false unless profile&.quiz_completed_at.present?
  return false if record.event.emergency_level.present? && !profile.tier_for_event(record.event)
  true
end
```

Los controladores usan `authorize @record` sin saber qué política se va a ejecutar. Pundit selecciona la estrategia correcta según el tipo del recurso.

**Si mañana las reglas de `EventPolicy` cambian, solo se modifica esa clase. Los controladores y el resto del sistema no se tocan.**

---

## Value Object — transporte de datos inmutable

**[Pantalla: app/services/emergency_conflict_resolver.rb]**

El patrón **Value Object** representa un concepto del dominio que se define solo por sus atributos, no por su identidad. Son inmutables — dos Value Objects con los mismos valores son intercambiables.

En el proyecto, `EmergencyConflictResolver` resuelve el conflicto cuando un voluntario ya está activo en otra emergencia. El resultado de esa resolución es un Value Object:

```ruby
class EmergencyConflictResolver
  Result = Struct.new(:action, :message, keyword_init: true)

  def resolve
    resolution = @profile.conflict_resolution_for(@new_event)
    Result.new(action: resolution, message: message_for(resolution))
  end
end
```

`Result` tiene dos atributos: `action` (qué hacer — convocar, saltar, segunda ola) y `message` (el texto de notificación). El `Struct` de Ruby crea automáticamente accessors y un constructor limpio.

El llamador recibe el resultado y actúa según el `action`:

```ruby
result = resolver.resolve

case result.action
when :convoke_conflict
  convoke!(profile, conflict_message: result.message)
when :second_wave
  convoke_second_wave!(profile, result.message)
when :skip
  next
end
```

**El Value Object es más expresivo que devolver un array `[:convoke_conflict, "mensaje..."]` — el acceso por nombre es claro, y el objeto documenta su propia estructura.**

---

## Service Object — lógica de negocio encapsulada

**[Pantalla: app/services/volunteer_matching_service.rb]**

El **Service Object** no es un patrón del Gang of Four original, pero es uno de los más usados en Rails. Resuelve un problema frecuente: ¿dónde va la lógica de negocio compleja que no pertenece ni al modelo ni al controlador?

La respuesta: en un objeto Ruby puro dedicado a esa operación.

`VolunteerMatchingService` es el ejemplo principal. Cuando se crea una emergencia, este servicio orquesta todo el proceso de convocatoria:

```ruby
class VolunteerMatchingService
  MAX_IMMEDIATE = 20
  MAX_SUPPORT   = 50

  def initialize(event)
    @event = event
  end

  def call
    return unless @event.emergency_level.present?

    immediate = []
    support   = []

    candidate_profiles.each do |profile|
      tier = profile.tier_for_event(@event)
      next unless tier

      if profile.busy_in_active_emergency?(exclude_event: @event)
        resolver = EmergencyConflictResolver.new(@event, profile)
        result   = resolver.resolve
        # ... maneja el conflicto
      else
        case tier
        when :immediate then immediate << profile
        when :support   then support   << profile
        end
      end
    end

    immediate.sort_by { |p| -p.score }.first(MAX_IMMEDIATE).each { |p| convoke!(p) }
    support.sort_by   { |p| -p.score }.first(MAX_SUPPORT).each   { |p| convoke!(p) }
  end
end
```

El modelo `Event` solo dispara el servicio desde un callback:

```ruby
after_create_commit :run_matching_if_emergency

def run_matching_if_emergency
  VolunteerMatchingService.new(self).call if emergency_level.present?
end
```

**El Service Object mantiene el modelo delgado, el controlador limpio y la lógica de negocio testeable en aislamiento.**

---

## Template Method — estructura fija, detalles variables

**[Pantalla: app/policies/application_policy.rb]**

El patrón **Template Method** define el esqueleto de un algoritmo en una clase base, dejando que las subclases implementen pasos específicos.

`ApplicationPolicy` es un Template Method aplicado a la autorización. Define los métodos que toda política debe responder — el esqueleto:

```ruby
class ApplicationPolicy
  def index?   = false   # por defecto: denegado
  def show?    = false
  def create?  = false
  def new?     = create? # new? delega a create? — variación controlada
  def update?  = false
  def edit?    = update? # edit? delega a update? — variación controlada
  def destroy? = false
end
```

Las subclases sobrescriben solo los métodos que necesitan cambiar:

```ruby
class OrganizationPolicy < ApplicationPolicy
  def index? = true   # sobrescribe — lectura pública
  def show?  = true   # sobrescribe — lectura pública
  # create?, update?, destroy? → heredados con sus reglas propias
end
```

**La relación `new? = create?` y `edit? = update?` es especialmente elegante: son alias polimórficos. Cambiar `create?` automáticamente cambia `new?`. Eso es Template Method controlando la variación.**

---

## Query Scope — consultas nombradas y reutilizables

**[Pantalla: app/models/event.rb — scopes]**

Los **Query Scopes** de Rails son una variante del patrón **Query Object**. Encapsulan consultas de base de datos con nombres que revelan su intención, haciéndolas componibles y reutilizables.

```ruby
# En Event
scope :activos,        -> { where(status: :activo) }
scope :vigentes,       -> { where(status: [:activo, :en_curso]) }
scope :proximos,       -> { where("date >= ?", Time.current).order(:date) }
scope :cancelados,     -> { where(status: :cancelado) }

# En Notification
scope :unread, -> { where(read: false) }
scope :recent, -> { order(created_at: :desc) }
```

En lugar de escribir `where(status: [:activo, :en_curso])` en cada lugar que se necesita, se escribe `Event.vigentes`. Si la definición de "vigente" cambia, se actualiza en un solo lugar.

Y lo más poderoso: los scopes son componibles:

```ruby
Event.vigentes.where.not(emergency_level: nil).order(:date)
```

**Los scopes son el patrón Query Object adaptado a las convenciones de Rails. Nombran las consultas con vocabulario del dominio, no con SQL.**

---

## RESUMEN FINAL

**[Pantalla: tabla resumen]**

Entonces, recapitulando todo lo que vimos:

### Buenas Prácticas aplicadas

| Práctica | Dónde |
|----------|-------|
| Nombres descriptivos | Constantes en `VolunteerProfile`: `SKILL_IMMEDIATE_THRESHOLD`, `SECTION_MAP` |
| Funciones pequeñas | `mark_as_read!`, `tier_for_event`, `load_volunteer_event_data` |
| Sin números mágicos | `statuses[:cancelado]` en lugar de `3` |
| Sin comentarios innecesarios | El código se explica por sí mismo |
| DRY | `SECTION_MAP`, `user_params`, `create_for` en `NotificationService` |

### Principios SOLID

| Principio | Estado | Ejemplo |
|-----------|:------:|---------|
| S — Responsabilidad única | ✅ | `load_volunteer_event_data` extraído de `index` |
| O — Abierto/Cerrado | ✅ | Pundit policies extensibles sin modificar la base |
| L — Sustitución de Liskov | ✅ | `Admin::BaseController` y subpolicies |
| I — Segregación de interfaces | ✅ | Políticas separadas por recurso |
| D — Inversión de dependencias | ⚠️ | `EmergencyConflictResolver` instanciado directamente |

### Patrones de diseño

| Patrón | Categoría | Dónde |
|--------|-----------|-------|
| Builder | Creacional | `Admin::OrganizationsController#create` |
| Facade | Estructural | `NotificationService` |
| Adapter | Estructural | `EcuadorValidations` |
| Observer | Comportamiento | Callbacks + Turbo Streams en `Event`, `Message`, `Notification` |
| Strategy | Comportamiento | Pundit policies |
| Value Object | Comportamiento | `EmergencyConflictResolver::Result` |
| Service Object | Comportamiento | `VolunteerMatchingService`, `EmergencyConflictResolver` |
| Template Method | Comportamiento | `ApplicationPolicy` → subpolicies |
| Query Scope | Comportamiento | `Event.vigentes`, `Notification.unread` |

---

## CIERRE

**[Pantalla: pantalla negra con texto]**

Para cerrar, quiero dejar una idea que conecta todo lo que vimos.

Las buenas prácticas, los principios SOLID y los patrones de diseño no son reglas a seguir ciegamente. Son **vocabulario compartido** — un lenguaje que permite a los desarrolladores comunicarse sobre el código con precisión.

Cuando alguien dice "esto viola el SRP" o "necesitamos un Facade acá", todos en el equipo entienden exactamente de qué se habla. Eso acelera las conversaciones, reduce los malentendidos y hace que el código evolucione en la dirección correcta.

El objetivo final siempre es el mismo:

> **Que el sistema sea fácil de entender, modificar y mantener — no solo hoy, sino en seis meses cuando nadie recuerde exactamente cómo funciona.**

Gracias.

---

> **Duración estimada por sección:**
> | Sección | Tiempo |
> |---------|--------|
> | Portada + intro | 1 min |
> | Clean Code (5 prácticas) | 7 min |
> | SOLID (5 principios) | 8 min |
> | Patrones de diseño (9 patrones) | 10 min |
> | Resumen + Cierre | 2 min |
> | **Total** | **~28 min** |
