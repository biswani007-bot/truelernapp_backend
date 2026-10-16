import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/login_methods_repository.dart';
import '../../data/repositories/login_methods_repository_impl.dart';
import 'login_methods_state.dart';

final loginMethodsRepositoryProvider = Provider<LoginMethodsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoginMethodsRepositoryImpl(apiClient: apiClient);
});

final loginMethodsControllerProvider =
    NotifierProvider<LoginMethodsController, LoginMethodsState>(
      LoginMethodsController.new,
    );

class LoginMethodsController extends Notifier<LoginMethodsState> {
  @override
  LoginMethodsState build() {
    return const LoginMethodsInitial();
  }

  /// Resets state on logout or account switching.
  void reset() {
    state = const LoginMethodsInitial();
  }

  Future<void> loadLoginMethods({bool isRefresh = false}) async {
    final currentState = state;
    if (isRefresh && currentState is LoginMethodsLoaded) {
      state = currentState.copyWith(isRefreshing: true);
    } else if (!isRefresh) {
      state = const LoginMethodsLoading();
    }

    try {
      final repository = ref.read(loginMethodsRepositoryProvider);
      final methods = await repository.getLoginMethods();
      state = LoginMethodsLoaded(methods: methods, isRefreshing: false);
    } catch (e) {
      state = LoginMethodsError(e.toString());
    }
  }
}
