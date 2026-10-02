class AppResult<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  AppResult.success(this.data)
      : errorMessage = null,
        isSuccess = true;

  AppResult.failure(this.errorMessage)
      : data = null,
        isSuccess = false;
}
