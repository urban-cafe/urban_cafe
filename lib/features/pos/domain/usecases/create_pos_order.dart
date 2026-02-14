import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';
import 'package:urban_cafe/features/pos/domain/repositories/pos_repository.dart';

class CreatePosOrderParams {
  final List<CartItem> items;
  final double totalAmount;
  final PosPaymentMethod paymentMethod;
  final double cashTendered;
  final double changeAmount;

  const CreatePosOrderParams({required this.items, required this.totalAmount, required this.paymentMethod, this.cashTendered = 0, this.changeAmount = 0});
}

class CreatePosOrder extends UseCase<PosOrder, CreatePosOrderParams> {
  final PosRepository repository;
  CreatePosOrder(this.repository);

  @override
  Future<Either<Failure, PosOrder>> call(CreatePosOrderParams params) {
    return repository.createPosOrder(items: params.items, totalAmount: params.totalAmount, paymentMethod: params.paymentMethod, cashTendered: params.cashTendered, changeAmount: params.changeAmount);
  }
}
