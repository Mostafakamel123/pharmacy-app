import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pharmacy_app/core/helpers/local_storage_helper.dart';
import 'package:pharmacy_app/core/network/api_endpoints.dart';

void main() {
  group('Prescriptions API E2E Integration Flow Test', () {
    late ApiEndpoints apiEndpoints;
    String? prescriptionId;
    String? replyId;
    
    // Constant IDs for testing
    const String testPharmacyId = 'cc29f0a9-9676-4949-5e44-08debf09c68b'; // Guid from documentation
    
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageHelper.init();
      apiEndpoints = ApiEndpoints();
    });

    test('Step 1: Upload a prescription (POST /api/Prescriptions)', () async {
      // Create a temporary sample file
      final tempFile = File('${Directory.systemTemp.path}/test_prescription.jpeg');
      await tempFile.writeAsBytes(List.generate(100, (i) => i));

      try {
        final result = await apiEndpoints.uploadPrescription(
          filePath: tempFile.path,
          notes: 'Test Prescription Notes',
          latitude: 30.0444,
          longitude: 31.2357,
        );

        expect(result, isNotNull);
        expect(result.containsKey('prescriptionId') || result.containsKey('id'), isTrue);
        prescriptionId = (result['prescriptionId'] ?? result['id']) as String;
        print('✅ Step 1: Upload Successful! Prescription ID: $prescriptionId');
      } catch (e) {
        fail('Step 1 Failed: $e');
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('Step 2: Get nearby prescriptions (GET /api/Prescriptions/nearby/{pharmacyId})', () async {
      if (prescriptionId == null) return;
      try {
        final list = await apiEndpoints.getNearbyPrescriptions(
          pharmacyId: testPharmacyId,
          radius: 5.0,
        );

        expect(list, isNotNull);
        print('✅ Step 2: Fetch Nearby Successful! Found ${list.length} prescriptions.');
      } catch (e) {
        fail('Step 2 Failed: $e');
      }
    });

    test('Step 3: Submit price offer/reply (POST /api/Prescriptions/{id}/replies)', () async {
      if (prescriptionId == null) return;
      try {
        final result = await apiEndpoints.replyToPrescription(
          prescriptionId: prescriptionId!,
          pharmacyId: testPharmacyId,
          message: 'العلاج متوفر جاهز للشحن فوراً',
          totalPrice: 150.0,
          isAvailable: true,
        );

        expect(result, isNotNull);
        expect(result.containsKey('replyId') || result.containsKey('id'), isTrue);
        replyId = (result['replyId'] ?? result['id']) as String;
        print('✅ Step 3: Price offer submitted successfully! Reply ID: $replyId');
      } catch (e) {
        fail('Step 3 Failed: $e');
      }
    });

    test('Step 4: Get my prescriptions (GET /api/Prescriptions/my-prescriptions)', () async {
      try {
        final list = await apiEndpoints.getMyPrescriptions(pageNumber: 1, pageSize: 10);
        expect(list, isNotNull);
        print('✅ Step 4: Fetch Patient History Successful! Found ${list.length} records.');
      } catch (e) {
        fail('Step 4 Failed: $e');
      }
    });

    test('Step 5: Accept offer and close request (PUT /api/Prescriptions/{pId}/replies/{rId}/accept)', () async {
      if (prescriptionId == null || replyId == null) return;
      try {
        await apiEndpoints.acceptPharmacyReply(
          prescriptionId: prescriptionId!,
          replyId: replyId!,
        );
        print('✅ Step 5: Offer accepted successfully!');
      } catch (e) {
        fail('Step 5 Failed: $e');
      }
    });

    test('Step 6: Update status (PATCH /api/Prescriptions/{id}/status)', () async {
      if (prescriptionId == null) return;
      try {
        await apiEndpoints.updatePrescriptionStatus(
          id: prescriptionId!,
          status: 2, // 2 = Preparing
        );
        print('✅ Step 6: Status updated successfully!');
      } catch (e) {
        fail('Step 6 Failed: $e');
      }
    });

    test('Step 7: Update prescription (PUT /api/Prescriptions/{id})', () async {
      if (prescriptionId == null) return;
      try {
        final result = await apiEndpoints.updatePrescription(
          id: prescriptionId!,
          notes: 'Updated Prescription Notes',
        );
        expect(result, isNotNull);
        print('✅ Step 7: Prescription updated successfully!');
      } catch (e) {
        fail('Step 7 Failed: $e');
      }
    });

    test('Step 8: Delete prescription (DELETE /api/Prescriptions/{id})', () async {
      if (prescriptionId == null) return;
      try {
        await apiEndpoints.deletePrescription(id: prescriptionId!);
        print('✅ Step 8: Prescription deleted successfully!');
      } catch (e) {
        fail('Step 8 Failed: $e');
      }
    });
  });
}
