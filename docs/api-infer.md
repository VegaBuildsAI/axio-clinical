# Contrato API — `POST /axio-clinical-agent/infer`

Contrato entre el **Motor Clínico** y los clientes del agente (Vega / web demo). El endpoint del
motor recibe un `InferRequest` y devuelve un `InferResponse` plano. La UI no consume esa forma
directamente: un adaptador la convierte a su modelo de diálogo.

## Endpoint

`POST /axio-clinical-agent/infer` (interno del motor: `POST /infer`)

### Request — `InferRequest`

```json
{
  "member_token": "ax_demo-001",
  "text": "Me duele un poco la cabeza desde la mañana",
  "channel": "web",
  "conversation_id": "conv-demo-001",
  "locale": "es-CR",
  "metadata": { "surface": "axio-clinical-agent-web-demo" }
}
```

| Campo | Tipo | Reglas |
|---|---|---|
| `member_token` | `string` | Seudónimo del miembro; **nunca PHI cruda** (`ax_<id>`). |
| `text` | `string` | Texto del turno enviado por la persona usuaria. |
| `channel` | `"whatsapp" \| "app" \| "web" \| "sms" \| "voz"` | Canal de entrada. Default: `app`. |
| `conversation_id` | `string \| null` | Conversación existente; si falta, el motor la genera. |
| `locale` | `string` | Locale de respuesta. Default: `es-CR`. |
| `metadata` | `object` | Datos técnicos **no clínicos** para trazabilidad. |

### Response — `InferResponse`

```json
{
  "reply": "Puede ser información general si el dolor es leve. Si empeora, aparece fiebre alta, rigidez de cuello, confusión, debilidad, dificultad para hablar o dolor intenso repentino, buscaría atención inmediata.",
  "risk_level": "N1",
  "escalated": false,
  "route": "local",
  "intent": "general",
  "actions": [
    { "label": "Quiero monitorearlo", "action_id": "monitor_headache", "kind": "quick_reply" },
    { "label": "Hablar con equipo clínico", "action_id": "clinical_team", "kind": "escalation" }
  ],
  "tools_used": ["local_llm"],
  "citations": [],
  "disclaimers": ["Información general; confirma con tu médico. No reemplazo una consulta."],
  "conversation_id": "conv-demo-001",
  "served_at": "2026-07-10T18:30:00+00:00"
}
```

| Campo | Tipo | Reglas |
|---|---|---|
| `reply` | `string` | Texto principal que el agente muestra. |
| `risk_level` | `"N0" \| "N1" \| "N2" \| "N3"` | Nivel de riesgo canónico para UI y badges. |
| `escalated` | `boolean` | `true` si se activó escalación o el caso entra a flujo humano. |
| `route` | `"crisis" \| "local" \| "cloud"` | Ruta de procesamiento usada por el motor. |
| `intent` | `string` | Intención detectada (trazabilidad/analítica). |
| `actions` | `SuggestedAction[]` | Siguientes acciones sugeridas. |
| `tools_used` | `string[]` | Herramientas/fuentes ejecutadas en el turno. |
| `citations` | `string[]` | Referencias SoR/KB que sostienen la respuesta. |
| `disclaimers` | `string[]` | Advertencias de seguridad para mostrar/registrar. |
| `conversation_id` | `string \| null` | Id de conversación vigente. |
| `served_at` | `string` | Timestamp ISO-8601 del servidor. |

`SuggestedAction`:

| Campo | Tipo | Reglas |
|---|---|---|
| `label` | `string` | Texto visible para la persona usuaria. |
| `action_id` | `string` | Identificador estable que consume el adaptador/UI. |
| `kind` | `"quick_reply" \| "link" \| "escalation"` | Default: `quick_reply`. |

## Guardrails N0–N3

| Nivel | Uso | Regla |
|---|---|---|
| `N0` | Informativo/administrativo | Beneficios, citas, membresía o info general sin riesgo clínico. **No diagnostica.** |
| `N1` | Preventivo/no urgente | Orientación y autocuidado seguro. Incluir disclaimer si hay contenido de salud. |
| `N2` | Monitoreo/criterio clínico | Recomienda seguimiento clínico; valida contra SoR/KB; evita afirmaciones sin soporte. |
| `N3` | **Escalación/crisis** | Bandera roja: escala y notifica **<2 min**. La UI usa estilo `escalation`. **Corta antes del LLM.** |

## Nota de adaptación (cliente)

El cliente (web/Vega) adapta `InferResponse` a su modelo de diálogo: crea el mensaje principal desde
`reply`, copia `risk_level` al badge, mapea `actions[]` (quick_reply → quick replies; escalation →
CTA clínico), y ante `escalated: true` o `N3` aplica el estado de bandera roja. `citations[]` y
`tools_used[]` son metadata/debug — **no** se muestran como texto principal al paciente.
