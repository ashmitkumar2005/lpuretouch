import 'dart:convert';
void main() {
  final pvrResult = '[{"Message":"Invalid User/Password mentioned."}]';
  final List<dynamic> parsed = jsonDecode(pvrResult);
  final tokenItem = parsed.firstWhere(
    (e) => e['AccessToken'] != null,
    orElse: () => null,
  );
  print('tokenItem: $tokenItem');
  if (tokenItem != null) {
    print('Login success!');
  } else {
    print('Login failed!');
  }
}
