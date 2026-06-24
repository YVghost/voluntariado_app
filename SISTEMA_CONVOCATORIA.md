# Sistema de Calificación y Convocatoria de Voluntarios

> Versión actualizada — refleja el estado actual del código en `app/models/volunteer_profile.rb`,
> `app/services/volunteer_matching_service.rb` y `app/services/emergency_conflict_resolver.rb`.

---

## 1. Calificación del voluntario

### 1.1 Cuestionario inicial (único e irrepetible)

Cada voluntario completa **una sola vez** un cuestionario de 25 preguntas divididas en 5 secciones. Una vez enviado, el formulario se bloquea permanentemente — el score evoluciona solo a través del historial real de participación.

Escala de respuesta:

| Valor | Significado |
|-------|-------------|
| 0 | Nunca / Sin experiencia |
| 1 | Algo / Conocimiento básico |
| 2 | Con práctica / Competente |
| 3 | Con experiencia / Avanzado |
| 4 | Experto / Formación formal |

### 1.2 Secciones y pesos

| Sección | Preguntas | Peso en score global |
|---------|-----------|---------------------|
| Primeros Auxilios | q1–q5 | 1.2 |
| Búsqueda y Rescate | q6–q10 | 1.5 ← mayor peso |
| Apoyo Psicosocial | q11–q15 | 0.8 |
| Logística y Abastecimiento | q16–q20 | 0.9 |
| Maquinaria / Construcción | q21–q25 | 1.3 |

### 1.3 Score por habilidad (escala 0–4)

```
score_habilidad = (suma de las 5 respuestas / 20) × 4
```

Una habilidad queda **activa** si `score_habilidad ≥ 1.0`.

### 1.4 Score global al completar el quiz (escala 0–10)

```
base = (Σ (score_habilidad/4 × peso_sección) / Σ pesos) × 10
score = min(base + cert_bonus, 10.0)
```

Implementado en `VolunteerProfile#calculate_score!`.

### 1.5 Bonus por certificaciones (al completar el quiz)

Las siguientes certificaciones suman puntos al score inicial:

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

### 1.6 Evolución del score después del quiz (por reviews)

Cada vez que un organizador califica a un voluntario que asistió, `EnrollmentReview#after_save` dispara `VolunteerProfile#update_skills_from_reviews!`.

**Reglas del recálculo:**

1. Se recalcula `quiz_raw` **desde `quiz_answers` originales** (nunca desde `skill_scores` almacenado — evita compounding).
2. Se promedian TODAS las calificaciones recibidas, **incluyendo ceros** (0 = "No aplicó" pero cuenta como dato real).
3. Mezcla por habilidad: `merged = quiz_raw × 0.4 + review_avg × 0.6`
4. Score global: mismo fórmula ponderada × 10
5. Bonus de certificaciones **proporcional y con tope de 2.0 puntos**: `(certs_obtenidas / max_posible) × 2.0`

```
score_actualizado = min(score_from_merged_skills + cert_bonus_proporcional, 10.0)
```

**Por qué el tope de 2.0 en certs:** sin este tope, acumular todas las certificaciones agrega 11.5 puntos extra, lo que satura el score a 10 independientemente del desempeño real en campo.

### 1.7 Snapshot del score en cada inscripción

Al momento de inscribirse (o ser convocado), el sistema guarda `enrollment.score_snapshot` con el score del voluntario en ese instante. Esto permite mostrar en el perfil cuánto tenía antes y cuánto tiene ahora después de ser calificado.

---

## 2. Ciclo de vida de un evento

Los estados avanzan de forma **manual** (organización) o **automática** (sistema):

```
activo
  │
  ├──[organizador pulsa "Iniciar"]──► en_curso
  │                                       │
  │                                       ├──[organizador pulsa "Finalizar"]──► finalizado
  │                                       │                                          │
  │                                       │                              [calificación uno a uno]
  │
  └──[3 días pasan sin iniciarlo]──► cancelado (automático, sin afectar scores)
```

| Estado | Color en UI | Descripción |
|--------|-------------|-------------|
| `activo` | Verde | Convocando — acepta inscripciones y matching automático |
| `en_curso` | Amber | El organizador inició el evento — toma lista de asistencia |
| `finalizado` | Gris | Evento terminado — habilita calificación de asistentes |
| `cancelado` | Rojo | Nunca se inició — sin impacto en ningún voluntario |

La auto-cancelación corre en `Event.auto_cancelar_no_iniciados!`, llamado en cada carga de `events#index` y `events#show`.

---

## 3. Proceso de convocatoria automática

### 3.1 Disparador

`Event` tiene `after_create_commit :run_matching_if_emergency`. Se ejecuta **síncronamente** al crear un evento con `emergency_level` presente. No se vuelve a ejecutar al editar.

### 3.2 Filtros de candidatos

El servicio `VolunteerMatchingService` obtiene perfiles que cumplan:
- `available = true`
- `quiz_completed_at` no nulo (perfil completo)

