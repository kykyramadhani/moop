import Observation

@Observable
final class Navigator {
    var path: [Route] = []

    func go(_ route: Route) { path.append(route) }
    func home() { path.removeAll() }
}
