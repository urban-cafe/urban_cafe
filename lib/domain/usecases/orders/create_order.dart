import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/cart_item.dart';
import 'package:urban_cafe/domain/entities/order_type.dart';
import 'package:urban_cafe/domain/repositories/order_repository.dart';

class CreateOrder implements UseCase<String, CreateOrderParams> {
  final OrderRepository repository;

  CreateOrder(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateOrderParams params) {
    return repository.createOrder(
      items: params.items,
      totalAmount: params.totalAmount,
      type: params.type,
      pointsRedeemed: params.pointsRedeemed,
    );
  }
}

class CreateOrderParams extends Equatable {
  final List<CartItem> items;
  final double totalAmount;
  final OrderType type;
  final int pointsRedeemed;

  const CreateOrderParams({
    required this.items,
    required this.totalAmount,
    required this.type,
    this.pointsRedeemed = 0,
  });

  @override
  List<Object?> get props => [items, totalAmount, type, pointsRedeemed];
}
