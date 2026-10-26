import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Immutable money value stored in minor units.
@immutable
class Money extends Equatable {
  const Money(this.amountMinor, {this.currency = 'IDR'});

  final int amountMinor;
  final String currency;

  static const Money zero = Money(0);

  int get decimals => currency.toUpperCase() == 'IDR' ? 0 : 2;

  double get asDouble => amountMinor / math.pow(10, decimals).toDouble();

  bool get isZero => amountMinor == 0;

  bool get isNegative => amountMinor < 0;

  bool get isPositive => amountMinor > 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor + other.amountMinor, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor - other.amountMinor, currency: currency);
  }

  Money operator *(num factor) {
    return Money((amountMinor * factor).round(), currency: currency);
  }

  Money abs() => Money(amountMinor.abs(), currency: currency);

  Money copyWith({int? amountMinor, String? currency}) {
    return Money(
      amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
    );
  }

  void _assertSameCurrency(Money other) {
    assert(
      currency == other.currency,
      'Cannot operate on $currency and ${other.currency}',
    );
  }

  @override
  List<Object?> get props => [amountMinor, currency];
}
