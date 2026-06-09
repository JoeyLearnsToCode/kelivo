import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/chat_input_data.dart';
import '../models/message_edit_result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../../../core/services/haptics.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../features/home/services/file_upload_service.dart';
import '../../../features/home/widgets/chat_input_bar.dart';
import '../../../theme/app_font_weights.dart';

Future<MessageEditResult?> showMessageEditSheet(
  BuildContext context, {
  required ChatMessage message,
}) async {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<MessageEditResult?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) =>
        SafeArea(top: false, child: _MessageEditSheet(message: message)),
  );
}

class _MessageEditSheet extends StatefulWidget {
  const _MessageEditSheet({required this.message});
  final ChatMessage message;
  @override
  State<_MessageEditSheet> createState() => _MessageEditSheetState();
}

class _MessageEditSheetState extends State<_MessageEditSheet> {
  late final TextEditingController _controller;
  final List<String> _images = <String>[];
  final List<DocumentAttachment> _docs = <DocumentAttachment>[];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onPickPhotos() async {
    final service = FileUploadService(
      getContext: () => context,
      mediaController: ChatInputBarController(),
      onScrollToBottom: () {},
    );
    final paths = await service.pickAndCopyPhotos();
    if (paths.isNotEmpty && mounted) {
      setState(() => _images.addAll(paths));
    }
  }

  Future<void> _onPickFiles() async {
    final service = FileUploadService(
      getContext: () => context,
      mediaController: ChatInputBarController(),
      onScrollToBottom: () {},
    );
    final result = await service.pickAndCopyFiles();
    if (mounted) {
      setState(() {
        _images.addAll(result.imagePaths);
        _docs.addAll(result.docs);
      });
    }
  }

  void _removeImageAt(int index) {
    final path = _images[index];
    setState(() => _images.removeAt(index));
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  void _removeDocAt(int index) {
    final d = _docs[index];
    setState(() => _docs.removeAt(index));
    try {
      final f = File(d.path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  String _buildContentWithMarkers() {
    final text = _controller.text.trim();
    final imageMarkers = _images.map((p) => '\n[image:$p]').join();
    final docMarkers = _docs
        .map((d) => '\n[file:${d.path}|${d.fileName}|${d.mime}]')
        .join();
    return text + imageMarkers + docMarkers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      // Ensure keyboard-safe bottom inset for the sheet
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (c, sc) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IosCardPress(
                        onTap: () {
                          Haptics.light();
                          Navigator.of(context).pop<MessageEditResult>(
                            MessageEditResult(
                              content: _buildContentWithMarkers(),
                              shouldSend: true,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        baseColor: Colors.transparent,
                        pressedBlendStrength:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.10
                            : 0.06,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          l10n.messageEditPageSaveAndSend,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: AppFontWeights.emphasis,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        l10n.messageEditPageTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: AppFontWeights.semibold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IosCardPress(
                        onTap: () {
                          Haptics.light();
                          Navigator.of(context).pop<MessageEditResult>(
                            MessageEditResult(
                              content: _buildContentWithMarkers(),
                              shouldSend: false,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        baseColor: Colors.transparent,
                        pressedBlendStrength:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.10
                            : 0.06,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          l10n.messageEditPageSave,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: AppFontWeights.emphasis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Attachment action buttons
              Row(
                children: [
                  IosCardPress(
                    onTap: _onPickPhotos,
                    borderRadius: BorderRadius.circular(20),
                    baseColor: Colors.transparent,
                    pressedBlendStrength:
                        Theme.of(context).brightness == Brightness.dark
                        ? 0.10
                        : 0.06,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Lucide.Image, size: 16, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.bottomToolsSheetPhotos,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: AppFontWeights.emphasis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IosCardPress(
                    onTap: _onPickFiles,
                    borderRadius: BorderRadius.circular(20),
                    baseColor: Colors.transparent,
                    pressedBlendStrength:
                        Theme.of(context).brightness == Brightness.dark
                        ? 0.10
                        : 0.06,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Lucide.Paperclip, size: 16, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.bottomToolsSheetUpload,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: AppFontWeights.emphasis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // File previews
              if (_docs.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final d = _docs[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file, size: 18),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                d.fileName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removeDocAt(idx),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (_docs.isNotEmpty) const SizedBox(height: 8),
              // Image previews
              if (_images.isNotEmpty)
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final path = _images[idx];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(path),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: Colors.black12,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: GestureDetector(
                              onTap: () => _removeImageAt(idx),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_images.isNotEmpty) const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  child: TextField(
                    controller: _controller,
                    autofocus: false,
                    keyboardType: TextInputType.multiline,
                    minLines: 8,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: l10n.messageEditPageHint,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : const Color(0xFFF2F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: cs.primary.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
