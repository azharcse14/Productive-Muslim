/// Islamic inheritance (Faraid / Mirath) calculator — classical Sunni rules.
///
/// This is a *pure-domain* implementation (no Flutter imports). All share
/// arithmetic is done with exact integer fractions ([_Fraction]) over a
/// common denominator — never floating point — so the fixed shares ('awl,
/// radd, 2:1 splits) are computed precisely. Floating point is used only at
/// the very end to turn a final fraction into a money amount.
///
/// SCOPE (v1): a common, solid set of heirs only —
///   husband, wife (0..4, share split equally), father, mother,
///   sons, daughters, full brothers, full sisters.
/// OUT OF SCOPE (v1), documented deliberately: grandparents, grandchildren
/// (son's children), uterine/consanguine siblings, uncles, nephews, and the
/// many `hajb` (blocking) interactions they introduce. The UI must show a
/// disclaimer to consult a qualified scholar.
library;

/// Greatest common divisor (Euclid). Operates on magnitudes.
int _gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final t = b;
    b = a % b;
    a = t;
  }
  return a == 0 ? 1 : a;
}

/// Exact, auto-reduced rational number. Denominator is kept positive.
class _Fraction {
  factory _Fraction(int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError('Fraction denominator cannot be zero');
    }
    if (denominator < 0) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final g = _gcd(numerator, denominator);
    return _Fraction._(numerator ~/ g, denominator ~/ g);
  }

  const _Fraction._(this.num, this.den);

  static const zero = _Fraction._(0, 1);

  final int num;
  final int den;

  bool get isZero => num == 0;

  _Fraction operator +(_Fraction o) =>
      _Fraction(num * o.den + o.num * den, den * o.den);

  _Fraction operator -(_Fraction o) =>
      _Fraction(num * o.den - o.num * den, den * o.den);

  _Fraction operator *(_Fraction o) => _Fraction(num * o.num, den * o.den);

  /// Compares against another fraction; returns -1, 0 or 1.
  int compareTo(_Fraction o) => (num * o.den).compareTo(o.num * den);

  bool greaterThan(_Fraction o) => compareTo(o) > 0;

  double get toDouble => num / den;
}

/// Inputs for an inheritance calculation. Every count is clamped to a sane
/// range in [InheritanceCalculator.calculate]; callers may pass raw values.
final class InheritanceInput {
  const InheritanceInput({
    this.estate = 0,
    this.hasHusband = false,
    this.wives = 0,
    this.hasFather = false,
    this.hasMother = false,
    this.sons = 0,
    this.daughters = 0,
    this.fullBrothers = 0,
    this.fullSisters = 0,
  });

  /// Net distributable estate (after debts/bequests) in the user's currency.
  final double estate;

  final bool hasHusband;

  /// Number of surviving wives (0..4). They share one group fard equally.
  final int wives;

  final bool hasFather;
  final bool hasMother;
  final int sons;
  final int daughters;
  final int fullBrothers;
  final int fullSisters;
}

/// One heir group's resolved share.
final class HeirShare {
  const HeirShare({
    required this.heirKey,
    required this.count,
    required this.shareLabel,
    required this.fraction,
    required this.amount,
  });

  /// One of: husband, wife, father, mother, son, daughter, brother, sister,
  /// unallocated.
  final String heirKey;

  /// Number of individuals in this group (e.g. 3 sons). 1 for single heirs.
  final int count;

  /// Human-facing classical label, e.g. "1/6", "2/3 (shared)", "asaba".
  final String shareLabel;

  /// Decimal of this group's TOTAL share of the estate (group, not per head).
  final double fraction;

  /// [fraction] * estate.
  final double amount;
}

/// Full result of an inheritance distribution.
final class InheritanceResult {
  const InheritanceResult({
    required this.estate,
    required this.shares,
    required this.isAwl,
    required this.isRadd,
    required this.unallocated,
    required this.note,
  });

  final double estate;
  final List<HeirShare> shares;

  /// True when the fixed shares exceeded the estate and were scaled down.
  final bool isAwl;

  /// True when a surplus was returned proportionally to the fard sharers.
  final bool isRadd;

