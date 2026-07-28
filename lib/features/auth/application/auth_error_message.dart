import 'package:supabase_flutter/supabase_flutter.dart';

/// 회원가입 실패 사유를 사용자용 한국어 문구로 바꾼다.
///
/// Supabase는 코드/메시지를 영어로 주므로, 흔한 실패는 원인이 보이도록 풀어 쓴다.
String signUpErrorMessage(Object error) {
  if (error is AuthException) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();
    if (code == 'email_address_invalid' || message.contains('invalid')) {
      return '사용할 수 없는 이메일입니다. 다른 이메일을 입력해 주세요.';
    }
    if (code == 'user_already_exists' ||
        message.contains('already registered') ||
        message.contains('already been registered')) {
      return '이미 가입된 이메일입니다. 로그인해 주세요.';
    }
    if (code == 'weak_password' || message.contains('password')) {
      return '비밀번호가 너무 약합니다. 6자 이상으로 입력해 주세요.';
    }
    if (code == 'over_email_send_rate_limit' ||
        message.contains('rate limit')) {
      return '요청이 너무 잦습니다. 잠시 후 다시 시도해 주세요.';
    }
    return '회원가입 실패: ${error.message}';
  }
  return '회원가입에 실패했습니다. 네트워크를 확인해 주세요.';
}

/// 로그인 실패 사유를 사용자용 한국어 문구로 바꾼다.
String signInErrorMessage(Object error) {
  if (error is AuthException) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();
    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return '이메일 확인이 필요합니다. 받은 메일의 링크를 눌러 주세요.';
    }
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    return '로그인 실패: ${error.message}';
  }
  return '로그인에 실패했습니다. 네트워크를 확인해 주세요.';
}
