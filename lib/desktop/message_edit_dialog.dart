import 'dart:io';

import 'package:flutter/material.dart';
import '../core/models/chat_message.dart';
import '../core/models/chat_input_data.dart';
import '../features/chat/models/message_edit_result.dart';
import '../l10n/app_localizations.dart';
import '../icons/lucide_adapter.dart';
import '../features/home/services/file_upload_service.dart';
import '../features/home/widgets/chat_input_bar.dart';
import '../theme/app_font_weights.dart';

Future<MessageEditResult?> showMessageEditDesktopDialog(
  BuildContext context, {
  required ChatMessage message,
}) async {
  return showDialog<MessageEditResult?>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _MessageEditDesktopDialog(message: message),
  );
}

class _MessageEditDesktopDialog extends StatefulWidget {
  const _MessageEditDesktopDialog({required this.message});
  final ChatMessage message;

  @override
  State<_MessageEditDesktopDialog> createState() =>
      _MessageEditDesktopDialogState();
}

class _MessageEditDesktopDialogState extends State<_MessageEditDesktopDialog> {
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 520,
          maxWidth: 720,
          maxHeight: 680,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: cs.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        l10n.messageEditPageTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: AppFontWeights.emphasis,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop<MessageEditResult>(
                            MessageEditResult(
                              content: _buildContentWithMarkers(),
                              shouldSend: true,
                            ),
                          );
                        },
                        icon: Icon(
                          Lucide.MessageCirclePlus,
                          size: 18,
                          color: cs.primary,
                        ),
                        label: Text(
                          l10n.messageEditPageSaveAndSend,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop<MessageEditResult>(
                            MessageEditResult(
                              content: _buildContentWithMarkers(),
                              shouldSend: false,
                            ),
                          );
                        },
                        icon: Icon(Lucide.Check, size: 18, color: cs.primary),
                        label: Text(
                          l10n.messageEditPageSave,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.mcpPageClose,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Lucide.X,
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Attachment action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _onPickPhotos,
                        icon: Icon(Lucide.Image, size: 16, color: cs.primary),
                        label: Text(
                          l10n.bottomToolsSheetPhotos,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _onPickFiles,
                        icon: Icon(
                          Lucide.Paperclip,
                          size: 16,
                          color: cs.primary,
                        ),
                        label: Text(
                          l10n.bottomToolsSheetUpload,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // File previews
                if (_docs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
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
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFF7F7F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file, size: 18),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 180,
                                  ),
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
                  ),
                if (_docs.isNotEmpty) const SizedBox(height: 8),
                // Image previews
                if (_images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
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
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
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
                  ),
                if (_images.isNotEmpty) const SizedBox(height: 8),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.multiline,
                      minLines: 10,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: l10n.messageEditPageHint,
                        filled: true,
                        fillColor: isDark
                            ? Colors.white10
                            : const Color(0xFFF7F7F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.18),
                            width: 0.6,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.18),
                            width: 0.6,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.primary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
