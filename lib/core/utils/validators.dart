class AppValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'O e-mail é obrigatório';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? passwordLogin(String? value) {
    if (value == null || value.isEmpty) return 'A senha é obrigatória';
    return null;
  }

  static String? passwordRegister(String? value) {
    if (value == null || value.isEmpty) return 'A senha é obrigatória';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'O nome é obrigatório';
    if (value.length < 3) return 'O nome deve ter pelo menos 3 caracteres';
    return null;
  }

  static String? document(String? value) {
    if (value == null || value.isEmpty) return 'O CPF é obrigatório';
    // Remove caracteres não numéricos
    final cleanedValue = value.replaceAll(RegExp(r'\D'), '');
    if (cleanedValue.length != 11) return 'O CPF deve conter 11 dígitos';
    if (!_isValidCPF(cleanedValue)) return 'CPF inválido';
    return null;
  }

  static bool _isValidCPF(String cpf) {
    // Verifica se todos os dígitos são iguais
    if (cpf.split('').every((digit) => digit == cpf[0])) return false;

    // Calcula o primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = 11 - (sum % 11);
    firstDigit = firstDigit > 9 ? 0 : firstDigit;

    // Calcula o segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = 11 - (sum % 11);
    secondDigit = secondDigit > 9 ? 0 : secondDigit;

    return cpf[9] == firstDigit.toString() && cpf[10] == secondDigit.toString();
  }

  static String? state(String? value) {
    if (value == null || value.isEmpty) return 'Sigla do estado é obrigatória';
    if (value.length != 2) return 'Use apenas 2 letras (ex: CE)';
    return null;
  }
}

