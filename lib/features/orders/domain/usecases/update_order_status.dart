import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/repositories/order_repository.dart';

class UpdateOrderStatus implements UseCase<void, UpdateOrderStatusParams> {
  final OrderRepository repository;

  UpdateOrderStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateOrderStatusParams params) {
    return repository.updateOrderStatus(params.orderId, params.status);
  }
}

class UpdateOrderStatusParams extends Equatable {
  final String orderId;
  final OrderStatus status;

  const UpdateOrderStatusParams({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}
