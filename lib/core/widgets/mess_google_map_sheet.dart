import 'dart:async';

import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/helpers/google_maps_availability.dart';
import 'package:mess_pilot/features/membership/domain/helpers/mess_map_uri.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MessMapLocation {
  final double latitude;
  final double longitude;
  final String address;

  const MessMapLocation({required this.latitude, required this.longitude, this.address = ''});
}

Future<MessMapLocation?> showMessGoogleMap({required BuildContext context, double? latitude, double? longitude, String address = '', bool editable = false, Future<List<MessMapLocation>> Function(String query)? onSearch}) {
  if (!isGoogleMapsAvailable()) {
    context.showErrorSnackBar(context.local.mapOpenFailed);
    return Future.value();
  }
  final content = MessGoogleMapSheet(latitude: latitude, longitude: longitude, address: address, editable: editable, onSearch: onSearch);
  if (ResponsiveHelper.isDesktop(context)) {
    return showDialog<MessMapLocation>(context: context, builder: (_) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720), child: content)));
  }
  return showModalBottomSheet<MessMapLocation>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => SizedBox(height: MediaQuery.sizeOf(context).height * .9, child: content));
}

class MessGoogleMapSheet extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String address;
  final bool editable;
  final Future<List<MessMapLocation>> Function(String query)? onSearch;

  const MessGoogleMapSheet({super.key, this.latitude, this.longitude, this.address = '', this.editable = false, this.onSearch});

  @override
  State<MessGoogleMapSheet> createState() => _MessGoogleMapSheetState();
}

class _MessGoogleMapSheetState extends State<MessGoogleMapSheet> {
  static const _dhaka = LatLng(23.8103, 90.4125);
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  late LatLng _position;
  String _address = '';
  bool _searching = false;
  bool _hasPosition = false;
  Timer? _searchDebounce;
  int _searchVersion = 0;
  List<MessMapLocation> _results = const [];

  @override
  void initState() {
    super.initState();
    _position = widget.latitude != null && widget.longitude != null ? LatLng(widget.latitude!, widget.longitude!) : _dhaka;
    _address = widget.address;
    _hasPosition = widget.latitude != null && widget.longitude != null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _search() async {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3 || widget.onSearch == null) return;
    final version = ++_searchVersion;
    setState(() => _searching = true);
    try {
      final results = await widget.onSearch!(query);
      if (mounted && version == _searchVersion) setState(() => _results = results);
    } catch (error) {
      if (mounted && version == _searchVersion) context.showErrorSnackBar(error);
    } finally {
      if (mounted && version == _searchVersion) setState(() => _searching = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    ++_searchVersion;
    setState(() {
      _results = const [];
      _searching = false;
    });
    if (value.trim().length >= 3) {
      _searchDebounce = Timer(const Duration(milliseconds: 500), _search);
    }
  }

  Future<void> _selectResult(MessMapLocation result) async {
    _searchDebounce?.cancel();
    ++_searchVersion;
    FocusScope.of(context).unfocus();
    final position = LatLng(result.latitude, result.longitude);
    setState(() {
      _position = position;
      _address = result.address;
      _hasPosition = true;
      _results = const [];
      _searching = false;
      _searchController.text = result.address;
    });
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
  }

  Future<void> _openExternalMap() async {
    final uri = messMapUri(latitude: _hasPosition ? _position.latitude : null, longitude: _hasPosition ? _position.longitude : null, address: _address);
    final opened = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) context.showErrorSnackBar(context.local.mapOpenFailed);
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedPosition = widget.latitude != null && widget.longitude != null;
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: _position, zoom: hasSavedPosition ? 16 : 12),
                    onMapCreated: (controller) => _mapController = controller,
                    onCameraMove: widget.editable ? (camera) {
                      _position = camera.target;
                      _hasPosition = true;
                    } : null,
                    markers: widget.editable || !hasSavedPosition ? const {} : {Marker(markerId: const MarkerId('mess'), position: _position)},
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                if (widget.editable) const Center(child: IgnorePointer(child: Padding(padding: EdgeInsets.only(bottom: 42), child: Icon(Icons.location_pin, size: 48, color: Colors.red)))),
                if (widget.editable)
                  PositionedDirectional(
                    top: Dimensions.paddingSizeDefault,
                    start: Dimensions.paddingSizeDefault,
                    end: 64,
                    child: Column(
                      children: [
                        Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(8),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                            decoration: InputDecoration(hintText: context.local.searchLocation, prefixIcon: const Icon(Icons.search), suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward_rounded)), border: InputBorder.none),
                          ),
                        ),
                        if (_results.isNotEmpty)
                          Material(
                            elevation: 3,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ListView.separated(shrinkWrap: true, itemCount: _results.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, index) {
                                final result = _results[index];
                                return ListTile(dense: true, leading: const Icon(Icons.location_on_outlined), title: Text(result.address, maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => _selectResult(result));
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                PositionedDirectional(top: Dimensions.paddingSizeDefault, end: Dimensions.paddingSizeDefault, child: Material(elevation: 3, borderRadius: BorderRadius.circular(8), child: IconButton(onPressed: _openExternalMap, tooltip: context.local.showOnGoogleMaps, icon: const Icon(Icons.open_in_new_rounded)))),
                PositionedDirectional(top: widget.editable ? 72 : Dimensions.paddingSizeDefault, start: widget.editable ? null : Dimensions.paddingSizeDefault, end: widget.editable ? Dimensions.paddingSizeDefault : null, child: Material(elevation: 3, borderRadius: BorderRadius.circular(8), child: IconButton(onPressed: () => Navigator.of(context).pop(), tooltip: MaterialLocalizations.of(context).closeButtonTooltip, icon: const Icon(Icons.close_rounded)))),
              ],
            ),
          ),
          if (widget.editable)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_address.isEmpty ? context.local.dragMapToChoose : _address, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    FilledButton.icon(onPressed: () => Navigator.of(context).pop(MessMapLocation(latitude: _position.latitude, longitude: _position.longitude, address: _address)), icon: const Icon(Icons.check_rounded), label: Text(context.local.useThisLocation)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

