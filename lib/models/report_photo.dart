import 'dart:typed_data';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';

/// Image formats accepted for report photos.
enum PhotoFormat {
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png'),
  webp('image/webp', 'webp');

  const PhotoFormat(this.contentType, this.extension);
  final String contentType;
  final String extension;
}

/// A photo chosen on the device, validated and ready to upload.
class PickedPhoto {
  const PickedPhoto._(this.bytes, this.format);

  /// Validates [bytes] by size and by file signature ("magic bytes").
  ///
  /// The file extension or the picker's reported MIME type are not trusted.
  /// Storage enforces size and MIME type again on the server.
  factory PickedPhoto.fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const AppException(AppErrorKind.validation, 'That file is empty.');
    }
    if (bytes.length > AppConfig.maxPhotoBytes) {
      throw const AppException(
        AppErrorKind.validation,
        'That photo is too large. Choose one under 5 MB.',
      );
    }
    final format = detectPhotoFormat(bytes);
    if (format == null) {
      throw const AppException(
        AppErrorKind.validation,
        'Only JPEG, PNG or WebP photos are supported.',
      );
    }
    return PickedPhoto._(bytes, format);
  }

  final Uint8List bytes;
  final PhotoFormat format;
}

/// Identifies JPEG, PNG and WebP from their leading bytes.
PhotoFormat? detectPhotoFormat(Uint8List bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return PhotoFormat.jpeg;
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return PhotoFormat.png;
  }
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) && // RIFF
      startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    // WEBP
    return PhotoFormat.webp;
  }
  return null;
}

/// What should happen to a report's photo when it is edited.
sealed class PhotoChange {
  const PhotoChange();
}

class KeepPhoto extends PhotoChange {
  const KeepPhoto();
}

class RemovePhoto extends PhotoChange {
  const RemovePhoto();
}

class ReplacePhoto extends PhotoChange {
  const ReplacePhoto(this.photo);
  final PickedPhoto photo;
}
