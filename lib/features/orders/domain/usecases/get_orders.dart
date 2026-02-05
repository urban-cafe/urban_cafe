import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/repositories/order_repository.dart';

class GetOrders implements UseCase<List<OrderEntity>, GetOrdersParams> {
  final OrderRepository repository;

  GetOrders(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(GetOrdersParams params) {
    return repository.getOrders(status: params.status);
  }
}

class GetOrdersParams extends Equatable {
  final OrderStatus? status;

  const GetOrdersParams({this.status});

  @override
  List<Object?> get props => [status];
}
