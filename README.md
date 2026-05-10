# Plataforma de Coordinación de Voluntariado

Sistema web para la gestion y cordinacion de emergencias a tiempo real. Permite a organizaciones y entidades publicar emergencias que se requiera voluntarios y gente especializada para brindar ayuda y asistencia de forma inmediata permitiendo a los voluntarios recibir notificacion por geolalizacion, hacer aceptacion y chat en vivo para facilitar comunicacion.

---

## Idea general

El flujo principal es:

1. Una **organización** se registra en la plataforma con su RUC y datos de un representante (rol `organizador`).
2. El organizador crea **eventos** con fecha, ubicación y descripción.
3. Los **voluntarios** se registran con su cédula y se inscriben a los eventos disponibles.
4. Durante el evento, los voluntarios registran su asistencia con **check-in por geolocalización**.
5. Al finalizar un evento, todos los inscritos reciben una **notificación en tiempo real**.
6. A lo largo del evento existe un **chat en vivo** exclusivo para los participantes.
7. El **administrador** tiene acceso a un panel completo con CRUD de usuarios, organizaciones, eventos e inscripciones.

---

## Tecnologías

| Categoría | Tecnología |
|---|---|
| Framework | Ruby on Rails 8.1.3 |
| Lenguaje | Ruby 3.2.2 |
| Base de datos | PostgreSQL |
| Autenticación | Devise ~5.0 |
| Autorización | Pundit |
| Frontend reactivo | Hotwire (Turbo + Stimulus) |
| WebSockets | Action Cable + Solid Cable |
| CSS | Tailwind CSS v4 (tailwindcss-rails) |
| Asset pipeline | Propshaft |
| Import maps | importmap-rails |
| Background jobs | Solid Queue |
| Cache | Solid Cache |
| Servidor | Puma |

---

## Requisitos previos

- Ruby 3.2.2
- PostgreSQL 14+
- Node.js (solo para compilar Tailwind en desarrollo)

---

## Instalación

```bash
git clone <repo>
cd voluntariado_app

bundle install

bin/rails db:create db:migrate

bin/rails server
```

En otra terminal, compilar Tailwind en modo watch:

```bash
bin/rails tailwindcss:watch
```

---

## Roles de usuario

El modelo `User` usa un `enum` con tres roles:

| Rol | Valor | Descripción |
|---|---|---|
| `admin` | 0 | Acceso total al panel de administración |
| `organizador` | 1 | Representa a una organización; crea y gestiona eventos |
| `voluntario` | 2 | Se inscribe en eventos y puede hacer check-in (**rol por defecto**) |

Los voluntarios requieren cédula ecuatoriana válida. Los organizadores son creados al registrar una organización.

---

## Autenticación (Devise)

Se usa **Devise** con los módulos `database_authenticatable`, `registerable`, `recoverable`, `rememberable` y `validatable`.

### Registro dual

La pantalla de registro (`/users/sign_up`) tiene dos pestañas:

- **Voluntario** — requiere nombres, apellidos, cédula, email y contraseña. Se crea un `User` con rol `voluntario`.
- **Organización** — requiere datos de la organización (nombre, RUC, ubicación, descripción) y datos del representante (nombres, apellidos, cédula, email, contraseña). Se usa `ActiveRecord::Base.transaction` para garantizar que el `User` organizador y la `Organization` se creen juntos o ninguno se guarde.

Esto está implementado en `Users::RegistrationsController < Devise::RegistrationsController`, que sobreescribe el action `create` y despacha a `create_voluntario` o `create_organizacion` según el parámetro `registration_type` enviado por el formulario.

### Validaciones ecuatorianas

El módulo `EcuadorValidations` (en `app/models/concerns/`) implementa:

- **Cédula** — 10 dígitos, provincia entre 01–24, tercer dígito < 6, checksum módulo 10 del Registro Civil.
- **RUC** — 13 dígitos con tres casos según el tercer dígito:
  - `0–5`: persona natural → los primeros 10 dígitos deben ser una cédula válida + `001`
  - `6`: entidad pública
  - `9`: sociedad privada o extranjera

---

## Autorización (Pundit)

Cada recurso tiene una **policy** en `app/policies/`. Las reglas principales son:

- `EventPolicy` — los voluntarios solo ven eventos activos; los organizadores solo ven/editan los eventos de su propia organización; los admins ven todo.
- `OrganizationPolicy` — solo admins pueden crear organizaciones; el organizador puede editar la suya.
- `EnrollmentPolicy` — solo voluntarios pueden inscribirse, únicamente en eventos activos; solo pueden cancelar su propia inscripción.

Las vistas usan `policy(@record).accion?` para mostrar u ocultar botones. Los controllers llaman `authorize @record` que lanza `Pundit::NotAuthorizedError` si no se cumple la policy, redirigiendo al root con un alerta.

El filtrado por scope se hace con `policy_scope(Event)`, que devuelve distintos conjuntos según el rol:

```ruby
# EventPolicy::Scope
if user.admin?      then scope.all
elsif user.organizador? then scope.joins(:organization).where(organizations: { user_id: user.id })
else scope.activos
end
```

---

## Chat en tiempo real

Cada evento tiene un chat en vivo disponible para sus participantes. El flujo completo es:

### 1. Suscripción al canal

En la vista `events/show.html.erb`:

```erb
<%= turbo_stream_from @event, :chat %>
```

Esto abre una suscripción de Action Cable al stream identificado como `["Event", event.id, "chat"]`. Cada navegador conectado queda escuchando ese stream.

