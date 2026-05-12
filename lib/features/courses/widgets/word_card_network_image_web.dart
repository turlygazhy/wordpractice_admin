import 'dart:developer' show log;

import 'package:flutter/material.dart';

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Web: обход CORS для отображения — настоящий DOM [&lt;img&gt;] в [HtmlElementView].
Widget buildWordCardNetworkImage({
  required String cleanUrl,
  required int cardIndex,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: _WordCardHtmlImg(
      key: ValueKey<String>(cleanUrl),
      url: cleanUrl,
      cardIndex: cardIndex,
    ),
  );
}

final Set<String> _registeredWordImgViewTypes = {};

class _WordCardHtmlImg extends StatefulWidget {
  final String url;
  final int cardIndex;

  const _WordCardHtmlImg({
    super.key,
    required this.url,
    required this.cardIndex,
  });

  @override
  State<_WordCardHtmlImg> createState() => _WordCardHtmlImgState();
}

class _WordCardHtmlImgState extends State<_WordCardHtmlImg> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'word_img_i${widget.cardIndex}_h${widget.url.hashCode}_l${widget.url.length}';
    if (!_registeredWordImgViewTypes.contains(_viewType)) {
      _registeredWordImgViewTypes.add(_viewType);
      final url = widget.url;
      final index = widget.cardIndex;
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
        final img = html.ImageElement()
          ..src = url
          ..alt = 'word $index'
          ..style.width = '100px'
          ..style.height = '100px'
          ..style.objectFit = 'cover'
          ..style.display = 'block'
          ..style.border = 'none';
        img.onLoad.listen((_) {
          log(
            'WordCard image: OK html <img> onLoad index=$index '
            'url=${_wordCardWebImgPreview(url)}',
            name: 'CourseOpen',
          );
        });
        img.onError.listen((html.Event e) {
          log(
            'WordCard image: FAIL html <img> onError index=$index '
            'url=${_wordCardWebImgPreview(url)} event=$e',
            name: 'CourseOpen',
          );
        });
        return img;
      });
    }
    log(
      'WordCard image: HtmlElementView(<img>) index=${widget.cardIndex} '
      'viewType=$_viewType url=${_wordCardWebImgPreview(widget.url)}',
      name: 'CourseOpen',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

String _wordCardWebImgPreview(String url, [int max = 120]) {
  final t = url.trim();
  if (t.isEmpty) return '(empty)';
  if (t.length <= max) return t;
  return '${t.substring(0, max)}… totalLen=${t.length}';
}
