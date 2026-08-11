import 'package:flutter_test/flutter_test.dart';
import 'package:sisov_mobile/core/db/local_database.dart';
import 'package:sisov_mobile/features/animals/models/slaughter_registration_model.dart';

void main() {
  group('slaughter batch contract', () {
    test('serializes one idempotent batch request with per-animal IG data', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.igOwn,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Abatedouro Tauá',
          frigorificoCode: 'SIM-123',
          proofOfAge: 'RASTREABILIDADE',
          carcassColor: 'VERMELHA_ROSADA',
          fatColor: 'BRANCA',
          meatTexture: 'FINA',
          hasBoletimEmbarque: true,
          hasGTA: true,
          hasHTA: true,
          confirmWelfare: true,
          confirmSanity: true,
          geographicOriginConfirmed: true,
          preSlaughterFastingConfirmed: true,
        ),
        items: const [
          SlaughterBatchItem(
            animalId: 'animal-1',
            carcassWeight: 18.5,
            carcassYield: 45,
          ),
          SlaughterBatchItem(
            animalId: 'animal-2',
            carcassWeight: 20,
            carcassYield: 47,
          ),
        ],
      );

      expect(request.validate(), isNull);
      expect(request.toJson()['mode'], 'IG_OWN');
      expect(request.toJson()['items'], hasLength(2));
      expect(request.toJson()['slaughterLocation'], 'Abatedouro Tauá');
      expect((request.toJson()['items'] as List).first['carcassWeight'], 18.5);
    });

    test('standard mode omits the technical questionnaire', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.standard,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Fazenda Boa Vista',
        ),
        items: const [SlaughterBatchItem(animalId: 'animal-1')],
      );

      final payload = request.toJson();
      expect(request.validate(), isNull);
      expect(payload, isNot(contains('proofOfAge')));
      expect(payload, isNot(contains('confirmWelfare')));
    });

    test('rejects invalid IG carcass yield', () {
      final request = SlaughterBatchRequest(
        mode: SlaughterMode.igOwn,
        commonData: SlaughterCommonData(
          slaughterDate: DateTime.utc(2026, 8, 11),
          slaughterLocation: 'Abatedouro Tauá',
        ),
        items: const [
          SlaughterBatchItem(
            animalId: 'animal-1',
            carcassWeight: 18,
            carcassYield: 41.9,
          ),
        ],
      );

      expect(request.validate(), contains('42%'));
    });
  });

  test('SQLite v3 migration preserves legacy rows by only adding columns', () {
    expect(LocalDatabase.animalV3MigrationStatements, hasLength(7));
    expect(
      LocalDatabase.animalV3MigrationStatements,
      everyElement(startsWith('ALTER TABLE animals ADD COLUMN')),
    );
  });
}
