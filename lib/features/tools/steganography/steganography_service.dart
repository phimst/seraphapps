import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SteganographyException implements Exception {
  final String message;
  SteganographyException(this.message);
  @override
  String toString() => message;
}

/// Teknik LSB (Least Significant Bit): tiap karakter pesan disisipkan ke
/// bit paling gak signifikan dari channel biru tiap pixel. Perubahan ini
/// gak keliatan mata telanjang (nilai warna cuma geser ±1), tapi bisa
/// dibaca lagi program yang tau caranya.
///
/// PENTING: hasil gambar WAJIB PNG (lossless). Kalau disave/dishare
/// sebagai JPG, kompresinya bakal ngerusak data yang disisipin.
class SteganographyService {
  static const _magicHeader = 'SRPX'; // penanda biar tau ini gambar steganografi kita

  /// Sisipin [secretText] ke [imageBytes], return PNG bytes hasil sisipan.
  static Uint8List encode(Uint8List imageBytes, String secretText) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw SteganographyException('Gagal baca gambar. Format gak didukung.');
    }

    final textBytes = utf8.encode(secretText);
    final payload = utf8.encode(_magicHeader) + _int32Bytes(textBytes.length) + textBytes;
    final totalBits = payload.length * 8;
    final capacityBits = image.width * image.height;

    if (totalBits > capacityBits) {
      throw SteganographyException(
          'Teks kepanjangan buat gambar ini. Kapasitas maksimal ±${(capacityBits / 8).floor()} karakter, teks lu ${textBytes.length} karakter. Pakai gambar lebih gede.');
    }

    final bits = _bytesToBits(payload);
    var bitIndex = 0;

    outer:
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (bitIndex >= bits.length) break outer;
        final pixel = image.getPixel(x, y);
        final newBlue = (pixel.b.toInt() & ~1) | bits[bitIndex];
        image.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), newBlue, pixel.a.toInt());
        bitIndex++;
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Baca teks tersembunyi dari gambar. Return null kalau gambar ini
  /// gak punya pesan tersembunyi (atau bukan hasil dari app ini).
  static String? decode(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw SteganographyException('Gagal baca gambar. Format gak didukung.');
    }

    final headerBits = (_magicHeader.length + 4) * 8; // magic header + panjang teks (4 byte)
    final capacityBits = image.width * image.height;
    if (headerBits > capacityBits) return null;

    final headerByteList = <int>[];
    var bitBuffer = 0;
    var bitCount = 0;
    var byteIndex = 0;
    var pixelIndex = 0;

    // Baca header dulu (magic + panjang teks)
    for (var y = 0; y < image.height && byteIndex < _magicHeader.length + 4; y++) {
      for (var x = 0; x < image.width && byteIndex < _magicHeader.length + 4; x++) {
        final pixel = image.getPixel(x, y);
        bitBuffer = (bitBuffer << 1) | (pixel.b.toInt() & 1);
        bitCount++;
        pixelIndex++;
        if (bitCount == 8) {
          headerByteList.add(bitBuffer);
          bitBuffer = 0;
          bitCount = 0;
          byteIndex++;
        }
      }
    }

    if (headerByteList.length < _magicHeader.length + 4) return null;

    final magic = utf8.decode(headerByteList.sublist(0, _magicHeader.length));
    if (magic != _magicHeader) return null; // bukan gambar steganografi kita

    final lengthBytes = headerByteList.sublist(_magicHeader.length, _magicHeader.length + 4);
    final textLength = _bytesToInt32(lengthBytes);
    if (textLength <= 0 || textLength > capacityBits ~/ 8) return null;

    // Lanjut baca isi teks-nya dari posisi pixel setelah header
    final textBits = <int>[];
    final totalTextBits = textLength * 8;
    var flatIndex = 0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (flatIndex >= pixelIndex) {
          if (textBits.length >= totalTextBits) break;
          final pixel = image.getPixel(x, y);
          textBits.add(pixel.b.toInt() & 1);
        }
        flatIndex++;
      }
      if (textBits.length >= totalTextBits) break;
    }

    final textBytes = <int>[];
    for (var i = 0; i < textBits.length; i += 8) {
      if (i + 8 > textBits.length) break;
      var byte = 0;
      for (var j = 0; j < 8; j++) {
        byte = (byte << 1) | textBits[i + j];
      }
      textBytes.add(byte);
    }

    try {
      return utf8.decode(textBytes);
    } catch (_) {
      return null;
    }
  }

  static List<int> _bytesToBits(List<int> bytes) {
    final bits = <int>[];
    for (final byte in bytes) {
      for (var i = 7; i >= 0; i--) {
        bits.add((byte >> i) & 1);
      }
    }
    return bits;
  }

  static List<int> _int32Bytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static int _bytesToInt32(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
}
