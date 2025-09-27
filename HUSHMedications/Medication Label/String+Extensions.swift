// Adds a convenient isNotEmpty computed property to String
extension String {
    /// Returns true if the string is not empty.
    var isNotEmpty: Bool { !self.isEmpty }
}
