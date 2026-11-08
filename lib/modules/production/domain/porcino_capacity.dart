/// Cálculos de capacidad porcina. Puros y sin estado: no guardan registros.
FormatException _invalid(String message) => FormatException(message);

/// Flujo de bandas: de vientres a partos semanales, lechones y espacios.
/// Con 2400 vientres, factor 25, 10 destetados y 4-8-16 semanas resulta en
/// 96 partos/semana, 384 jaulas de maternidad y 960 lechones/semana.
class SwineFlowPlan {
  SwineFlowPlan({
    required this.sows,
    required this.weanedPerLitter,
    this.factor = 25,
    this.maternityWeeks = 4,
    this.nurseryWeeks = 8,
    this.finishingWeeks = 16,
  }) {
    if (sows <= 0 || sows > 100000) {
      throw _invalid('Vientres: entero entre 1 y 100000.');
    }
    if (!factor.isFinite || factor <= 0 || factor > 100) {
      throw _invalid('Factor: número mayor que 0 y hasta 100.');
    }
    if (!weanedPerLitter.isFinite ||
        weanedPerLitter <= 0 ||
        weanedPerLitter > 20) {
      throw _invalid('Destetados por parto: mayor que 0 y hasta 20.');
    }
    for (final weeks in [maternityWeeks, nurseryWeeks, finishingWeeks]) {
      if (weeks < 1 || weeks > 52) {
        throw _invalid('Las semanas de ocupación van de 1 a 52.');
      }
    }
  }

  final int sows;
  final double factor, weanedPerLitter;
  final int maternityWeeks, nurseryWeeks, finishingWeeks;

  double get farrowingsPerWeek => sows / factor;
  double get pigletsPerWeek => farrowingsPerWeek * weanedPerLitter;
  int get maternityCrates => _ceil(farrowingsPerWeek * maternityWeeks);
  int get nurseryPlaces => _ceil(pigletsPerWeek * nurseryWeeks);
  int get finishingPlaces => _ceil(pigletsPerWeek * finishingWeeks);

  static int _ceil(double value) => (value - 1e-9).ceil();
}

/// Capacidad de silo = animales × consumo diario × días de inventario.
class SiloSizing {
  SiloSizing({
    required this.animals,
    required this.kgPerHeadDay,
    required this.inventoryDays,
  }) {
    if (animals <= 0 || animals > 1000000) {
      throw _invalid('Animales: entero positivo.');
    }
    if (!kgPerHeadDay.isFinite || kgPerHeadDay <= 0 || kgPerHeadDay > 30) {
      throw _invalid('Consumo diario: mayor que 0 y hasta 30 kg por cabeza.');
    }
    if (inventoryDays <= 0 || inventoryDays > 365) {
      throw _invalid('Días de inventario: entero de 1 a 365.');
    }
  }

  final int animals, inventoryDays;
  final double kgPerHeadDay;

  double get dailyKg => animals * kgPerHeadDay;
  double get totalKg => dailyKg * inventoryDays;
  double get totalTons => totalKg / 1000;
}

/// Superficie = animales × m² por animal.
class SpaceEstimate {
  SpaceEstimate({required this.animals, required this.m2PerAnimal}) {
    if (animals <= 0 || animals > 1000000) {
      throw _invalid('Animales: entero positivo.');
    }
    if (!m2PerAnimal.isFinite || m2PerAnimal <= 0) {
      throw _invalid('Densidad inválida.');
    }
  }

  final int animals;
  final double m2PerAnimal;

  double get totalM2 => animals * m2PerAnimal;
}
