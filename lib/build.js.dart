import 'package:saslprep/saslprep.dart';

import 'dart:js' as js;

void main() {
  js.context['saslprep'] = Saslprep.saslprep;
}
