#!/usr/bin/env swift
// Valida Routine/routine.json: estructura, ids únicos, referencias del schedule y media descargada.
// Uso: swift Scripts/validate-routine.swift [ruta/a/routine.json]
import Foundation

struct Exercise: Decodable { let id: String; let name: String; let sets: Int; let reps: String; let gifId: String? }
struct Block: Decodable { let id: String; let name: String; let exercises: [Exercise]; let timesPerWeek: Int? }
struct Routine: Decodable { let version: Int; let days: [Block]; let extras: [Block]?; let schedule: [String: [String]] }

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let path = CommandLine.arguments.dropFirst().first.map { URL(fileURLWithPath: $0) } ?? root.appending(path: "Routine/routine.json")

var errors: [String] = []
var warnings: [String] = []

struct CatalogEntry: Decodable { let id: String }
struct Catalog: Decodable { let exercises: [CatalogEntry] }
let catalogIds = Set(((try? JSONDecoder().decode(Catalog.self, from: Data(contentsOf: root.appending(path: "Catalog/exercises.json"))))?.exercises ?? []).map(\.id))

do {
    let routine = try JSONDecoder().decode(Routine.self, from: Data(contentsOf: path))
    let blocks = routine.days + (routine.extras ?? [])
    let blockIds = blocks.map(\.id)
    if Set(blockIds).count != blockIds.count { errors.append("Hay ids de días/extras repetidos.") }

    var seen = Set<String>()
    for block in blocks {
        for ex in block.exercises {
            if !seen.insert(ex.id).inserted { errors.append("id de ejercicio repetido: \(ex.id)") }
            if ex.id.range(of: "^[a-z0-9-]+$", options: .regularExpression) == nil { errors.append("id inválido: \(ex.id)") }
            if ex.sets < 1 { errors.append("\(ex.id): sets debe ser ≥ 1") }
            if let gif = ex.gifId, gif.hasPrefix("chalk/") {
                if !catalogIds.contains(gif) { errors.append("\(ex.name): \(gif) no existe en Catalog/exercises.json") }
            } else if let gif = ex.gifId {
                let gifURL = root.appending(path: "Routine/media/\(gif).gif")
                if !FileManager.default.fileExists(atPath: gifURL.path) { warnings.append("\(ex.name): falta media de \(gif). Corre Scripts/fetch-media.sh") }
            } else {
                warnings.append("\(ex.name): sin GIF ni entrada de catálogo (la app mostrará un aviso)")
            }
        }
    }
    for extra in routine.extras ?? [] where extra.timesPerWeek == nil { errors.append("El extra \(extra.id) necesita timesPerWeek") }

    let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    for day in weekdays {
        guard let ids = routine.schedule[day] else { errors.append("schedule.\(day) falta"); continue }
        for id in ids where !blockIds.contains(id) { errors.append("schedule.\(day) referencia un id inexistente: \(id)") }
    }
    print("Rutina: \(routine.days.count) días, \((routine.extras ?? []).count) extras, \(seen.count) ejercicios")
} catch {
    errors.append("No se pudo leer \(path.path): \(error)")
}

warnings.forEach { print("⚠️  \($0)") }
errors.forEach { print("❌ \($0)") }
print(errors.isEmpty ? "✅ Rutina válida" : "Rutina inválida")
exit(errors.isEmpty ? 0 : 1)
