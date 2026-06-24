# Plataforma de Coordinación de Voluntariado

Sistema web para la gestión y coordinación de emergencias en tiempo real. Permite a organizaciones publicar emergencias que requieran voluntarios especializados y coordinar la respuesta de forma automática según las habilidades, score y disponibilidad de cada voluntario.

---

## Idea general

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

## Requisitos previos

- Ruby 3.2+
- PostgreSQL 14+

---

## Instalación

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

## Validaciones ecuatorianas

El concern `EcuadorValidations` (`app/models/concerns/ecuador_validations.rb`) implementa:

- **Cédula** — 10 dígitos, provincia 01–24, tercer dígito < 6, checksum módulo 10 del Registro Civil.
- **RUC** — 13 dígitos con tres casos según tercer dígito (0–5: persona natural, 6: entidad pública, 9: sociedad privada).

---

## Sistema de convocatoria automática

Ver **`SISTEMA_CONVOCATORIA.md`** para la documentación completa del matching, cálculo de scores y calificaciones.

Resumen:
- Score 0–10 calculado desde cuestionario de 25 preguntas en 5 habilidades
- Matching automático al crear una emergencia: convoca inmediatos (top 20) y apoyo (top 50)
- Resolución de conflictos: 3 comparaciones (país → tiempo → prioridad)
- Score evoluciona con las calificaciones post-evento (40% quiz original + 60% reviews)

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

Las notificaciones son persistentes (`notifications` table) y se entregan vía Turbo Streams al navbar de cada usuario. Tipos:

| Trigger | Destinatario |
|---|---|
| Voluntario convocado a emergencia | El voluntario |
| Convocado con conflicto de prioridad | El voluntario (con contexto del conflicto) |
| Segunda ola (otro país) | El voluntario (con fecha estimada de llegada) |
| Evento finalizado | Todos los inscritos no cancelados |
| Inscripción confirmada | El voluntario |

---

## Panel de administración

`/admin/dashboard` — solo para `admin`.

Cuatro pestañas:
- **Usuarios** — CRUD completo con cambio de rol inline
- **Organizaciones** — crea/edita org + representante en un solo formulario transaccional
- **Eventos** — lista con estado, organización e inscritos; crear desde contexto admin redirige de vuelta al dashboard
- **Inscripciones** — lista con estado, asistencia y eliminación

---

## Documentación técnica adicional

- `SISTEMA_CONVOCATORIA.md` — scoring, matching, resolución de conflictos, tablas de umbrales
- `ARQUITECTURA.md` — mapa completo de modelos, controladores, vistas, rutas, servicios y políticas
