class RpcResult<T> {

  final bool success;

  final T? data;

  final String? message;

  const RpcResult({
    required this.success,
    this.data,
    this.message,
  });

  factory RpcResult.success(T data) {
    return RpcResult(
      success: true,
      data: data,
    );
  }

  factory RpcResult.failure(String message) {
    return RpcResult(
      success: false,
      message: message,
    );
  }

}