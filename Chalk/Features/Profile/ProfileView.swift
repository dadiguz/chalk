import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(RoutineStore.self) private var store
    @Query private var profiles: [UserProfile]
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var weights: [BodyWeightEntry]
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @Query private var notes: [Note]
    @State private var isCheckingIn = false
    @State private var debugRoute: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                if let profile {
                    header(profile)
                }

                Section {
                    Button("Actualizar peso y foto", systemImage: "camera.badge.clock") { isCheckingIn = true }
                } footer: {
                    if let profile {
                        Text("Último check-in: \(profile.lastCheckInAt.formatted(.relative(presentation: .named))).")
                    }
                }

                Section {
                    NavigationLink {
                        ProgressChartsView()
                    } label: {
                        Label("Progreso", systemImage: "chart.xyaxis.line")
                    }
                    NavigationLink {
                        PhotosGalleryView()
                    } label: {
                        LabeledContent {
                            Text(photos.count, format: .number)
                        } label: {
                            Label("Fotos", systemImage: "photo.stack")
                        }
                    }
                    NavigationLink {
                        NotesLogView()
                    } label: {
                        LabeledContent {
                            Text(notes.count, format: .number)
                        } label: {
                            Label("Mis notas", systemImage: "note.text")
                        }
                    }
                }

                routineSection

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("Acerca de y créditos", systemImage: "info.circle")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.canvas))
            .navigationTitle("Perfil")
            #if DEBUG
            .task { debugRoute = UserDefaults.standard.string(forKey: "profileRoute") }
            .navigationDestination(item: $debugRoute) { route in
                switch route {
                case "charts": ProgressChartsView()
                case "notes": NotesLogView()
                default: PhotosGalleryView()
                }
            }
            #endif
            .sheet(isPresented: $isCheckingIn) {
                if let profile { WeeklyCheckInView(profile: profile, isManual: true) }
            }
        }
    }

    private func header(_ profile: UserProfile) -> some View {
        @Bindable var profile = profile
        return Section {
            HStack(spacing: 16) {
                Group {
                    if let photo = photos.first, let image = PhotoStorage.image(for: photo.fileName) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.surfaceRaised))
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(.circle)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Nombre", text: $profile.name)
                        .font(.title2.bold())
                    if let weight = weights.first {
                        Text("\(weight.kg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var routineSection: some View {
        let meta = store.routine.meta
        return Section("Tu rutina") {
            if store.isExample {
                Label("Rutina de ejemplo", systemImage: "info.circle")
                    .foregroundStyle(.orange)
            }
            if let goal = meta.goal, !goal.isEmpty {
                LabeledContent("Objetivo", value: goal)
            }
            LabeledContent("Días", value: "\(store.routine.days.count)")
            if !store.routine.extras.isEmpty {
                LabeledContent("Extras", value: store.routine.extras.map(\.name).formatted(.list(type: .and)))
            }
            ForEach(meta.generalNotes, id: \.self) { note in
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