No hay filtro por ciudad ni país — cualquier voluntario del mundo puede ser convocado.

### 3.3 Clasificación por tier

Para cada candidato se llama `VolunteerProfile#tier_for_event(event)`:

**Si el evento tiene `required_skills`:** se compara `skill_scores[skill]` contra los umbrales de la sección 4.
- `:immediate` → TODAS las habilidades requeridas ≥ umbral inmediato
- `:support` → AL MENOS UNA habilidad requerida ≥ umbral apoyo
- `nil` → ninguna alcanza el mínimo de apoyo → bloqueado

**Si no hay `required_skills` (fallback):** se compara el score global contra los umbrales de la sección 4.2. Si `skill_scores` está vacío, también cae a este fallback.

### 3.4 Resolución de conflictos

Si el candidato ya está activo (convocado/confirmado) en otra emergencia vigente, `VolunteerProfile#conflict_resolution_for(new_event)` ejecuta 3 comparaciones en orden:

**Comparación 1 — País:**
- País del voluntario ≠ país del nuevo evento → `:second_wave`
- Se crea enrollment con `second_wave: true`, `expected_arrival: 7.days.from_now`

**Comparación 2 — Cruce de tiempos:**

| Nivel | Duración estimada |
|-------|-----------------|
| T1 | 4 horas |
| T2 | 6 horas |
| T3 | 12 horas |
| T4 | 24 horas |
| T5 | 48 horas |
| T6 | 72 horas |

- Sin cruce → `:convoke` (puede atender ambas, no hay conflicto)
- Con cruce → pasa a comparación 3

**Comparación 3 — Prioridad:**

| Diferencia de nivel | Resultado |
|--------------------|-----------|
| Nueva ≥ 2 niveles mayor | `:convoke_conflict` — se convoca con notificación de conflicto |
| Nueva 1 nivel mayor | `:convoke_conflict` |
| Igual o menor | `:skip` — no se convoca |

### 3.5 Creación de inscripciones

- Top 20 inmediatos por score → `Enrollment` con `status: :convocado`
- Top 50 de apoyo por score → `Enrollment` con `status: :convocado`
- Segunda ola → `Enrollment` con `status: :convocado`, `second_wave: true`

### 3.6 Flujo de la inscripción

```
convocado → [voluntario confirma] → confirmado
confirmado → [organizador marca asistencia] → asistio
asistio → [organizador califica] → EnrollmentReview guardado → score recalculado
```

Solo voluntarios con status `asistio` aparecen en el formulario de calificación.

---

## 4. Tablas de umbrales

### 4.1 Por habilidad (escala 0–4)

| Nivel | Inmediato (≥) | Apoyo (≥) |
|-------|--------------|-----------|
| T1 — Leve | 1.5 | 0.5 |
| T2 — Moderada | 2.0 | 1.0 |
| T3 — Media | 2.5 | 1.5 |
| T4 — Alta | 3.0 | 2.0 |
| T5 — Crítica | 3.2 | 2.5 |
| T6 — Catástrofe | 3.5 | 3.0 |

### 4.2 Por score global (escala 0–10, fallback)

| Nivel | Inmediato (≥) | Apoyo (≥) |
|-------|--------------|-----------|
| T1 | 4.0 | 2.0 |
| T2 | 5.0 | 3.0 |
| T3 | 5.5 | 4.0 |
| T4 | 6.5 | 5.0 |
| T5 | 7.0 | 6.0 |
| T6 | 8.0 | 7.0 |

### 4.3 Habilidades prioritarias por tipo (referencia)

| Tipo | Habilidades |
|------|-------------|
| Accidente vial / doméstico (T1–T2) | Primeros Auxilios |
| Incendio / intoxicación (T2) | Primeros Auxilios, Logística |
| Evento masivo / inundación leve (T3) | Apoyo Psicosocial, Logística |
| Sismo / rescate múltiple (T4) | Búsqueda y Rescate, Primeros Auxilios |
| Deslave / colapso (T5) | Búsqueda y Rescate, Maquinaria |
| Terremoto / tsunami / erupción (T6) | Búsqueda y Rescate, Maquinaria, Primeros Auxilios, Logística |

---

## 5. Visibilidad según tier en la lista de eventos

| Estado | Fondo de card | Badge | Acción |
|--------|--------------|-------|--------|
| Ya convocado / confirmado | Amarillo `#fef3c7` | 🚨 Ya convocado (texto rojo) | Ver, confirmar |
| Tier `:immediate` sin inscripción | Verde `#dcfce7` | ✓ Podés inscribirte | Inscripción directa |
| Tier `:support` sin inscripción | Naranja `#ffedd5` | 🤝 Podés dar apoyo | Inscripción como apoyo |
| Tier `nil` (fuera de rango) | Gris `#f1f5f9` | Sin nivel requerido | Solo lectura |
| Evento normal (sin emergencia) | Blanco | — | Inscripción libre |
