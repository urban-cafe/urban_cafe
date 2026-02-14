import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_settings.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class UpdatePointSettings {
  final LoyaltyRepository repository;
  const UpdatePointSettings(this.repository);

  Future<Either<Failure, PointSettings>> call(PointSettings settings) => repository.updatePointSettings(settings);
}
