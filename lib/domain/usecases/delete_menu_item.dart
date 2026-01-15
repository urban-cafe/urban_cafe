import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class DeleteMenuItem implements UseCase<void, DeleteMenuItemParams> {
  final MenuRepository repository;
  const DeleteMenuItem(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMenuItemParams params) {
    return repository.deleteMenuItem(params.id);
  }
}

class DeleteMenuItemParams extends Equatable {
  final String id;
  const DeleteMenuItemParams(this.id);

  @override
  List<Object?> get props => [id];
}
