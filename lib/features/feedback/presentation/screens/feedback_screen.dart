import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_user_avatar.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/features/feedback/data/feedback_api_service.dart';
import 'package:mess_pilot/features/feedback/domain/entities/feedback_entity.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_page_body.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _descriptionController = TextEditingController();
  late final _api = FeedbackApiService(getIt<ApiClient>());
  final _picker = ImagePicker();
  List<FeedbackEntity> _feedbacks = [];
  List<FeedbackImageUpload> _selectedImages = [];
  int? _nextPage;
  bool _loading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _submitting = false;
  Object? _error;
  CancelToken? _cancel;
  int _requestVersion = 0;

  static const int _maxImages = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (_submitting) return;
    final version = ++_requestVersion;
    final cancel = CancelToken();
    _cancel?.cancel();
    _cancel = cancel;
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final result = await _api.getFeedbacks(cancelToken: cancel);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _feedbacks = result.feedbacks;
        _nextPage = result.nextPage;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || version != _requestVersion || cancel.isCancelled) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_nextPage == null || _refreshing || _loadingMore) return;
    final version = _requestVersion;
    setState(() { _loadingMore = true; });
    try {
      final result = await _api.getFeedbacks(page: _nextPage!);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _feedbacks = [..._feedbacks, ...result.feedbacks];
        _nextPage = result.nextPage;
      });
    } catch (e) {
      if (!mounted || version != _requestVersion) return;
      context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() { _loadingMore = false; });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing || _loading || _submitting) return;
    setState(() { _refreshing = true; });
    await _load(silent: true);
    if (mounted) setState(() { _refreshing = false; });
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      context.showAlertSnackBar(context.local.feedbackMaxImages);
      return;
    }
    final remaining = _maxImages - _selectedImages.length;
    try {
      final images = await _picker.pickMultiImage(limit: remaining, imageQuality: 80);
      if (images.isEmpty) return;
      final toAdd = images.take(remaining);
      final uploads = <FeedbackImageUpload>[];
      for (final file in toAdd) {
        final bytes = await file.readAsBytes();
        uploads.add((name: file.name, bytes: bytes));
      }
      if (!mounted) return;
      setState(() {
        _selectedImages = [..._selectedImages, ...uploads];
      });
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(e);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages = [..._selectedImages]..removeAt(index);
    });
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      context.showAlertSnackBar(context.local.feedbackDescriptionRequired);
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final created = await _api.submitFeedback(
        description: description,
        images: _selectedImages,
      );
      if (!mounted) return;
      _descriptionController.clear();
      setState(() {
        _selectedImages = [];
        _submitting = false;
        _feedbacks = [created, ..._feedbacks];
      });
      context.showSuccessSnackBar(context.local.feedbackSubmitted);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      context.showErrorSnackBar(e);
    }
  }

  void _handleCommentAdded(String feedbackId, FeedbackCommentEntity newComment) {
    setState(() {
      final index = _feedbacks.indexWhere((f) => f.id == feedbackId);
      if (index != -1) {
        final current = _feedbacks[index];
        _feedbacks[index] = current.copyWith(
          commentsCount: current.commentsCount + 1,
          comments: [...current.comments, newComment],
        );
      }
    });
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);

    return Scaffold(
      appBar: showWebAppBar
          ? null
          : AppBar(
              leading: const HomeBackButton(),
              title: Text(context.local.feedbackTitle),
            ),
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      body: MainPageBody(
        title: context.local.feedbackTitle,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _feedbacks.isEmpty) return const Center(child: AppLoader());
    if (_error != null && _feedbacks.isEmpty) return Center(child: AppErrorState(error: _error!, onRetry: _load));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: AppPageScrollView(
        maxWidth: 760.0,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
          vertical: Dimensions.paddingSizeDefault,
        ),
        children: [
          _buildHeaderBanner(),
          const SizedBox(height: Dimensions.spaceDefault),
          _buildSubmitForm(),
          const SizedBox(height: Dimensions.spaceLarge),
          if (_feedbacks.isEmpty)
            AppStateView(
              title: context.local.feedbackEmptyTitle,
              message: context.local.feedbackEmptyMessage,
              icon: Icons.feedback_outlined,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.local.feedbackListTitle,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.spaceSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.customThemeColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    '${_feedbacks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: AppTextStyles.semiBold,
                      color: context.customThemeColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spaceSmall),
            for (final fb in _feedbacks)
              _FeedbackCard(
                feedback: fb,
                api: _api,
                onCommentAdded: (comment) => _handleCommentAdded(fb.id, comment),
                key: ValueKey(fb.id),
              ),
            if (_nextPage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                child: Center(
                  child: OutlinedButton(
                    onPressed: _loadingMore ? null : _loadMore,
                    child: _loadingMore ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.local.opinionLoadMore),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    final colors = context.customThemeColors;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colors.primaryColor.withValues(alpha: 0.25),
                  colors.secondaryColor.withValues(alpha: 0.14),
                ]
              : [
                  colors.primaryColor.withValues(alpha: 0.12),
                  colors.secondaryColor.withValues(alpha: 0.06),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colors.primaryColor.withValues(alpha: isDark ? 0.40 : 0.22),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Icon(Icons.tips_and_updates_rounded, color: colors.primaryColor, size: 24),
              ),
              const SizedBox(width: Dimensions.spaceDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.local.feedbackHeaderTitle,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: colors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.local.feedbackHeaderSubtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondaryColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitForm() {
    final colors = context.customThemeColors;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        side: BorderSide(color: colors.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.local.feedbackFormTitle,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: AppTextStyles.semiBold),
            ),
            const SizedBox(height: Dimensions.spaceSmall),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 2000,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: context.local.feedbackDescriptionHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                contentPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              ),
            ),
            const SizedBox(height: Dimensions.spaceSmall),
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Dimensions.spaceSmall),
                  itemBuilder: (context, index) => _buildSelectedImage(index),
                ),
              ),
              const SizedBox(height: Dimensions.spaceSmall),
            ],
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Dimensions.spaceSmall,
              runSpacing: Dimensions.spaceSmall,
              children: [
                OutlinedButton.icon(
                  onPressed: _submitting || _selectedImages.length >= _maxImages ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: Text(context.local.feedbackAddImages(_maxImages - _selectedImages.length)),
                ),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(context.local.feedbackSubmitButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImage(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Image.memory(
            _selectedImages[index].bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single feedback card with expandable comments, inline image viewer, and
/// reply composer.
class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({
    required this.feedback,
    required this.api,
    required this.onCommentAdded,
    super.key,
  });

  final FeedbackEntity feedback;
  final FeedbackApiService api;
  final ValueChanged<FeedbackCommentEntity> onCommentAdded;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _showComments = false;
  bool _submittingComment = false;
  bool _loadingComments = false;
  bool _loadingMoreComments = false;
  int? _commentsNextPage;
  List<FeedbackCommentEntity>? _localComments;
  final _commentController = TextEditingController();
  FeedbackImageUpload? _commentImage;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleComments() async {
    final nextState = !_showComments;
    setState(() {
      _showComments = nextState;
    });

    if (nextState && _localComments == null) {
      if (widget.feedback.comments.isNotEmpty) {
        _localComments = List.from(widget.feedback.comments);
      } else if (widget.feedback.commentsCount > 0) {
        setState(() {
          _loadingComments = true;
        });
        try {
          final result = await widget.api.getComments(widget.feedback.id);
          if (!mounted) return;
          setState(() {
            _localComments = result.comments;
            _commentsNextPage = result.nextPage;
            _loadingComments = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _localComments = [];
            _loadingComments = false;
          });
        }
      } else {
        _localComments = [];
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_commentsNextPage == null || _loadingMoreComments) return;
    setState(() { _loadingMoreComments = true; });
    try {
      final result = await widget.api.getComments(widget.feedback.id, page: _commentsNextPage!);
      if (!mounted) return;
      final current = _localComments ?? widget.feedback.comments;
      final existingIds = current.map((comment) => comment.id).toSet();
      setState(() {
        _localComments = [...current, ...result.comments.where((comment) => !existingIds.contains(comment.id))];
        _commentsNextPage = result.nextPage;
      });
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() { _loadingMoreComments = false; });
    }
  }

  Future<void> _pickCommentImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _commentImage = (name: file.name, bytes: bytes);
      });
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(e);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _commentImage == null) return;

    setState(() {
      _submittingComment = true;
    });

    try {
      final comment = await widget.api.addComment(
        feedbackId: widget.feedback.id,
        comment: text,
        image: _commentImage,
      );
      if (!mounted) return;
      _commentController.clear();
      final currentList = _localComments ?? widget.feedback.comments;
      setState(() {
        _commentImage = null;
        _submittingComment = false;
        _localComments = [...currentList, comment];
      });
      widget.onCommentAdded(comment);
      context.showSuccessSnackBar(context.local.feedbackCommentSubmitted);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingComment = false;
      });
      context.showErrorSnackBar(e);
    }
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fb = widget.feedback;
    final colors = context.customThemeColors;
    final dateFormat = DateFormat.yMMMd('en_US').add_jm();

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceSmall),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          side: BorderSide(color: colors.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              Row(
                children: [
                  AppUserAvatar(name: fb.authorName, photoUrl: fb.authorPhotoUrl),
                  const SizedBox(width: Dimensions.spaceSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fb.authorName,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: AppTextStyles.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (fb.isAuthor) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                ),
                                child: Text(
                                  context.local.feedbackYou,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: AppTextStyles.bold,
                                    color: colors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          dateFormat.format(fb.createdAt),
                          style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceDefault),
              // Feedback description
              SelectableText(
                fb.description,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              // Images
              if (fb.images.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spaceSmall),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fb.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Dimensions.spaceSmall),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _showFullImage(context, fb.images[index]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        child: Image.network(
                          fb.images[index],
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 110,
                            height: 110,
                            color: colors.borderColor,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Dimensions.spaceSmall),
              const Divider(height: 16),
              // Action row with comments count button
              Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: _toggleComments,
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showComments ? Icons.chat_bubble : Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: colors.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                fb.commentsCount > 0
                                    ? context.local.feedbackCommentsCount(fb.commentsCount)
                                    : context.local.feedbackAddCommentButton,
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: AppTextStyles.semiBold,
                                  color: colors.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showComments ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: colors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Expanded comments thread
              if (_showComments) ...[
                const SizedBox(height: Dimensions.spaceSmall),
                if (_loadingComments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    child: Center(child: AppLoader(size: 20)),
                  )
                else ...[
                  for (final c in (_localComments ?? fb.comments))
                    _buildCommentTile(c, colors, dateFormat),
                  if (_commentsNextPage != null)
                    Align(
                      child: TextButton(
                        onPressed: _loadingMoreComments ? null : _loadMoreComments,
                        child: _loadingMoreComments ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.local.opinionLoadMore),
                      ),
                    ),
                ],
                const SizedBox(height: Dimensions.spaceSmall),
                // Inline composer
                _buildCommentComposer(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentTile(FeedbackCommentEntity c, dynamic colors, DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: c.authorPhotoUrl != null ? NetworkImage(c.authorPhotoUrl!) : null,
                child: c.authorPhotoUrl == null
                    ? Text(
                        c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.authorName,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: AppTextStyles.semiBold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.isAuthor) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          context.local.feedbackYou,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: AppTextStyles.bold,
                            color: colors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(c.createdAt),
                style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondaryColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (c.comment.isNotEmpty)
            SelectableText(
              c.comment,
              style: context.textTheme.bodySmall?.copyWith(height: 1.3),
            ),
          if (c.imageUrl != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showFullImage(context, c.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Image.network(
                  c.imageUrl!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 90,
                    height: 90,
                    color: colors.borderColor,
                    child: const Icon(Icons.broken_image_outlined, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentComposer(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_commentImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Image.memory(
                  _commentImage!.bytes,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _commentImage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceSmall),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: context.local.feedbackWriteCommentHint,
                  hintStyle: context.textTheme.bodySmall?.copyWith(color: colors.textHintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Dimensions.spaceSmall),
            IconButton(
              onPressed: _submittingComment ? null : _pickCommentImage,
              tooltip: context.local.feedbackCommentImageTooltip,
              icon: Icon(
                _commentImage != null ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
                color: _commentImage != null ? colors.primaryColor : colors.textSecondaryColor,
                size: 22,
              ),
            ),
            IconButton.filled(
              onPressed: _submittingComment ? null : _submitComment,
              icon: _submittingComment
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
