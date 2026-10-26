/// Wynik akcji użytkownika (dodaj / edytuj / usuń / przesuń).
/// UI na podstawie wyniku decyduje, czy pokazać komunikat błędu.
sealed class ActionResult {
  const ActionResult();

  bool get isSuccess => this is ActionSuccess;
}

final class ActionSuccess extends ActionResult {
  const ActionSuccess();
}

final class ActionFailure extends ActionResult {
  final String message;

  const ActionFailure(this.message);
}
