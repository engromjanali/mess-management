import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notice_entity.dart';
import '../repositories/notice_repository.dart';

/// Loads every notice.
@lazySingleton
class GetNoticesUseCase implements UseCase<List<NoticeEntity>, NoParams> {
  final NoticeRepository _repository;
  GetNoticesUseCase(this._repository);

  @override
  ResultFuture<List<NoticeEntity>> call(NoParams params) =>
      _repository.getNotices();
}

/// Params for publishing a notice.
class AddNoticeParams extends Equatable {
  final String title;
  final String description;

  const AddNoticeParams({required this.title, required this.description});

  @override
  List<Object?> get props => [title, description];
}

/// Publishes a new notice.
@lazySingleton
class AddNoticeUseCase implements UseCase<NoticeEntity, AddNoticeParams> {
  final NoticeRepository _repository;
  AddNoticeUseCase(this._repository);

  @override
  ResultFuture<NoticeEntity> call(AddNoticeParams params) =>
      _repository.addNotice(
        title: params.title,
        description: params.description,
      );
}

/// Params for editing a notice.
class UpdateNoticeParams extends Equatable {
  final String id;
  final String title;
  final String description;

  const UpdateNoticeParams({
    required this.id,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [id, title, description];
}

/// Edits an existing notice.
@lazySingleton
class UpdateNoticeUseCase implements UseCase<NoticeEntity, UpdateNoticeParams> {
  final NoticeRepository _repository;
  UpdateNoticeUseCase(this._repository);

  @override
  ResultFuture<NoticeEntity> call(UpdateNoticeParams params) =>
      _repository.updateNotice(
        id: params.id,
        title: params.title,
        description: params.description,
      );
}

/// Removes a notice by id.
@lazySingleton
class DeleteNoticeUseCase implements UseCase<void, String> {
  final NoticeRepository _repository;
  DeleteNoticeUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.deleteNotice(id);
}
