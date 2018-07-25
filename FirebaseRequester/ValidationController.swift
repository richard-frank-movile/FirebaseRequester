
import Foundation
import Result
import Firebase
import FirebaseDatabase
import CodableFirebase

extension Decodable {
    init?(fromFirebase data: Any) {
        do {
            self = try FirebaseDecoder().decode(Self.self, from: data)
        } catch {
            return nil
        }
    }
}

struct UserModel: Codable {
    let firstName, lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

protocol DatabaseTarget {
    var ref: DatabaseReference { get }
    var child: String { get }
}

extension DatabaseTarget {
    var ref: DatabaseReference {
        return Database.database().reference()
    }
}

enum SampleTarget {
    case getDocuments
    case getDocument(byId: Int)
}

extension SampleTarget: DatabaseTarget {
    
    var child: String {
        switch self {
        case .getDocuments:
            return "users"
        case .getDocument(let id):
            return "users/\(id)"
        }
    }
}

enum DatabaseProviderError: Error {
    case decoderError
    case snapshopError
}

class DatabaseProvider<T: DatabaseTarget, U: Decodable> {
    func request(_ target: T,
                 completion: @escaping (Result<U, DatabaseProviderError>) -> ()) {
        target.ref.child(target.child).observeSingleEvent(of: .value) { (snapshot) in
            if let data = snapshot.value {
                if let model = U.init(fromFirebase: data) {
                    completion(.success(model))
                } else {
                    completion(.failure(.decoderError))
                }
            } else {
                completion(.failure(.snapshopError))
            }
        }
    }
}

class ValidationController: UIViewController {
    
    var provider = DatabaseProvider<SampleTarget, UserModel>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        provider.request(.getDocument(byId: 1)) { (result) in
            switch result {
            case .success(let value):
                print(value)
            case .failure(let error):
                print(error)
            }
        }
    }
}


