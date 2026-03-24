abstract class ITtsEngine {
  Future<void> speak(String text);
  Future<void> stop() async {}
}