import Foundation

extension Result {
  func asyncFlatMap<NewSuccess>(_ transform: (Success) async -> Result<NewSuccess, Failure>) async
    -> Result<NewSuccess, Failure>
  {
    switch self {
    case .success(let value):
      return await transform(value)
    case .failure(let error):
      return .failure(error)
    }
  }
}
