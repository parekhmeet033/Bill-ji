import '../error/failures.dart';

abstract class Resource<T> {
  final T? data;
  final Failure? failure;

  Resource({this.data, this.failure});
}

class Initial<T> extends Resource<T> {
  Initial() : super();
}

class Success<T> extends Resource<T> {
  Success(T data) : super(data: data);
}

class Error<T> extends Resource<T> {
  Error(Failure failure) : super(failure: failure);
}

class Loading<T> extends Resource<T> {
  Loading() : super();
}
