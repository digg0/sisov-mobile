import 'package:flutter_test/flutter_test.dart';
import 'package:sisov_mobile/core/db/local_database.dart';
import 'package:sisov_mobile/features/animals/models/slaughter_registration_model.dart';

void main() {
  group('slaughter batch contract', () {
    const location = {
      'latitude': -6.003,
      'longitude': -40.292,
      'accuracy': 8.0,
      'capturedAt': '2026-08-11T12:00:00.000Z',
    };

    test('serializes a standard slaughter batch without IG data', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.standard,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Fazenda Boa Vista',
          location: location,
        ),
        items: const [
          SlaughterBatchItem(animalId: 'animal-1'),
          SlaughterBatchItem(animalId: 'animal-2'),
        ],
      );

      expect(request.validate(), isNull);
      expect(request.toJson()['mode'], 'STANDARD');
      expect(request.toJson()['items'], hasLength(2));
      expect(request.toJson()['slaughterLocation'], 'Fazenda Boa Vista');
    });

    test('standard mode omits the technical questionnaire', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.standard,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Fazenda Boa Vista',
          location: location,
        ),
        items: const [SlaughterBatchItem(animalId: 'animal-1')],
      );

      final payload = request.toJson();
      expect(request.validate(), isNull);
      expect(payload, isNot(contains('proofOfAge')));
      expect(payload, isNot(contains('confirmWelfare')));
    });

    test('slaughterhouse IG remains pending without own IG questionnaire', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.igSlaughterhouse,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Abatedouro Tauá',
          location: location,
          frigorificoCode: 'SIF-123',
        ),
        items: const [SlaughterBatchItem(animalId: 'animal-1')],
      );

      final payload = request.toJson();
      expect(request.validate(), isNull);
      expect(payload['mode'], 'IG_SLAUGHTERHOUSE');
      expect(payload['frigorificoCode'], 'SIF-123');
      expect(payload, isNot(contains('proofOfAge')));
    });

    test('rejects a slaughter batch without captured location', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.standard,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Fazenda Boa Vista',
        ),
        items: const [SlaughterBatchItem(animalId: 'animal-1')],
      );

      expect(request.validate(), contains('localização'));
    });
  });

  test('SQLite v3 migration preserves legacy rows by only adding columns', () {
    expect(LocalDatabase.animalV3MigrationStatements, hasLength(6));
    expect(
      LocalDatabase.animalV3MigrationStatements,
      everyElement(startsWith('ALTER TABLE animals ADD COLUMN')),
    );
  });

  test(
    'SQLite v4 migration removes the discontinued weaning weight column',
    () {
      final migration = LocalDatabase.animalV4MigrationStatements.join(' ');
      expect(migration, isNot(contains('weaning_weight')));
      expect(migration, contains('DROP TABLE animals'));
      expect(migration, contains('RENAME TO animals'));
    },
  );
}
