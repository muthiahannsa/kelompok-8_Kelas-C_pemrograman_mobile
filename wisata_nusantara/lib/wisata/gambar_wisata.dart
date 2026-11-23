import 'dart:convert';

import 'package:flutter/material.dart';

/// Menampilkan gambar wisata, baik dari URL biasa maupun dari data base64.
Widget gambarWisata(String src, {double? height, BoxFit fit = BoxFit.cover}) {
  Widget fallback = Container(
    height: height,
    color: Colors.grey.shade300,
    child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
  );

  if (src.isEmpty) return fallback;

  if (src.startsWith('data:image')) {
    try {
      final bytes = base64Decode(src.substring(src.indexOf(',') + 1));
      return Image.memory(
        bytes,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }

  return Image.network(
    src,
    height: height,
    width: double.infinity,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}