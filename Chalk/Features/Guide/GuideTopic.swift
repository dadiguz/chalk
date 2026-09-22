import Foundation

/// Un tema fijo de la guía, con ícono y explicación.
struct GuideTopic: Identifiable {
    /// Clave estable, usada en los enlaces del glosario (`chalk-glossary://<key>`).
    let key: String
    let title: String
    let systemImage: String
    let body: String
    /// Palabras que, al aparecer en indicaciones o instrucciones, enlazan a este tema.
    var keywords: [String] = []

    var id: String { key }

    /// Cómo leer una rutina de fuerza.
    static let training: [GuideTopic] = [
        GuideTopic(key: "rir", title: "RIR · Repeticiones en reserva", systemImage: "battery.25percent",
                   body: "Cuántas repeticiones más podrías hacer al terminar la serie con buena técnica. RIR 0 es llegar al fallo; RIR 1 a 2 es parar cuando te quedan 1 o 2 repeticiones. Un rango \"1 a 2\" significa que elijas el peso para terminar en ese punto.",
                   keywords: ["RIR", "repeticiones en reserva", "al fallo"]),
        GuideTopic(key: "rpe", title: "RPE · Esfuerzo percibido", systemImage: "gauge.with.dots.needle.67percent",
                   body: "Escala del 1 al 10 de qué tan dura se sintió la serie. Es el espejo del RIR: RPE 10 ≈ RIR 0, RPE 9 ≈ RIR 1, RPE 8 ≈ RIR 2.",
                   keywords: ["RPE", "esfuerzo percibido"]),
        GuideTopic(key: "rom", title: "ROM · Rango de movimiento", systemImage: "arrow.up.and.down",
                   body: "El recorrido completo de la articulación en el ejercicio. \"ROM completo\" es bajar y subir todo lo que permite el movimiento sin rebotar ni recortar. \"Priorizar la elongación\" es controlar la parte donde el músculo se estira.",
                   keywords: ["ROM", "RON", "rango de movimiento", "recorrido completo"]),
        GuideTopic(key: "eccentric", title: "Fase excéntrica", systemImage: "tortoise",
                   body: "La parte del movimiento en la que el músculo se alarga mientras resiste el peso, normalmente al bajar. \"Excéntrica de 3 segundos\" es tardar 3 segundos en esa fase.",
                   keywords: ["fase excéntrica", "excéntrica"]),
        GuideTopic(key: "elongation", title: "Elongación", systemImage: "arrow.left.and.right",
                   body: "La posición en la que el músculo está más estirado (por ejemplo, abajo en un press inclinado o arriba en un jalón). \"Priorizar la elongación\" es bajar completo y controlado en esa parte, sin rebotar, porque ahí el músculo recibe mucho estímulo.",
                   keywords: ["elongación"]),
        GuideTopic(key: "contraction", title: "Contracción", systemImage: "arrow.right.and.line.vertical.and.arrow.left",
                   body: "La posición en la que el músculo está más corto y apretado. \"1 seg de contracción\" es pausar un segundo en ese punto apretando el músculo antes de regresar.",
                   keywords: ["contracción"]),
        GuideTopic(key: "myoreps", title: "MYOreps", systemImage: "repeat",
                   body: "Técnica para la última serie: haz la serie cerca del fallo, descansa 3 a 5 respiraciones profundas y haz mini series de 3 a 5 repeticiones con el mismo peso, hasta que ya no salgan.",
                   keywords: ["MYOreps", "myo reps", "myo-reps"]),
        GuideTopic(key: "dropset", title: "Dropset", systemImage: "arrow.down.right",
                   body: "Al terminar la serie, baja el peso entre 20 y 30% sin descansar y sigue hasta cerca del fallo. Se hace normalmente solo en la última serie.",
                   keywords: ["dropset", "drop set"]),
        GuideTopic(key: "warmup-sets", title: "Series de aproximación", systemImage: "stairs",
                   body: "Series ligeras antes del primer ejercicio para calentar, subiendo la carga poco a poco hasta acercarte al peso de trabajo. No se registran como series.",
                   keywords: ["series de aproximación", "aproximación"]),
        GuideTopic(key: "rest", title: "Descanso", systemImage: "timer",
                   body: "Tiempo entre series del mismo ejercicio. Respetarlo ayuda a rendir igual en cada serie.",
                   keywords: ["descanso"]),
    ]

    /// Cómo funciona Chalk.
    static let app: [GuideTopic] = [
        GuideTopic(key: "app-marking", title: "Marcar ejercicios", systemImage: "checkmark.square",
                   body: "✓ es hecho y ✕ es que no lo hiciste. Tocar de nuevo el botón activo lo regresa a pendiente. Los botones junto al nombre del día marcan todos sus ejercicios a la vez."),
        GuideTopic(key: "app-streak", title: "Racha", systemImage: "flame",
                   body: "Suma un día cada vez que registras al menos un ejercicio hecho. Los días libres no la rompen; un día de rutina sin nada hecho, sí. Hoy no la rompe mientras el día siga en curso."),
        GuideTopic(key: "app-makeup", title: "Reponer un día", systemImage: "arrow.triangle.2.circlepath",
                   body: "Si faltaste un día de rutina, ve a un día libre (por ejemplo el sábado) y toca \"Reponer un día\". Arriba aparecen los días que no hiciste esta semana; al elegir uno se agrega a ese día con la etiqueta \"Repuesto\" y cuenta para tu semana. Puedes quitarlo desde el menú ⋯ de la tarjeta."),
        GuideTopic(key: "app-extras", title: "Extras pendientes", systemImage: "plus.circle",
                   body: "Los extras (como abdominales) tienen una cuota por semana. Si no los haces o los marcas con ✕, pasan al día siguiente con la etiqueta \"Pendiente\" hasta que cumplas la cuota. La cuota se reinicia cada lunes."),
        GuideTopic(key: "app-weight", title: "Peso por ejercicio", systemImage: "scalemass",
                   body: "Empieza con el peso de tu rutina, si lo trae. Cuando lo cambias en un ejercicio, se guarda en ese día y se vuelve el nuevo peso por defecto de ese ejercicio."),
        GuideTopic(key: "app-navigation", title: "Navegar días", systemImage: "chevron.left.chevron.right",
                   body: "Usa las flechas o desliza a los lados para ver días pasados y corregir lo que olvidaste marcar. Toca la fecha para volver a hoy."),
        GuideTopic(key: "app-calories", title: "Calorías", systemImage: "flame.circle",
                   body: "Son una estimación: MET 5.0 de fuerza × tu peso corporal × tiempo estimado (series × (45 s + descanso)). Sirven para comparar días, no son una medición."),
        GuideTopic(key: "app-notes", title: "Notas y check-in", systemImage: "note.text",
                   body: "Agrega notas del día al final de Mi día o de un ejercicio en su detalle; todas quedan en Perfil › Mis notas. Cada semana la app te pregunta si quieres actualizar tu peso y tu foto."),
    ]
}
