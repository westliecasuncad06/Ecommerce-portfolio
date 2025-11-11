import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService(this._storage);
  final FirebaseStorage _storage;

  /// Upload a picked image (XFile) to Storage under products/{sellerId}/ and return download URL
  Future<String> uploadProductImage(XFile file, String sellerId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = 'products/$sellerId/$fileName';
    final ref = _storage.ref().child(path);
    final bytes = await file.readAsBytes();
    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }
}