### 2. Envío de mensaje

El formulario de chat hace un POST a `events/:event_id/messages`. El `MessagesController` crea el registro y Rails responde vacío (el formulario se resetea con Turbo).

### 3. Broadcast automático

`Message` tiene un callback `after_create_commit`:

```ruby
after_create_commit do
  broadcast_append_to [event, :chat],
    target: "messages",
    partial: "messages/message",
    locals: { message: self }
end
```

Al guardarse, Turbo Streams transmite el partial `messages/_message.html.erb` a **todos los navegadores** suscritos al stream del evento. El mensaje aparece instantáneamente sin que nadie refresque la página.

### 4. Transporte

Action Cable usa **Solid Cable** (adaptador de base de datos incluido en Rails 8) como backend del broker de mensajes, sin necesidad de Redis en desarrollo.

---

## Notificaciones en tiempo real

Las notificaciones son persistentes (tabla `notifications`) y se entregan en tiempo real usando el mismo mecanismo de Turbo Streams.

### Modelo

```
Notification: user_id, message, read (default: false), notifiable (polimórfico)
```

`notifiable` es una asociación polimórfica: puede apuntar a un `Event` (evento finalizado) o a un `Enrollment` (inscripción confirmada).

### Flujo de entrega

Cuando se crea un `Notification`, el callback `after_create_commit` ejecuta:

```ruby
broadcast_prepend_to "notifications_#{user_id}",
  target: "notifications_list",
  partial: "notifications/notification",
  locals: { notification: self }

broadcast_replace_to "notifications_#{user_id}",
  target: "notifications_badge",
  html: badge_html   # conteo de no leídas
```

El navbar está suscrito al stream del usuario actual:

```erb
<%= turbo_stream_from "notifications_#{current_user.id}" %>
```

Así, el badge de notificaciones y la lista se actualizan en tiempo real sin recargar.

### Disparadores

| Evento | Método | Destinatarios |
|---|---|---|
| Voluntario se inscribe en un evento | `NotificationService.inscripcion_confirmada(enrollment)` | El voluntario |
| Organizador finaliza un evento | `NotificationService.event_finalizado(event)` | Todos los inscritos no cancelados |

---

## Check-in con geolocalización

Cuando un voluntario llega al evento puede registrar su asistencia con check-in. El flujo es:

1. El voluntario pulsa "Hacer check-in" en la página del evento.
2. El **Stimulus controller** `check-in` (`app/javascript/controllers/check_in_controller.js`) llama a `navigator.geolocation.getCurrentPosition()`.
3. Al obtener la posición, inyecta `latitude` y `longitude` en campos ocultos del formulario y lo envía con `form.requestSubmit()`.
4. El `EnrollmentsController#check_in` actualiza la inscripción con `status: :asistio`, `check_in_time: Time.current` y las coordenadas.
5. El servidor responde con un Turbo Stream que reemplaza el bloque `enrollment_section` en la página, actualizando la UI sin recargar.

Los estados de una inscripción son `inscrito → asistio` (o `cancelado`).

---

## Panel de administración

Disponible en `/admin/dashboard` únicamente para usuarios con rol `admin`.

La protección está en `Admin::BaseController`:

```ruby
before_action :require_admin!

def require_admin!
  redirect_to root_path, alert: "Acceso restringido." unless current_user.admin?
end
```

El panel tiene cuatro pestañas:

- **Usuarios** — listado completo con rol, cédula y fecha. Permite editar todos los campos (incluyendo contraseña y cédula), cambiar rol inline, crear nuevos usuarios de cualquier rol, y eliminar.
- **Organizaciones** — listado con RUC, representante y cantidad de eventos. Permite editar la organización y los datos del representante (incluyendo credenciales), crear nuevas, y eliminar.
- **Eventos** — listado con organización, fecha y estado. Permite editar, crear y eliminar.
- **Inscripciones** — listado con voluntario, evento, estado, hora de check-in y coordenadas GPS. Permite eliminar.

---

## Estructura de directorios relevante

```
app/
├── controllers/
│   ├── admin/
│   │   ├── base_controller.rb        # Requiere rol admin
│   │   ├── dashboard_controller.rb   # Panel principal + acciones de destroy
│   │   ├── users_controller.rb       # CRUD de usuarios desde el admin
│   │   └── organizations_controller.rb
│   ├── users/
│   │   └── registrations_controller.rb  # Registro dual voluntario/organización
│   ├── enrollments_controller.rb     # Inscripción, cancelación y check-in
│   └── messages_controller.rb        # Creación de mensajes de chat
├── models/
│   ├── concerns/
│   │   └── ecuador_validations.rb    # Algoritmos cédula y RUC
│   ├── user.rb
│   ├── organization.rb
│   ├── event.rb
│   ├── enrollment.rb
│   ├── message.rb
│   └── notification.rb
├── policies/                         # Pundit: reglas de autorización
│   ├── event_policy.rb
│   ├── organization_policy.rb
│   └── enrollment_policy.rb
├── services/
│   └── notification_service.rb       # Lógica de creación de notificaciones
├── javascript/
│   └── controllers/
│       ├── check_in_controller.js    # Geolocalización
│       ├── tabs_controller.js        # Tabs genérico (dashboard, etc.)
│       └── registration_tabs_controller.js
└── views/
    ├── admin/
    ├── events/
    ├── notifications/
    └── devise/registrations/
```
