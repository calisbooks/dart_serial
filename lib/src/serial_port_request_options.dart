part of serial;

/// Options for [SerialPortExtensions.requestPort].
@JS()
@anonymous
abstract class _SerialPortRequestOptions {
  /// The external constructor.
  external factory _SerialPortRequestOptions({
    List<_SerialPortFilter> filters = const [],
  });

  external List<_SerialPortFilter> get filters;
  external set filters(List<_SerialPortFilter> v);
}
