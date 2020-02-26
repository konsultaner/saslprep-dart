import 'package:saslprep/saslprep.dart';

void main() {
  // password
  print(Saslprep.saslprep('password\u00AD'));
  // No error due to unassigned character
  print(Saslprep.saslprep('password\u0487', options: SaslprepOptions(true)));
  // Error due to unassigned character
  print(Saslprep.saslprep('password\u0487'));
}
