import '../../domain/entities/login_methods_entity.dart';

sealed class LoginMethodsState {
  const LoginMethodsState();
}

class LoginMethodsInitial extends LoginMethodsState {
  const LoginMethodsInitial();
}

class LoginMethodsLoading extends LoginMethodsState {
  const LoginMethodsLoading();
}

class LoginMethodsLoaded extends LoginMethodsState {
  const LoginMethodsLoaded({required this.methods, this.isRefreshing = false});

  final LoginMethodsEntity methods;
  final bool isRefreshing;

  LoginMethodsLoaded copyWith({
    LoginMethodsEntity? methods,
    bool? isRefreshing,
  }) {
    return LoginMethodsLoaded(
      methods: methods ?? this.methods,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class LoginMethodsError extends LoginMethodsState {
  const LoginMethodsError(this.message);

  final String message;
}