  /// Residue that could not be allocated to any heir in scope.
  final double unallocated;

  /// Short machine note key describing any special outcome (may be empty):
  /// 'awl', 'radd', 'unallocated', 'umariyyatayn', or ''.
  final String note;
}

/// Internal working record for a heir group before money is computed.
///
/// As a residuary (asaba) the base behaviour is "take the whole residue"
/// (used for a lone father). Subclasses override [distribute] for 2:1 splits.
class _Allocation {
  _Allocation(this.heirKey, this.count, this.label, this.fraction);
  final String heirKey;
  final int count;
  String label;
  _Fraction fraction;

  /// Returns the heir rows produced when this group absorbs [residue] as a
  /// residuary. For a fixed-share father in 'Umariyyatayn the residue is
  /// ignored (his amount is already fixed in [fraction]).
  List<_Allocation> distribute(_Fraction residue) {
    // Lone residuary: takes the whole residue on top of any fixed amount.
    final f = (label == 'asaba' && fraction.isZero)
        ? residue
        : fraction + residue;
    return [_Allocation(heirKey, count, label, f)];
  }
}

/// Pure Faraid math. See file header for scope.
abstract final class InheritanceCalculator {
  static int _c(int v) => v < 0 ? 0 : v;

  /// Computes the inheritance distribution for [input].
  static InheritanceResult calculate(InheritanceInput input) {
    final estate = input.estate < 0 ? 0.0 : input.estate;

    final wives = _c(input.wives).clamp(0, 4);
    final hasWife = wives > 0;
    final hasHusband = input.hasHusband;
    final hasFather = input.hasFather;
    final hasMother = input.hasMother;
    final sons = _c(input.sons);
    final daughters = _c(input.daughters);
    final brothers = _c(input.fullBrothers);
    final sisters = _c(input.fullSisters);

    final descendant = sons > 0 || daughters > 0;
    final siblingCount = brothers + sisters;

    // Father blocks ALL full siblings; siblings also act only when no son.
    final siblingsActive = !hasFather && sons == 0 && (brothers > 0 || sisters > 0);

    // --- Fixed (fard) shares -------------------------------------------
    final fard = <_Allocation>[];
    // Asaba (residuary) groups get the leftover after fard.
    _Allocation? asaba;

    // 1. Spouse fard.
    if (hasHusband) {
      final f = descendant ? _Fraction(1, 4) : _Fraction(1, 2);
      fard.add(_Allocation('husband', 1, descendant ? '1/4' : '1/2', f));
    }
    if (hasWife) {
      final f = descendant ? _Fraction(1, 8) : _Fraction(1, 4);
      fard.add(_Allocation('wife', wives, descendant ? '1/8' : '1/4', f));
    }

    // 2. 'Umariyyatayn detection: spouse + father + mother, no descendant,
    //    and fewer than two siblings. A single sibling is blocked by the
    //    father and does not reduce the mother, so the case still applies;
    //    2+ siblings reduce the mother to 1/6 (normal path). Mother takes
    //    1/3 of the residue after the spouse; father takes the rest.
    final spousePresent = hasHusband || hasWife;
    final isUmariyyatayn = spousePresent &&
        hasFather &&
        hasMother &&
        !descendant &&
        siblingCount < 2;

    var note = '';

    if (isUmariyyatayn) {
      // Spouse fard already added above. Residue after spouse:
      final spouseFraction = fard.first.fraction; // exactly one spouse row
      final residue = _Fraction(1, 1) - spouseFraction;
      final motherShare = residue * _Fraction(1, 3);
      final fatherShare = residue - motherShare; // = 2/3 of residue
      fard.add(_Allocation('mother', 1, '1/3 (of residue)', motherShare));
      // Father is residuary here, but in this special case his amount equals
      // the leftover exactly; treat it as a fixed row so sumFard hits 1 and
      // no further residue/asaba/radd logic fires.
      fard.add(_Allocation('father', 1, 'asaba', fatherShare));
      note = 'umariyyatayn';
      return _finalize(
        estate: estate,
        fard: fard,
        asaba: null,
        isAwl: false,
        isRadd: false,
        note: note,
        spouseKeys: const {'husband', 'wife'},
      );
    }

    // 2b. Mother (normal).
    if (hasMother) {
      final oneSixth = descendant || siblingCount >= 2;
      final f = oneSixth ? _Fraction(1, 6) : _Fraction(1, 3);
      fard.add(_Allocation('mother', 1, oneSixth ? '1/6' : '1/3', f));
    }

    // 3. Father.
    if (hasFather) {
      if (descendant) {
        // Always 1/6 fard. Additionally residuary when no SON (daughters
        // only) — he absorbs whatever residue remains.
        fard.add(_Allocation('father', 1, '1/6', _Fraction(1, 6)));
        if (sons == 0) {
          asaba = _Allocation('father', 1, '1/6 + asaba', _Fraction.zero);
        }
      } else {
        // No descendant: father is pure residuary.
        asaba = _Allocation('father', 1, 'asaba', _Fraction.zero);
      }
    }

    // 4. Children.
    if (sons > 0) {
      // Sons + daughters together are asaba 2:1. No fard for daughters.
      asaba = _ChildrenAsaba(sons, daughters, sons * 2 + daughters);
    } else if (daughters > 0) {
      final f = daughters == 1 ? _Fraction(1, 2) : _Fraction(2, 3);
      fard.add(
        _Allocation(
          'daughter',
          daughters,
          daughters == 1 ? '1/2' : '2/3 (shared)',
          f,
        ),
      );
    }

    // 5. Full siblings — only when no son and no father.
    if (siblingsActive) {
      if (daughters > 0) {
        // Siblings take the residue after the daughters' fard: with brothers,
        // sisters are 'asaba bil-ghayr (2:1 with the brothers); sisters alone
        // with daughters are 'asaba ma'a al-ghayr.
        asaba = _SiblingsAsaba(brothers, sisters);
      } else {
        // No descendant, no father, no son.
        if (brothers > 0) {
          asaba = _SiblingsAsaba(brothers, sisters);
        } else {
          // Only sisters: 1 → 1/2, 2+ → 2/3.
          final f = sisters == 1 ? _Fraction(1, 2) : _Fraction(2, 3);
          fard.add(
            _Allocation(
              'sister',
              sisters,
              sisters == 1 ? '1/2' : '2/3 (shared)',
              f,
            ),
          );
        }
      }
    }

    return _finalize(
      estate: estate,
      fard: fard,
      asaba: asaba,
      isAwl: false,
      isRadd: false,
      note: note,
      spouseKeys: const {'husband', 'wife'},
    );
  }

