import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/calculators/domain/usecases/inheritance_calculator.dart';

/// Looks up a single heir group by key. Fails if absent.
HeirShare _share(InheritanceResult r, String key) =>
    r.shares.firstWhere((s) => s.heirKey == key);

bool _has(InheritanceResult r, String key) =>
    r.shares.any((s) => s.heirKey == key);

/// All amounts (incl. unallocated) must sum to the estate.
void _expectConservation(InheritanceResult r) {
  final sum = r.shares.fold<double>(0, (a, s) => a + s.amount);
  expect(sum, closeTo(r.estate, 0.001),
      reason: 'amounts must sum to estate');
  final fracSum = r.shares.fold<double>(0, (a, s) => a + s.fraction);
  expect(fracSum, closeTo(1.0, 1e-9), reason: 'fractions must sum to 1');
}

void main() {
  group('InheritanceCalculator — classic textbook vectors', () {
    test("'Awl: husband + 2 daughters + father + mother → /15", () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 240000,
          hasHusband: true,
          hasFather: true,
          hasMother: true,
          daughters: 2,
        ),
      );
      expect(r.isAwl, isTrue);
      // daughters 8/15, husband 3/15, mother 2/15, father 2/15.
      expect(_share(r, 'daughter').fraction, closeTo(8 / 15, 1e-9));
      expect(_share(r, 'husband').fraction, closeTo(3 / 15, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(2 / 15, 1e-9));
      expect(_share(r, 'father').fraction, closeTo(2 / 15, 1e-9));
      // father takes only his 1/6 (now scaled), no extra residue.
      expect(_share(r, 'father').basis, ShareBasis.sixth);
      _expectConservation(r);
    });

    test('wife + son + daughter (estate 240000)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 240000,
          wives: 1,
          sons: 1,
          daughters: 1,
        ),
      );
      // wife 1/8 = 30000; residue 210000 split son:daughter 2:1.
      expect(_share(r, 'wife').amount, closeTo(30000, 0.001));
      expect(_share(r, 'wife').basis, ShareBasis.eighth);
      expect(_share(r, 'son').amount, closeTo(140000, 0.001));
      expect(_share(r, 'daughter').amount, closeTo(70000, 0.001));
      expect(r.isAwl, isFalse);
      expect(r.isRadd, isFalse);
      _expectConservation(r);
    });

    test('Umariyyatayn: husband + mother + father', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 240000,
          hasHusband: true,
          hasFather: true,
          hasMother: true,
        ),
      );
      // husband 1/2, mother 1/6 (=1/3 of remaining 1/2), father 1/3.
      expect(_share(r, 'husband').fraction, closeTo(1 / 2, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(1 / 6, 1e-9));
      expect(_share(r, 'father').fraction, closeTo(1 / 3, 1e-9));
      expect(r.note, 'umariyyatayn');
      _expectConservation(r);
    });

    test('Umariyyatayn: wife + mother + father', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 240000,
          wives: 1,
          hasFather: true,
          hasMother: true,
        ),
      );
      // wife 1/4; residue 3/4; mother 1/3 of 3/4 = 1/4; father 1/2.
      expect(_share(r, 'wife').fraction, closeTo(1 / 4, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(1 / 4, 1e-9));
      expect(_share(r, 'father').fraction, closeTo(1 / 2, 1e-9));
      expect(r.note, 'umariyyatayn');
      _expectConservation(r);
    });

    test('Radd: one daughter + mother (no spouse, no asaba)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, hasMother: true, daughters: 1),
      );
      // fard: daughter 1/2, mother 1/6 → sum 2/3, residue 1/3 radd 3:1.
      // → daughter 3/4, mother 1/4.
      expect(r.isRadd, isTrue);
      expect(_share(r, 'daughter').fraction, closeTo(3 / 4, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(1 / 4, 1e-9));
      // base labels preserved (set before radd).
      expect(_share(r, 'daughter').basis, ShareBasis.half);
      expect(_share(r, 'mother').basis, ShareBasis.sixth);
      _expectConservation(r);
    });

    test('Husband only → 1/2, rest unallocated (no radd to spouse)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 100000, hasHusband: true),
      );
      expect(_share(r, 'husband').amount, closeTo(50000, 0.001));
      expect(_has(r, 'unallocated'), isTrue);
      expect(_share(r, 'unallocated').amount, closeTo(50000, 0.001));
      expect(r.unallocated, closeTo(50000, 0.001));
      expect(r.note, 'unallocated');
      _expectConservation(r);
    });

    test('Mother + 2 full sisters (no descendant, no father) → radd', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, hasMother: true, fullSisters: 2),
      );
      // mother 1/6 (>=2 siblings), sisters 2/3 → sum 5/6, residue 1/6 radd.
      // radd ratio mother:sisters = (1/6):(2/3) = 1:4.
      // mother extra = 1/6 * 1/5 = 1/30 → 1/6 + 1/30 = 6/30 = 1/5.
      // sisters extra = 1/6 * 4/5 = 4/30 → 2/3 + 4/30 = 24/30 = 4/5.
      expect(r.isRadd, isTrue);
      expect(_share(r, 'mother').fraction, closeTo(1 / 5, 1e-9));
      expect(_share(r, 'sister').fraction, closeTo(4 / 5, 1e-9));
      _expectConservation(r);
    });

    test('Sons only: 3 sons split equally', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 300000, sons: 3),
      );
      // No fard sharer → sons take all as asaba, split equally.
      expect(_share(r, 'son').fraction, closeTo(1.0, 1e-9));
      expect(_share(r, 'son').amount, closeTo(300000, 0.001));
      expect(_share(r, 'son').count, 3);
      _expectConservation(r);
    });
  });

  group('InheritanceCalculator — additional cases', () {
    test('Wife + 2 sons (estate 320000): wife 1/8, sons share residue', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 320000, wives: 1, sons: 2),
      );
      expect(_share(r, 'wife').fraction, closeTo(1 / 8, 1e-9));
      expect(_share(r, 'son').fraction, closeTo(7 / 8, 1e-9));
      expect(_share(r, 'son').count, 2);
      _expectConservation(r);
    });

    test('2 wives share the 1/8 group row equally (count 2)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, wives: 2, sons: 1),
      );
      // group wife row = 1/8 regardless of count.
      expect(_share(r, 'wife').fraction, closeTo(1 / 8, 1e-9));
      expect(_share(r, 'wife').count, 2);
      expect(_share(r, 'wife').amount, closeTo(30000, 0.001));
      _expectConservation(r);
    });

    test('Father + mother + son: father & mother 1/6 each, son residue', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 360000,
          hasFather: true,
          hasMother: true,
          sons: 1,
        ),
      );
      expect(_share(r, 'father').fraction, closeTo(1 / 6, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(1 / 6, 1e-9));
      expect(_share(r, 'son').fraction, closeTo(4 / 6, 1e-9));
      _expectConservation(r);
    });

    test('Father + 1 daughter: daughter 1/2, father 1/6 + residue (asaba)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, hasFather: true, daughters: 1),
      );
      // daughter 1/2; father 1/6 fard + residue 1/3 = 1/2 total.
      expect(_share(r, 'daughter').fraction, closeTo(1 / 2, 1e-9));
      // father is ONE row: 1/6 fard + residue → 1/2.
      final fatherRows =
          r.shares.where((s) => s.heirKey == 'father').toList();
      expect(fatherRows, hasLength(1));
      expect(fatherRows.single.basis, ShareBasis.sixthPlusResiduary);
      expect(fatherRows.single.fraction, closeTo(1 / 2, 1e-9));
      expect(fatherRows.single.amount, closeTo(120000, 0.001));
      _expectConservation(r);
    });

    test('Father + 2 daughters + mother: no residue → single 1/6 row', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 60000,
          hasFather: true,
          hasMother: true,
          daughters: 2,
        ),
      );
      // 2/3 + 1/6 + 1/6 = 1 → nothing left for the father as asaba.
      final fatherRows =
          r.shares.where((s) => s.heirKey == 'father').toList();
      expect(fatherRows, hasLength(1));
      expect(fatherRows.single.basis, ShareBasis.sixth);
      expect(fatherRows.single.fraction, closeTo(1 / 6, 1e-9));
      _expectConservation(r);
    });

    test('Father blocks siblings: father + 2 brothers + mother', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 180000,
          hasFather: true,
          hasMother: true,
          fullBrothers: 2,
        ),
      );
      // siblings blocked; mother 1/6 (>=2 siblings present still block her up),
      // father takes residue. No brother row.
      expect(_has(r, 'brother'), isFalse);
      // mother: descendant false but siblingCount=2 → 1/6.
      expect(_share(r, 'mother').fraction, closeTo(1 / 6, 1e-9));
      expect(_share(r, 'father').fraction, closeTo(5 / 6, 1e-9));
      _expectConservation(r);
    });

    test("'Asaba ma'a al-ghair: daughter + full sister (no son, no father)",
        () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, daughters: 1, fullSisters: 1),
      );
      // daughter 1/2 fard; sister becomes residuary, takes residue 1/2.
      expect(_share(r, 'daughter').fraction, closeTo(1 / 2, 1e-9));
      expect(_share(r, 'sister').fraction, closeTo(1 / 2, 1e-9));
      _expectConservation(r);
    });

    test('Husband + 1 daughter: husband 1/4, daughter 1/2, radd to daughter',
        () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, hasHusband: true, daughters: 1),
      );
      // husband 1/4 (descendant), daughter 1/2; residue 1/4 → radd to
      // daughter only (spouse excluded). daughter 1/2 + 1/4 = 3/4.
      expect(_share(r, 'husband').fraction, closeTo(1 / 4, 1e-9));
      expect(_share(r, 'daughter').fraction, closeTo(3 / 4, 1e-9));
      expect(r.isRadd, isTrue);
      _expectConservation(r);
    });

    test('2 full sisters only → 2/3, residue radd (no spouse)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 240000, fullSisters: 2),
      );
      // sisters 2/3 fard, residue 1/3 radd to sisters → whole estate.
      expect(_share(r, 'sister').fraction, closeTo(1.0, 1e-9));
      expect(r.isRadd, isTrue);
      _expectConservation(r);
    });

    test('Negative / oversized inputs are clamped', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: -100,
          wives: 9, // capped to 4
          sons: -3, // clamped to 0
          daughters: 1,
        ),
      );
      expect(r.estate, 0);
      expect(_share(r, 'wife').count, 4);
      expect(_has(r, 'son'), isFalse);
      expect(_has(r, 'daughter'), isTrue);
    });

    test('Empty input → no shares, full estate unallocated', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 100000),
      );
      // No heirs at all: nothing allocated. Conservation still trivially ok
      // only if we surface the remainder; with no fard sharers and no asaba
      // there is simply nothing — estate stays with no rows.
      expect(r.shares.where((s) => s.heirKey != 'unallocated'), isEmpty);
    });

    test('Mother alone → 1/3 then radd to full estate', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: 90000, hasMother: true),
      );
      // mother 1/3 fard, residue 2/3 radd to mother → whole estate.
      expect(_share(r, 'mother').fraction, closeTo(1.0, 1e-9));
      expect(r.isRadd, isTrue);
      _expectConservation(r);
    });
  });

  group("InheritanceCalculator — 'Umariyyatayn with siblings", () {
    test('husband + father + mother + 1 full brother (120,000)', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 120000,
          hasHusband: true,
          hasFather: true,
          hasMother: true,
          fullBrothers: 1,
        ),
      );
      // One sibling is blocked by the father and does not reduce the mother.
      expect(r.note, 'umariyyatayn');
      expect(_share(r, 'husband').amount, closeTo(60000, 0.001));
      expect(_share(r, 'mother').amount, closeTo(20000, 0.001));
      expect(_share(r, 'father').amount, closeTo(40000, 0.001));
      expect(_has(r, 'brother'), isFalse);
      _expectConservation(r);
    });

    test('wife + father + mother + 1 full sister → 1/4, 1/4, 1/2', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 120000,
          wives: 1,
          hasFather: true,
          hasMother: true,
          fullSisters: 1,
        ),
      );
      expect(r.note, 'umariyyatayn');
      expect(_share(r, 'wife').fraction, closeTo(1 / 4, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(1 / 4, 1e-9));
      expect(_share(r, 'father').fraction, closeTo(1 / 2, 1e-9));
      expect(_has(r, 'sister'), isFalse);
      _expectConservation(r);
    });

    test('2+ siblings: mother stays at 1/6 (normal path)', () {
      for (final (brothers, sisters) in [(2, 0), (0, 2), (1, 1), (3, 2)]) {
        final r = InheritanceCalculator.calculate(
          InheritanceInput(
            estate: 120000,
            hasHusband: true,
            hasFather: true,
            hasMother: true,
            fullBrothers: brothers,
            fullSisters: sisters,
          ),
        );
        expect(r.note, isNot('umariyyatayn'));
        expect(_share(r, 'husband').fraction, closeTo(1 / 2, 1e-9));
        expect(_share(r, 'mother').fraction, closeTo(1 / 6, 1e-9));
        expect(_share(r, 'father').fraction, closeTo(1 / 3, 1e-9));
        expect(_has(r, 'brother') || _has(r, 'sister'), isFalse);
        _expectConservation(r);
      }
    });
  });
  group('InheritanceCalculator — review vectors', () {
    test("husband + 2 full sisters → 'awl 7/6", () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 70000,
          hasHusband: true,
          fullSisters: 2,
        ),
      );
      // husband 1/2 = 3/6, sisters 2/3 = 4/6 → raised to /7.
      expect(r.isAwl, isTrue);
      expect(_share(r, 'husband').fraction, closeTo(3 / 7, 1e-9));
      expect(_share(r, 'sister').fraction, closeTo(4 / 7, 1e-9));
      expect(_share(r, 'sister').basis, ShareBasis.twoThirdsShared);
      _expectConservation(r);
    });

    test("husband + mother + 2 full sisters → 'awl 8/6", () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 80000,
          hasHusband: true,
          hasMother: true,
          fullSisters: 2,
        ),
      );
      // husband 3/6, mother 1/6 (2 siblings), sisters 4/6 → raised to /8.
      expect(r.isAwl, isTrue);
      expect(_share(r, 'husband').fraction, closeTo(3 / 8, 1e-9));
      expect(_share(r, 'mother').fraction, closeTo(1 / 8, 1e-9));
      expect(_share(r, 'sister').fraction, closeTo(4 / 8, 1e-9));
      _expectConservation(r);
    });

    test('2 daughters + full brother + full sister: siblings residue 2:1', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 90000,
          daughters: 2,
          fullBrothers: 1,
          fullSisters: 1,
        ),
      );
      // daughters 2/3; residue 1/3 split brother:sister 2:1.
      expect(_share(r, 'daughter').fraction, closeTo(2 / 3, 1e-9));
      expect(_share(r, 'brother').fraction, closeTo(2 / 9, 1e-9));
      expect(_share(r, 'sister').fraction, closeTo(1 / 9, 1e-9));
      expect(_share(r, 'sister').basis, ShareBasis.residuaryTwoToOne);
      expect(r.isRadd, isFalse);
      _expectConservation(r);
    });

    test('son blocks full siblings', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 100000,
          sons: 1,
          fullBrothers: 2,
          fullSisters: 2,
        ),
      );
      expect(_share(r, 'son').fraction, closeTo(1.0, 1e-9));
      expect(_has(r, 'brother') || _has(r, 'sister'), isFalse);
      _expectConservation(r);
    });

    test('mother + exactly 1 sibling, no father → mother 1/3', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 90000,
          hasMother: true,
          fullBrothers: 1,
        ),
      );
      expect(_share(r, 'mother').fraction, closeTo(1 / 3, 1e-9));
      expect(_share(r, 'mother').basis, ShareBasis.third);
      expect(_share(r, 'brother').fraction, closeTo(2 / 3, 1e-9));
      expect(r.isRadd, isFalse);
      _expectConservation(r);
    });

    test('out-of-scope relatives → no distribution', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(
          estate: 100000,
          hasHusband: true,
          hasOtherRelatives: true,
        ),
      );
      expect(r.outOfScope, isTrue);
      expect(r.note, 'outOfScope');
      expect(r.shares, isEmpty);
      expect(r.isRadd, isFalse);
      expect(r.unallocated, 0);
    });

    test('non-finite estate counts as 0', () {
      final r = InheritanceCalculator.calculate(
        const InheritanceInput(estate: double.nan, sons: 1),
      );
      expect(r.estate, 0);
      expect(_share(r, 'son').amount, 0);
    });
  });
}
