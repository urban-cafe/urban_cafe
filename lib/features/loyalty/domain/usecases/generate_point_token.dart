import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class GeneratePointToken {
  final LoyaltyRepository repository;
  const GeneratePointToken(this.repository);

  Future<Either<Failure, PointToken>> call() => repository.generateToken();
}
