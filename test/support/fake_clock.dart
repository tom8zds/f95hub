/// A controllable wall clock for playtime tests.
class FakeClock {
  FakeClock(this.current);

  DateTime current;

  DateTime call() => current;

  void advance(Duration by) {
    current = current.add(by);
  }
}
