part of serial;

@JS()
@anonymous
abstract class _SerialPortFilter {
  /// The external constructor.
  external factory _SerialPortFilter({
    int? usbVendorId,
    int? usbProductId,
  });

  external int? get usbVendorId;
  external set usbVendorId(int? v);

  external int? get usbProductId;
  external set usbProductId(int? v);
}
