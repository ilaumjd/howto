import Foundation

extension Result {
    func asyncFlatMap<NewSuccess>(_ transform: (Success) async -> Result<NewSuccess, Failure>) async
        -> Result<NewSuccess, Failure>
    {
        switch self {
        case let .success(value):
            return await transform(value)
        case let .failure(error):
            return .failure(error)
        }
    }
}
