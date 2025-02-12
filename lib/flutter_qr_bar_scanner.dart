
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

//class FlutterQrBarScanner {
//  static const MethodChannel _channel =
//      const MethodChannel('flutter_qr_bar_scanner');
//
//  static Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }
//}


class PreviewDetails {
  num? height;
  num? width;
  num? orientation;
  int? textureId;

  PreviewDetails(this.height, this.width, this.orientation, this.textureId);
}

enum BarcodeFormats {
  ALL_FORMATS,
  AZTEC,
  CODE_128,
  CODE_39,
  CODE_93,
  CODABAR,
  DATA_MATRIX,
  EAN_13,
  EAN_8,
  ITF,
  PDF417,
  QR_CODE,
  UPC_A,
  UPC_E,
}

const _defaultBarcodeFormats = const [
  BarcodeFormats.ALL_FORMATS,
];

class FlutterQrReader {
  static const MethodChannel _channel = const MethodChannel('com.github.contactlutforrahman/flutter_qr_bar_scanner');
  static QrChannelReader channelReader = new QrChannelReader(_channel);
  //Set target size before starting
  static Future<PreviewDetails> start({
    required int height,
    required int width,
    required QRCodeHandler qrCodeHandler,
    List<BarcodeFormats>? formats = _defaultBarcodeFormats,
  }) async {
    final _formats = formats ?? _defaultBarcodeFormats;
    assert(_formats.length > 0);

    List<String> formatStrings = _formats.map((format) => format.toString().split('.')[1]).toList(growable: false);

    channelReader.setQrCodeHandler(qrCodeHandler);
    var details = await _channel.invokeMethod(
        'start', {'targetHeight': height, 'targetWidth': width, 'heartbeatTimeout': 0, 'formats': formatStrings});

    // invokeMethod returns Map<dynamic,...> in dart 2.0
    assert(details is Map<dynamic, dynamic>);

    int? textureId = details["textureId"];
    num? orientation = details["surfaceOrientation"];
    num? surfaceHeight = details["surfaceHeight"];
    num? surfaceWidth = details["surfaceWidth"];

    return new PreviewDetails(surfaceHeight, surfaceWidth, orientation, textureId);
  }

  static Future stop() {
    channelReader.setQrCodeHandler(null);
    return _channel.invokeMethod('stop').catchError(print);
  }

  static Future heartbeat() {
    return _channel.invokeMethod('heartbeat').catchError(print);
  }

  static Future<List<List<int>>?> getSupportedSizes() {
    return _channel.invokeMethod('getSupportedSizes').catchError(print) as Future<List<List<int>>?>;
  }
}

enum FrameRotation { none, ninetyCC, oneeighty, twoseventyCC }

typedef void QRCodeHandler(String qr);

class QrChannelReader {
  QrChannelReader(this.channel) {
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'qrRead':
          if (qrCodeHandler != null) {
            assert(call.arguments is String);
            qrCodeHandler!(call.arguments);
          }
          break;
        default:
          print("QrChannelHandler: unknown method call received at "
              "${call.method}");
      }
    });
  }

  void setQrCodeHandler(QRCodeHandler? qrch) {
    this.qrCodeHandler = qrch;
  }

  MethodChannel channel;
  QRCodeHandler? qrCodeHandler;
}