  /// Resolves 'awl / residue / asaba / radd, then turns fractions into money.
  static InheritanceResult _finalize({
    required double estate,
    required List<_Allocation> fard,
    required _Allocation? asaba,
    required bool isAwl,
    required bool isRadd,
    required String note,
    required Set<String> spouseKeys,
  }) {
    // Sum of fard shares.
    var sumFard = _Fraction.zero;
    for (final a in fard) {
      sumFard = sumFard + a.fraction;
    }

    final one = _Fraction(1, 1);
    final List<_Allocation> finalAllocs = [];
    var unallocatedFraction = _Fraction.zero;

    if (sumFard.greaterThan(one)) {
      // ---- 'Awl: scale every fard by common denominator = sum of nums. ----
      // Put all on a common denominator first.
      var lcm = 1;
      for (final a in fard) {
        lcm = lcm ~/ _gcd(lcm, a.fraction.den) * a.fraction.den;
      }
      var sumNum = 0;
      for (final a in fard) {
        sumNum += a.fraction.num * (lcm ~/ a.fraction.den);
      }
      for (final a in fard) {
        final numerator = a.fraction.num * (lcm ~/ a.fraction.den);
        finalAllocs.add(
          _Allocation(a.heirKey, a.count, a.label, _Fraction(numerator, sumNum)),
        );
      }
      isAwl = true;
      note = 'awl';
      // No residue, no asaba payout under 'awl.
    } else {
      // Keep fard as-is.
      finalAllocs.addAll(fard);
      final residue = one - sumFard;

      final fardRow = asaba == null
          ? null
          : finalAllocs.where((a) => a.heirKey == asaba.heirKey).firstOrNull;
      if (fardRow != null) {
        // Father with daughters only: his 1/6 fard and the residue are one
        // row, not two.
        if (residue.num > 0) {
          fardRow.fraction = fardRow.fraction + residue;
          fardRow.label = asaba!.label;
        }
      } else if (asaba != null) {
        // Asaba takes the full residue (per its split rule).
        finalAllocs.addAll(asaba.distribute(residue));
      } else if (residue.num > 0) {
        // No residuary heir.
        final raddEligible = fard
            .where((a) => !spouseKeys.contains(a.heirKey))
            .toList();
        if (raddEligible.isNotEmpty) {
          // ---- Radd: distribute residue proportionally to non-spouse fard.
          var raddBase = _Fraction.zero;
          for (final a in raddEligible) {
            raddBase = raddBase + a.fraction;
          }
          for (final a in finalAllocs) {
            if (spouseKeys.contains(a.heirKey)) continue;
            // extra = residue * (a.fraction / raddBase)
            final ratio = _divide(a.fraction, raddBase);
            a.fraction = a.fraction + residue * ratio;
          }
          isRadd = true;
          note = note.isEmpty ? 'radd' : note;
        } else {
          // Only the spouse is a fard sharer; surplus is unallocated.
          unallocatedFraction = residue;
          note = note.isEmpty ? 'unallocated' : note;
        }
      }
    }

    // ---- Money stage (fraction -> amount). --------------------------------
    final shares = <HeirShare>[];
    for (final a in finalAllocs) {
      shares.add(
        HeirShare(
          heirKey: a.heirKey,
          count: a.count,
          shareLabel: a.label,
          fraction: a.fraction.toDouble,
          amount: a.fraction.toDouble * estate,
        ),
      );
    }
    if (!unallocatedFraction.isZero) {
      shares.add(
        HeirShare(
          heirKey: 'unallocated',
          count: 0,
          shareLabel: 'unallocated',
          fraction: unallocatedFraction.toDouble,
          amount: unallocatedFraction.toDouble * estate,
        ),
      );
    }

    return InheritanceResult(
      estate: estate,
      shares: shares,
      isAwl: isAwl,
      isRadd: isRadd,
      unallocated: unallocatedFraction.toDouble * estate,
      note: note,
    );
  }

