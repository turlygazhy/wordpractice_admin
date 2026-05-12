import 'dart:developer' show log;
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Result of word form dialog.
/// Holds texts and optional media bytes and content types.
class WordFormResult {
  final String arabic;
  final String translation;
  final Uint8List? audioBytes;
  final String? audioContentType;
  final Uint8List? imageBytes;
  final String? imageContentType;

  const WordFormResult({
    required this.arabic,
    required this.translation,
    this.audioBytes,
    this.audioContentType,
    this.imageBytes,
    this.imageContentType,
  });
}

/// Dialog widget for creating or editing a word with media.
/// Provides simple UI for texts and web-only file pickers.
class WordFormDialogWidget extends StatefulWidget {
  final String? initialArabic;
  final String? initialTranslation;

  const WordFormDialogWidget({
    super.key,
    this.initialArabic,
    this.initialTranslation,
  });

  @override
  State<WordFormDialogWidget> createState() => _WordFormDialogWidgetState();
}

/// Normalizes [html.FileReader.result] after [readAsArrayBuffer]: web may expose
/// either [ByteBuffer] or [Uint8List] (e.g. NativeUint8List).
Uint8List _fileReaderResultToUint8List(Object? result) {
  if (result is ByteBuffer) {
    return result.asUint8List();
  }
  if (result is Uint8List) {
    return result;
  }
  throw StateError(
    'Unexpected FileReader.result type: ${result?.runtimeType}',
  );
}

class _WordFormDialogWidgetState extends State<WordFormDialogWidget> {
  late final TextEditingController _arabicController;
  late final TextEditingController _translationController;

  Uint8List? _audioBytes;
  String? _audioContentType;
  Uint8List? _imageBytes;
  String? _imageContentType;

  String? _arabicError;
  String? _translationError;

  @override
  void initState() {
    super.initState();
    log(
      'WordFormDialog: init initialArabicSet=${widget.initialArabic != null} '
      'initialTranslationSet=${widget.initialTranslation != null}',
      name: 'WordCRUD.dialog',
    );
    _arabicController = TextEditingController(text: widget.initialArabic ?? '');
    _translationController =
        TextEditingController(text: widget.initialTranslation ?? '');
  }

  @override
  void dispose() {
    _arabicController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  /// Validates all fields and returns result when valid.
  /// Closes dialog with constructed WordFormResult.
  void _submit() {
    setState(() {
      _arabicError = null;
      _translationError = null;
    });

    final arabic = _arabicController.text.trim();
    final translation = _translationController.text.trim();

    var hasError = false;

    if (arabic.isEmpty) {
      _arabicError = 'Обязательно';
      hasError = true;
    }
    if (translation.isEmpty) {
      _translationError = 'Обязательно';
      hasError = true;
    }

    if (hasError) {
      log(
        'WordFormDialog: submit blocked validation arabicEmpty=${arabic.isEmpty} '
        'translationEmpty=${translation.isEmpty}',
        name: 'WordCRUD.dialog',
      );
      setState(() {});
      return;
    }

    log(
      'WordFormDialog: submit pop arabicLen=${arabic.length} translationLen=${translation.length} '
      'audioBytes=${_audioBytes?.length ?? 0} audioContentType=$_audioContentType '
      'imageBytes=${_imageBytes?.length ?? 0} imageContentType=$_imageContentType',
      name: 'WordCRUD.dialog',
    );
    Navigator.of(context).pop(
      WordFormResult(
        arabic: arabic,
        translation: translation,
        audioBytes: _audioBytes,
        audioContentType: _audioContentType,
        imageBytes: _imageBytes,
        imageContentType: _imageContentType,
      ),
    );
  }

  /// Picks audio file on web and stores bytes and content type.
  /// Uses dart:html behind kIsWeb guard.
  Future<void> _pickAudioWeb() async {
    if (!kIsWeb) return;

    final input = html.FileUploadInputElement()..accept = 'audio/*';
    input.click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) {
      log('WordFormDialog: pick audio cancelled (no file)', name: 'WordCRUD.dialog');
      return;
    }

    final file = input.files!.first;
    log(
      'WordFormDialog: pick audio file name=${file.name} size=${file.size} type=${file.type}',
      name: 'WordCRUD.dialog',
    );
    final reader = html.FileReader()..readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = _fileReaderResultToUint8List(reader.result);
    log(
      'WordFormDialog: pick audio read OK bytes=${bytes.length}',
      name: 'WordCRUD.dialog',
    );
    setState(() {
      _audioBytes = bytes;
      _audioContentType = file.type.isEmpty ? 'audio/mpeg' : file.type;
    });
  }

  /// Picks image file on web and stores bytes and content type.
  /// Uses dart:html behind kIsWeb guard.
  Future<void> _pickImageWeb() async {
    if (!kIsWeb) return;

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) {
      log('WordFormDialog: pick image cancelled (no file)', name: 'WordCRUD.dialog');
      return;
    }

    final file = input.files!.first;
    log(
      'WordFormDialog: pick image file name=${file.name} size=${file.size} type=${file.type}',
      name: 'WordCRUD.dialog',
    );
    final reader = html.FileReader()..readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = _fileReaderResultToUint8List(reader.result);
    log(
      'WordFormDialog: pick image read OK bytes=${bytes.length}',
      name: 'WordCRUD.dialog',
    );
    setState(() {
      _imageBytes = bytes;
      _imageContentType = file.type.isEmpty ? 'image/jpeg' : file.type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Слово'),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  /// Builds dialog content column with text fields and media pickers.
  /// Separates layout from build method.
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _arabicController,
            decoration: InputDecoration(
              labelText: 'Арабский',
              border: const OutlineInputBorder(),
              errorText: _arabicError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _translationController,
            decoration: InputDecoration(
              labelText: 'Перевод',
              border: const OutlineInputBorder(),
              errorText: _translationError,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: kIsWeb ? _pickAudioWeb : null,
                  child: Text(
                    _audioBytes == null ? 'Выбрать аудио' : 'Аудио выбрано',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: kIsWeb ? _pickImageWeb : null,
                  child: Text(
                    _imageBytes == null ? 'Выбрать картинку' : 'Картинка выбрана',
                  ),
                ),
              ),
            ],
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 8),
            const Text(
              'Загрузка файлов сейчас реализована только для Web',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds dialog actions row with cancel and save buttons.
  /// Delegates validation and submit to private method.
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        onPressed: _submit,
        child: const Text('Сохранить'),
      ),
    ];
  }
}
