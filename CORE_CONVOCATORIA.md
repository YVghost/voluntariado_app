# Core del Sistema de Convocatoria de Voluntarios

Explicación técnica completa del ciclo: formulario de habilidades → cálculo de score → matching → convocatoria → calificación → actualización del score.

---

## Fase 1 — El formulario de habilidades (Quiz)

**Vista:** [quiz/show.html.erb](app/views/quiz/show.html.erb) · **Controlador:** [quiz_controller.rb](app/controllers/quiz_controller.rb)

El voluntario completa el quiz **una única vez**. Una vez enviado se bloquea permanentemente — la vista pasa a modo lectura y el único camino de evolución del score son las calificaciones reales. La condición que bifurca entre formulario y lectura está en [show.html.erb:3](app/views/quiz/show.html.erb#L3) (`if @profile.quiz_completed_at.present?`).

### Estructura del formulario

El formulario tiene 25 preguntas divididas en 5 secciones de 5 preguntas cada una. Cada pregunta se responde con un radio button de 0 a 4:

| Valor | Significado |
|-------|-------------|
| 0 | Nunca / Sin experiencia |
| 1 | Algo / Conocimiento básico |
| 2 | Con práctica / Competente |
| 3 | Con experiencia / Avanzado |
| 4 | Experto / Formación formal |

Las 5 secciones con todas sus preguntas están definidas en [show.html.erb:122-159](app/views/quiz/show.html.erb#L122-L159) como el array `skill_sections`. Los radio buttons se renderizan en [show.html.erb:162-185](app/views/quiz/show.html.erb#L162-L185).

| Sección | Keys | Preguntas sobre |
|---------|------|-----------------|
| Primeros Auxilios | q1–q5 | RCP, hemorragias, fracturas, quemaduras, shock |
| Búsqueda y Rescate | q6–q10 | Espacios confinados, cuerdas/altura, orientación, extracción de escombros, planos |
| Apoyo Psicosocial | q11–q15 | Crisis emocional, PAP, calma colectiva, niños/adultos mayores, señales de trauma |
| Logística y Abastecimiento | q16–q20 | Distribución de recursos, albergues, inventario, conducción, coordinación |
| Maquinaria / Construcción | q21–q25 | Maquinaria pesada, estructuras, motosierra/generador, escombros, instalaciones |

Además el formulario incluye:
- **Certificaciones** — 8 checkboxes en [show.html.erb:186-206](app/views/quiz/show.html.erb#L186-L206). Los bonus posibles están definidos en [volunteer_profile.rb:20-29](app/models/volunteer_profile.rb#L20-L29).
- **Ubicación** — selector en cascada País → Ciudad → Sector en [show.html.erb:208-248](app/views/quiz/show.html.erb#L208-L248). Se guarda en `country`, `city`, `sector` del perfil.

Al enviar, el controlador guarda `quiz_answers` (jsonb), `certifications` (jsonb), `country/city/sector`, y llama `profile.calculate_score!`.

---

## Fase 2 — Cálculo del score inicial

**Método:** [volunteer_profile.rb:56-100](app/models/volunteer_profile.rb#L56-L100) → `calculate_score!`

### Paso 1 — Score por habilidad (escala 0–4)

El mapeo sección → preguntas está en [volunteer_profile.rb:59-65](app/models/volunteer_profile.rb#L59-L65). Para cada sección ([volunteer_profile.rb:71-77](app/models/volunteer_profile.rb#L71-L77)):

```
pct          = suma_respuestas / (5 × 4)    # proporción 0.0–1.0
skill_score  = pct × 4                      # escala 0–4, redondeado a 2 decimales
```

Una habilidad queda **activa** si `pct ≥ 0.25` (equivale a un `skill_score ≥ 1.0`) — línea [volunteer_profile.rb:77](app/models/volunteer_profile.rb#L77).

### Paso 2 — Score global ponderado (escala 0–10)

Los pesos por habilidad están en [volunteer_profile.rb:31-37](app/models/volunteer_profile.rb#L31-L37):

| Habilidad | Peso |
|-----------|------|
| Primeros Auxilios | 1.2 |
| Búsqueda y Rescate | 1.5 ← mayor |
| Apoyo Psicosocial | 0.8 |
| Logística y Abastecimiento | 0.9 |
| Maquinaria / Construcción | 1.3 |

La fórmula aplicada en [volunteer_profile.rb:80-82](app/models/volunteer_profile.rb#L80-L82):

```
base_score = (Σ (pct_sección × peso) / Σ pesos) × 10
```

### Paso 3 — Bonus por certificaciones

Definición de puntos en [volunteer_profile.rb:20-29](app/models/volunteer_profile.rb#L20-L29). Aplicación en [volunteer_profile.rb:84-87](app/models/volunteer_profile.rb#L84-L87):

| Certificación | Bonus |
|---------------|-------|
| Primeros Auxilios (Cruz Roja / Defensa Civil) | +1.0 |
| Rescate en espacios confinados o altura | +1.5 |
| Primeros Auxilios Psicológicos (PAP) | +1.0 |
| Licencia de conducción tipo C o D | +0.5 |
| Operador de maquinaria pesada | +2.0 |
| Técnico / ingeniero civil o construcción | +1.5 |
| Técnico en enfermería o paramédico | +2.0 |
| Bombero voluntario formado | +2.0 |

```
final_score = min(base_score + cert_bonus, 10.0)
```

### Resultado guardado

`update!` en [volunteer_profile.rb:94-99](app/models/volunteer_profile.rb#L94-L99) escribe:
- `score` — score global 0–10
- `skill_scores` — jsonb con el score 0–4 de cada habilidad
- `skills` — array de habilidades activas (aquellas con pct ≥ 0.25)
- `quiz_completed_at` — timestamp del momento en que se completó

---

## Fase 3 — Creación de una emergencia y disparo del matching

**Callback:** [event.rb:45](app/models/event.rb#L45) → `after_create_commit :run_matching_if_emergency`

**Método:** [event.rb:75-77](app/models/event.rb#L75-L77)

```ruby
def run_matching_if_emergency
  VolunteerMatchingService.new(self).call if emergency_level.present?
end
```

Cuando se crea un evento con `emergency_level` (1–6), el callback dispara el matching **síncronamente**. No se vuelve a correr si el evento se edita. Los campos del evento relevantes para el matching están en [event.rb:1-28](app/models/event.rb#L1-L28):
- `emergency_level` (integer 1–6)
- `emergency_type` (string)
- `required_skills` (string[] PostgreSQL)
- `location` (string "País, Ciudad, Sector")
- `date` (datetime)

---

## Fase 4 — El matching: quién se convoca

**Servicio:** [volunteer_matching_service.rb](app/services/volunteer_matching_service.rb)

### 4.1 Pool de candidatos

Método `candidate_profiles` en [volunteer_matching_service.rb:46-51](app/services/volunteer_matching_service.rb#L46-L51):

```ruby
VolunteerProfile
  .includes(:user)
  .where(available: true)
  .where.not(quiz_completed_at: nil)
```

No hay filtro geográfico — cualquier voluntario disponible del mundo entra al análisis. La geografía solo importa al resolver conflictos.

### 4.2 Clasificación por tier

**Método:** [volunteer_profile.rb:167-179](app/models/volunteer_profile.rb#L167-L179) → `tier_for_event(event)`

Para cada candidato se evalúa en qué categoría cae para *este* evento específico.

**Si el evento tiene `required_skills`** — método privado `skill_tier_for` en [volunteer_profile.rb:261-279](app/models/volunteer_profile.rb#L261-L279):

Se comparan los `skill_scores` del voluntario contra las tablas de umbrales definidas en [volunteer_profile.rb:40-41](app/models/volunteer_profile.rb#L40-L41):

| Nivel | Inmediato (≥) | Apoyo (≥) |
|-------|:------------:|:---------:|
| T1 — Leve | 1.5 | 0.5 |
| T2 — Moderada | 2.0 | 1.0 |
| T3 — Media | 2.5 | 1.5 |
| T4 — Alta | 3.0 | 2.0 |
| T5 — Crítica | 3.2 | 2.5 |
| T6 — Catástrofe | 3.5 | 3.0 |

Regla:
- `:immediate` → **TODAS** las habilidades requeridas superan el umbral inmediato
- `:support` → **AL MENOS UNA** habilidad requerida supera el umbral de apoyo
- `nil` → ninguna alcanza ni el mínimo → excluido

**Si el evento no tiene `required_skills` (fallback)** — método privado `global_tier_for` en [volunteer_profile.rb:281-289](app/models/volunteer_profile.rb#L281-L289):

Se compara el `score` global contra las tablas definidas en [volunteer_profile.rb:44-45](app/models/volunteer_profile.rb#L44-L45):

| Nivel | Inmediato (≥) | Apoyo (≥) |
|-------|:------------:|:---------:|
| T1 | 4.0 | 2.0 |
| T2 | 5.0 | 3.0 |
| T3 | 5.5 | 4.0 |
| T4 | 6.5 | 5.0 |
| T5 | 7.0 | 6.0 |
| T6 | 8.0 | 7.0 |

### 4.3 Resolución de conflictos

Si `busy_in_active_emergency?` ([volunteer_profile.rb:186-194](app/models/volunteer_profile.rb#L186-L194)) devuelve `true`, se llama a `conflict_resolution_for(new_event)` ([volunteer_profile.rb:205-241](app/models/volunteer_profile.rb#L205-L241)).

El bucle del servicio que maneja esto está en [volunteer_matching_service.rb:19-36](app/services/volunteer_matching_service.rb#L19-L36).

Se ejecutan 3 comparaciones en orden:

**Comparación 1 — País** ([volunteer_profile.rb:222-228](app/models/volunteer_profile.rb#L222-L228)):
```
Si país del voluntario ≠ país del nuevo evento → :second_wave
```
El voluntario está en otro país; se lo convoca como segunda ola con llegada estimada en 7 días ([volunteer_profile.rb:50](app/models/volunteer_profile.rb#L50) — `SECOND_WAVE_DAYS = 7`).

**Comparación 2 — Cruce de tiempos** ([volunteer_profile.rb:230](app/models/volunteer_profile.rb#L230)):

Método privado `times_overlap?` en [volunteer_profile.rb:291-303](app/models/volunteer_profile.rb#L291-L303). Usa duraciones estimadas de [volunteer_profile.rb:47-48](app/models/volunteer_profile.rb#L47-L48):

| Nivel | Duración estimada |
|-------|:-----------------:|
| T1 | 4 horas |
| T2 | 6 horas |
| T3 | 12 horas |
| T4 | 24 horas |
| T5 | 48 horas |
| T6 | 72 horas |

```
Si los rangos [inicio_A, inicio_A + duración_A] y [inicio_B, inicio_B + duración_B] NO se superponen
  → :convoke   (puede atender ambas)
Si se superponen → pasa a comparación 3
```

**Comparación 3 — Prioridad por nivel** ([volunteer_profile.rb:232-239](app/models/volunteer_profile.rb#L232-L239)):

```
level_diff = nuevo.emergency_level - actual.emergency_level

Si level_diff ≥ 2 → :convoke_conflict  (la nueva es significativamente más urgente)
Si level_diff == 1 → :convoke_conflict  (la nueva tiene algo más de prioridad)
Si level_diff ≤ 0 → :skip              (la actual tiene igual o mayor prioridad)
```

### 4.4 Creación de inscripciones

Ordenamiento y límites en [volunteer_matching_service.rb:40-41](app/services/volunteer_matching_service.rb#L40-L41). Método `convoke!` en [volunteer_matching_service.rb:53-69](app/services/volunteer_matching_service.rb#L53-L69). Segunda ola en [volunteer_matching_service.rb:71-83](app/services/volunteer_matching_service.rb#L71-L83):

```
immediate.sort_by(-score).first(20) → Enrollment(status: :convocado)
support.sort_by(-score).first(50)   → Enrollment(status: :convocado)
segunda_ola                         → Enrollment(status: :convocado, second_wave: true, expected_arrival: 7.days)
convoke_conflict                    → Enrollment(status: :convocado) + notificación especial
```

El `before_create` en [enrollment.rb:13](app/models/enrollment.rb#L13) dispara `snapshot_volunteer_score` ([enrollment.rb:18-20](app/models/enrollment.rb#L18-L20)) que guarda el score actual en `score_snapshot`.

### 4.5 Notificaciones al convocar

[notification_service.rb](app/services/notification_service.rb) — métodos según el caso:
- Convocatoria normal → `voluntario_convocado(enrollment)`
- Con conflicto → `convocado_con_conflicto(enrollment, message)`
- Segunda ola → `segunda_ola(enrollment, message)`

---

## Fase 5 — Ciclo de vida de la inscripción

Enum definido en [enrollment.rb:7](app/models/enrollment.rb#L7):

```
convocado → [voluntario confirma en EnrollmentsController#update] → confirmado
confirmado → [organizador marca asistencia en EnrollmentsController#mark_attendance] → asistio
```

Solo voluntarios con status `asistio` aparecen en el formulario de calificación ([_show_finalizado.html.erb:4](app/views/events/_show_finalizado.html.erb#L4)).

---

## Fase 6 — Finalización de la emergencia

[events_controller.rb](app/controllers/events_controller.rb) → acción `finalizar` — pasa status de `en_curso` a `finalizado`.

Callback en [event.rb:44](app/models/event.rb#L44) → `notify_volunteers_if_finalizado` ([event.rb:57-59](app/models/event.rb#L57-L59)) notifica a todos los inscritos activos.

---

## Fase 7 — Calificación de voluntarios

**Vista:** [_show_finalizado.html.erb](app/views/events/_show_finalizado.html.erb) · **Controlador:** [event_reviews_controller.rb](app/controllers/event_reviews_controller.rb)

La lista de asistentes se carga en [_show_finalizado.html.erb:4](app/views/events/_show_finalizado.html.erb#L4). El formulario por voluntario está en [_show_finalizado.html.erb:103-155](app/views/events/_show_finalizado.html.erb#L103-L155). Las 5 habilidades a calificar vienen de [enrollment_review.rb:6-11](app/models/enrollment_review.rb#L6-L11) (`SKILL_ATTRS`).

Escala de la review:

| Valor | Significado |
|-------|-------------|
| 0 | No aplicó |
| 1 | Básico |
| 2 | Moderado |
| 3 | Avanzado |
| 4 | Experto |

Unicidad: un voluntario solo puede ser calificado una vez por revisor ([enrollment_review.rb:21](app/models/enrollment_review.rb#L21)).

---

## Fase 8 — Actualización del score al calificar

**Callback:** [enrollment_review.rb:24](app/models/enrollment_review.rb#L24) → `after_save :update_volunteer_skills`

**Método disparador:** [enrollment_review.rb:28-30](app/models/enrollment_review.rb#L28-L30) llama `volunteer_profile.update_skills_from_reviews!`

**Método principal:** [volunteer_profile.rb:106-160](app/models/volunteer_profile.rb#L106-L160) → `update_skills_from_reviews!`

### El algoritmo de recálculo paso a paso

**Paso 1 — Recalcular el quiz desde `quiz_answers` originales** ([volunteer_profile.rb:112-125](app/models/volunteer_profile.rb#L112-L125)):

```ruby
# Nunca desde skill_scores almacenado — evita compounding
quiz_raw[skill] = (suma_respuestas / max_posible) × 4   # escala 0–4
```

**Paso 2 — Promediar TODAS las reviews por habilidad, incluye ceros** ([volunteer_profile.rb:128-133](app/models/volunteer_profile.rb#L128-L133)):

```ruby
# El 0 ("No aplicó") es un dato real y entra en el promedio
review_avgs[skill] = suma_de_todos_los_scores / cantidad_de_reviews
```

**Paso 3 — Mezcla ponderada** ([volunteer_profile.rb:138-141](app/models/volunteer_profile.rb#L138-L141)):

```ruby
merged[skill] = (quiz_raw[skill] × 0.4) + (review_avgs[skill] × 0.6)
```

60/40 a favor del campo — lo demostrado en campo pesa más que lo autodeclarado en el quiz.

**Paso 4 — Score global recalculado** ([volunteer_profile.rb:147-149](app/models/volunteer_profile.rb#L147-L149)):

```ruby
weighted   = merged.sum { |skill, val| (val / 4.0) × LEVEL_WEIGHTS[skill] }
base_score = (weighted / weight_sum) × 10.0
```

**Paso 5 — Bonus de certificaciones proporcional, tope 2.0** ([volunteer_profile.rb:152-155](app/models/volunteer_profile.rb#L152-L155)):

```ruby
raw_cert   = suma de puntos de las certs marcadas
max_cert   = 11.5 (suma de todas las certs posibles)
cert_bonus = (raw_cert / max_cert) × 2.0   # máximo 2.0 puntos
```

> **Por qué el tope de 2.0:** sin él, tener todas las certificaciones sumaría 11.5 pts y llevaría cualquier score a 10 independientemente del desempeño real. El tope preserva que el trabajo de campo sea el factor dominante.

**Escritura final** ([volunteer_profile.rb:157-159](app/models/volunteer_profile.rb#L157-L159)) con `update_columns` (no dispara callbacks adicionales):

```ruby
new_score = min(base_score + cert_bonus, 10.0)
# Actualiza: score, skill_scores, skills
```

Habilidades activas post-review: aquellas con `merged_score ≥ 1.0` ([volunteer_profile.rb:144](app/models/volunteer_profile.rb#L144)).

---

## Diagrama del flujo completo

```
[show.html.erb:111] Voluntario llena quiz (25 preguntas + certs + ubicación)
           │
           ▼
    [volunteer_profile.rb:56] calculate_score!
    ├── skill_scores[5]  → [volunteer_profile.rb:71-77]
    ├── skills[]         → [volunteer_profile.rb:77]
    └── score 0–10       → [volunteer_profile.rb:80-87]
           │
           │     Organizador crea evento con emergency_level
           ▼
    [event.rb:45] after_create_commit
    [event.rb:75] → VolunteerMatchingService.call
           │
    [volunteer_matching_service.rb:46] candidate_profiles (available + quiz)
           │
    [volunteer_matching_service.rb:15] Por cada perfil: tier_for_event
           │     [volunteer_profile.rb:174] Si required_skills → skill_tier_for
           │                                [volunteer_profile.rb:261]
           │     [volunteer_profile.rb:177] Si no → global_tier_for
           │                               [volunteer_profile.rb:281]
           │
    [volunteer_matching_service.rb:19] Si busy_in_active_emergency?
           │     [volunteer_profile.rb:224] País diferente → :second_wave
           │     [volunteer_profile.rb:230] Sin cruce → :convoke
           │     [volunteer_profile.rb:234] Con cruce + prioridad mayor → :convoke_conflict
           │     [volunteer_profile.rb:238] Con cruce + igual/menor → :skip
           │
    [volunteer_matching_service.rb:40-41]
    ├── Top 20 :immediate → Enrollment(convocado)
    └── Top 50 :support   → Enrollment(convocado)
                  │
    [enrollment.rb:13] before_create → snapshot_volunteer_score
    [enrollment.rb:18] score_snapshot = profile.score
                  │
    [notification_service.rb] NotificationService envía notificación
                  │
                  ├── Voluntario confirma → status: confirmado
                  ├── Organizador inicia → evento: en_curso
                  ├── Organizador marca asistencia → enrollment: asistio
                  └── Organizador finaliza → evento: finalizado
                              │
    [event.rb:44] after_update_commit → notify_volunteers_if_finalizado
                              │
    [_show_finalizado.html.erb:103] Formulario calificación (por cada asistio)
    [enrollment_review.rb:21] EnrollmentReview(5 skills 0–4 + comment)
                              │
    [enrollment_review.rb:24] after_save → update_volunteer_skills
    [volunteer_profile.rb:106] → update_skills_from_reviews!
                  ├── [L112] quiz_raw desde quiz_answers originales
                  ├── [L128] review_avgs (todas las reviews, incluye 0)
                  ├── [L138] merged = quiz × 0.4 + reviews × 0.6
                  ├── [L147] base_score ponderado × 10
                  ├── [L152] cert_bonus proporcional, tope 2.0
                  └── [L157] update_columns(score, skill_scores, skills)
```

---

## Tabla resumen de archivos y líneas por fase

| Fase | Archivo | Líneas clave |
|------|---------|--------------|
| Preguntas del quiz | [quiz/show.html.erb](app/views/quiz/show.html.erb) | [L122-L159](app/views/quiz/show.html.erb#L122-L159) |
| Render del formulario | [quiz/show.html.erb](app/views/quiz/show.html.erb) | [L162-L185](app/views/quiz/show.html.erb#L162-L185) |
| Certificaciones (form) | [quiz/show.html.erb](app/views/quiz/show.html.erb) | [L186-L206](app/views/quiz/show.html.erb#L186-L206) |
| Definición de skills y pesos | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L4-L37](app/models/volunteer_profile.rb#L4-L37) |
| Tablas de umbrales | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L40-L48](app/models/volunteer_profile.rb#L40-L48) |
| Cálculo de score inicial | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L56-L100](app/models/volunteer_profile.rb#L56-L100) |
| Callback disparo matching | [event.rb](app/models/event.rb) | [L45](app/models/event.rb#L45), [L75-L77](app/models/event.rb#L75-L77) |
| Matching principal | [volunteer_matching_service.rb](app/services/volunteer_matching_service.rb) | [L9-L42](app/services/volunteer_matching_service.rb#L9-L42) |
| Candidatos disponibles | [volunteer_matching_service.rb](app/services/volunteer_matching_service.rb) | [L46-L51](app/services/volunteer_matching_service.rb#L46-L51) |
| Clasificación por tier | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L167-L179](app/models/volunteer_profile.rb#L167-L179) |
| Tier por skill_scores | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L261-L279](app/models/volunteer_profile.rb#L261-L279) |
| Tier por score global | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L281-L289](app/models/volunteer_profile.rb#L281-L289) |
| Check voluntario ocupado | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L186-L194](app/models/volunteer_profile.rb#L186-L194) |
| Resolución de conflictos | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L205-L241](app/models/volunteer_profile.rb#L205-L241) |
| Cruce de tiempos | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L291-L303](app/models/volunteer_profile.rb#L291-L303) |
| Crear enrollment + snapshot | [enrollment.rb](app/models/enrollment.rb) | [L13](app/models/enrollment.rb#L13), [L18-L20](app/models/enrollment.rb#L18-L20) |
| Convocar voluntario | [volunteer_matching_service.rb](app/services/volunteer_matching_service.rb) | [L53-L69](app/services/volunteer_matching_service.rb#L53-L69) |
| Convocar segunda ola | [volunteer_matching_service.rb](app/services/volunteer_matching_service.rb) | [L71-L83](app/services/volunteer_matching_service.rb#L71-L83) |
| Notificaciones | [notification_service.rb](app/services/notification_service.rb) | — |
| Formulario de calificación | [_show_finalizado.html.erb](app/views/events/_show_finalizado.html.erb) | [L103-L155](app/views/events/_show_finalizado.html.erb#L103-L155) |
| Skills a calificar (SKILL_ATTRS) | [enrollment_review.rb](app/models/enrollment_review.rb) | [L6-L11](app/models/enrollment_review.rb#L6-L11) |
| Callback disparo recálculo | [enrollment_review.rb](app/models/enrollment_review.rb) | [L24](app/models/enrollment_review.rb#L24), [L28-L30](app/models/enrollment_review.rb#L28-L30) |
| Recálculo de score post-review | [volunteer_profile.rb](app/models/volunteer_profile.rb) | [L106-L160](app/models/volunteer_profile.rb#L106-L160) |