  static _Fraction _divide(_Fraction a, _Fraction b) =>
      _Fraction(a.num * b.den, a.den * b.num);
}

/// Children residuary: sons + daughters split residue 2:1.
class _ChildrenAsaba extends _Allocation {
  _ChildrenAsaba(this.sons, this.daughters, this.units)
      : super('son', sons, 'asaba (2:1)', _Fraction.zero);

  final int sons;
  final int daughters;
  final int units; // sons*2 + daughters

  @override
  List<_Allocation> distribute(_Fraction residue) {
    final out = <_Allocation>[];
    if (sons > 0) {
      final f = residue * _Fraction(sons * 2, units);
      out.add(_Allocation('son', sons, 'asaba (2:1)', f));
    }
    if (daughters > 0) {
      final f = residue * _Fraction(daughters, units);
      out.add(_Allocation('daughter', daughters, 'asaba (2:1)', f));
    }
    return out;
  }
}

/// Full-sibling residuary: brothers + sisters split residue 2:1 (or sisters
/// alone split equally). Used for 'asaba and 'asaba ma'a al-ghair.
class _SiblingsAsaba extends _Allocation {
  _SiblingsAsaba(this.brothers, this.sisters)
      : units = brothers * 2 + sisters,
        super('brother', brothers, 'asaba (2:1)', _Fraction.zero);

  final int brothers;
  final int sisters;
  final int units;

  @override
  List<_Allocation> distribute(_Fraction residue) {
    final out = <_Allocation>[];
    if (brothers > 0) {
      final f = residue * _Fraction(brothers * 2, units);
      out.add(_Allocation('brother', brothers, 'asaba (2:1)', f));
    }
    if (sisters > 0) {
      final label = brothers > 0 ? 'asaba (2:1)' : 'asaba';
      final f = residue * _Fraction(sisters, units);
      out.add(_Allocation('sister', sisters, label, f));
    }
    return out;
  }
}
