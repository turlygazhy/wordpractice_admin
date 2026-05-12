import 'dart:developer' show log;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Non-web / VM: same as before — [CachedNetworkImage] (no Storage CORS issue here).
Widget buildWordCardNetworkImage({
  required String cleanUrl,
  required int cardIndex,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: CachedNetworkImage(
      imageUrl: cleanUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      memCacheWidth: 100,
      memCacheHeight: 100,
      maxWidthDiskCache: 200,
      maxHeightDiskCache: 200,
      imageBuilder: (context, imageProvider) {
        log(
          'WordCard image: OK decoded (CachedNetworkImage) index=$cardIndex '
          'url=${_wordCardNetImgPreview(cleanUrl)}',
          name: 'CourseOpen',
        );
        return Image(
          image: imageProvider,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      },
      placeholder: (context, url) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        log(
          'WordCard image: FAIL (CachedNetworkImage) index=$cardIndex '
          'url=${_wordCardNetImgPreview(url.toString())} error=$error',
          name: 'CourseOpen',
          error: error,
        );
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    ),
  );
}

String _wordCardNetImgPreview(String url, [int max = 120]) {
  final t = url.trim();
  if (t.isEmpty) return '(empty)';
  if (t.length <= max) return t;
  return '${t.substring(0, max)}… totalLen=${t.length}';
}
