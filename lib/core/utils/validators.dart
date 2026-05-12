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


  static String? state(String? value) {
    if (value == null || value.isEmpty) return 'Sigla do estado é obrigatória';
    if (value.length != 2) return 'Use apenas 2 letras (ex: CE)';
    return null;
  }
}

