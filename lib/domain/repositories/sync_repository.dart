/// Future remote synchronization boundary. Local repositories remain the source
/// of truth until P3 sync is implemented.
abstract class SyncRepository {
  Future<void> pushAll();

  Future<void> pullAll();
}
