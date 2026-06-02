import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Resolves coordinates to a user-friendly name/address.
  /// Falls back to null if geocoding fails.
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Attempt to set locale identifier to Arabic for regional display
      try {
        await setLocaleIdentifier('ar');
      } catch (e) {
        debugPrint('GeocodingService: Failed to set locale to ar, using system locale: $e');
      }

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final List<String> addressParts = [];

        // Build a user-friendly name from details
        // Check street or name
        if (place.street != null &&
            place.street!.isNotEmpty &&
            !place.street!.contains('+') &&
            place.street != place.name) {
          addressParts.add(place.street!);
        } else if (place.name != null &&
                   place.name!.isNotEmpty &&
                   !place.name!.contains('+')) {
          addressParts.add(place.name!);
        }

        // Check sub-locality / neighborhood
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }

        // Check locality / city
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        // Check country if everything else is empty
        if (addressParts.isEmpty && place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Error in GeocodingService: $e');
    }
    return null;
  }
}
