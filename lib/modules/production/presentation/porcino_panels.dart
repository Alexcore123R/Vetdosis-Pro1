import 'package:flutter/material.dart';
import '../../../vet_ui/vet_components.dart';
import '../../../vet_ui/vet_theme.dart';
import '../domain/porcino_capacity.dart';
import '../domain/porcino_reference.dart';
import 'growth_panel.dart';

/// Paneles del módulo Porcinos para cada actividad. Cálculos de sesión: no
/// guardan registros de granja ni consultan Supabase.
List<Widget> porcinoPanelsFor(String activity, {required bool showCosts}) {
  const notice = VetNotice(
    text:
        'Cálculos de sesión con valores de referencia de clase. No guardan registros de granja y no son metas de rendimiento.',
    icon: Icons.fact_check_outlined,
  );
  return switch (activity) {
    'Reproducción y gestación' => [
      notice,
      const PorcinoFlowPanel(),
      const _Gap(),
      const PorcinoSiloPanel(
        title: 'Silo para gestación',
        phases: porcinoGestationFeed,
      ),
      const _Gap(),
      const PorcinoReferenceCard(
        title: 'Referencias de reproducción',
        rows: porcinoReproductionReference,
      ),
    ],
    'Maternidad y destete' => [
      notice,
      const PorcinoSpacePanel(
        title: 'Espacio en destete',
        weights: porcinoNurseryWeights,
        icon: Icons.grid_view_rounded,
      ),
      const _Gap(),
      const PorcinoSiloPanel(
        title: 'Silo para maternidad y destete',
        phases: [...porcinoMaternityFeed, ...porcinoNurseryFeed],
      ),
      const _Gap(),
      const PorcinoReferenceCard(
        title: 'Referencias de maternidad y destete',
        rows: porcinoMaternityReference,
      ),
    ],
    'Crecimiento y engorda' => [
      notice,
      GrowthPanel(showCosts: showCosts),
      const _Gap(),
      const PorcinoSpacePanel(
        title: 'Espacio en engorda',
        weights: porcinoFinishingWeights,
        icon: Icons.grid_view_rounded,
      ),
      const _Gap(),
      const PorcinoSiloPanel(
        title: 'Silo para desarrollo y finalización',
        phases: porcinoGrowingFeed,
      ),
      const _Gap(),
      const PorcinoReferenceCard(
        title: 'Referencias de crecimiento y engorda',
        rows: porcinoGrowingReference,
      ),
    ],
    _ => const <Widget>[],
  };
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 16);
}

double _decimal(TextEditingController c, String label) {
  final raw = c.text.trim();
  if (!RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(raw)) {
    throw FormatException('$label: usa números sin separadores de miles.');
  }
  return double.parse(raw.replaceAll(',', '.'));
}

int _whole(TextEditingController c, String label) {
  final value = int.tryParse(c.text.trim());
  if (value == null) throw FormatException('$label: debe ser un número entero.');
  return value;
}

String _fmt(double v, [int decimals = 2]) {
  final fixed = v.toStringAsFixed(decimals);
  if (!fixed.contains('.')) return fixed;
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VetIconBox(icon: icon, accent: VetColors.pink, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.helper,
    this.decimal = false,
  });
  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool decimal;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, helperText: helper),
      onChanged: (_) => onChanged(),
    ),
  );
}

class _Results extends StatelessWidget {
  const _Results(this.rows);
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VetColors.recessed,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VetColors.softShadow),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label, style: textTheme.bodyMedium)),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Vientres → partos por semana, lechones destetados y espacios por etapa.
class PorcinoFlowPanel extends StatefulWidget {
  const PorcinoFlowPanel({super.key});
  @override
  State<PorcinoFlowPanel> createState() => _PorcinoFlowPanelState();
}

class _PorcinoFlowPanelState extends State<PorcinoFlowPanel> {
  final sows = TextEditingController();
  final weaned = TextEditingController();
  final factor = TextEditingController(text: '25');
  final maternityWeeks = TextEditingController(text: '4');
  final nurseryWeeks = TextEditingController(text: '8');
  final finishingWeeks = TextEditingController(text: '16');
  SwineFlowPlan? result;
  String? error;

  @override
  void dispose() {
    for (final c in [
      sows,
      weaned,
      factor,
      maternityWeeks,
      nurseryWeeks,
      finishingWeeks,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void reset() => setState(() {
    result = null;
    error = null;
  });

  void example() {
    sows.text = '2400';
    weaned.text = '10';
    factor.text = '25';
    maternityWeeks.text = '4';
    nurseryWeeks.text = '8';
    finishingWeeks.text = '16';
    calculate();
  }

  void calculate() {
    setState(() {
      result = null;
      error = null;
      try {
        result = SwineFlowPlan(
          sows: _whole(sows, 'Vientres'),
          weanedPerLitter: _decimal(weaned, 'Destetados por parto'),
          factor: _decimal(factor, 'Factor'),
          maternityWeeks: _whole(maternityWeeks, 'Semanas en maternidad'),
          nurseryWeeks: _whole(nurseryWeeks, 'Semanas en destete'),
          finishingWeeks: _whole(finishingWeeks, 'Semanas en engorda'),
        );
      } on FormatException catch (e) {
        error = e.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    return VetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.account_tree_outlined,
            title: 'Flujo de bandas y capacidad',
            subtitle: 'De vientres a partos por semana, lechones y espacios.',
          ),
          _Field(
            controller: sows,
            label: 'Vientres productivos',
            onChanged: reset,
          ),
          _Field(
            controller: weaned,
            label: 'Lechones destetados por parto',
            decimal: true,
            helper: 'Clase: 9.0 promedio · 10.0 Top 10 %',
            onChanged: reset,
          ),
          _Field(
            controller: factor,
            label: 'Factor (vientres por parto semanal)',
            decimal: true,
            helper: 'Sistema simple de clase: 25',
            onChanged: reset,
          ),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: maternityWeeks,
                  label: 'Sem. maternidad',
                  onChanged: reset,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  controller: nurseryWeeks,
                  label: 'Sem. destete',
                  onChanged: reset,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  controller: finishingWeeks,
                  label: 'Sem. engorda',
                  onChanged: reset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VetActionButton(
            icon: Icons.calculate_outlined,
            label: 'Calcular flujo',
            onPressed: calculate,
          ),
          TextButton(
            onPressed: example,
            child: const Text('Usar ejemplo Modelo 2400'),
          ),
          if (error != null)
            VetNotice(
              text: error!,
              icon: Icons.error_outline,
              kind: VetBadgeKind.danger,
            ),
          if (r != null) ...[
            _Results([
              ('Partos por semana', _fmt(r.farrowingsPerWeek)),
              ('Lechones destetados por semana', _fmt(r.pigletsPerWeek, 1)),
              ('Jaulas de maternidad', '${r.maternityCrates}'),
              ('Lugares de destete', '${r.nurseryPlaces}'),
              ('Lugares de engorda', '${r.finishingPlaces}'),
            ]),
            const SizedBox(height: 10),
            Text(
              'Procedimiento: partos/semana = vientres ÷ factor; lechones/semana = partos × destetados por parto; espacios = lechones/semana × semanas de ocupación (la semana «+1» de limpieza va incluida en cada cifra).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Capacidad de silo = animales × consumo diario × días de inventario.
class PorcinoSiloPanel extends StatefulWidget {
  const PorcinoSiloPanel({
    super.key,
    required this.title,
    required this.phases,
  });
  final String title;
  final List<PorcinoFeedPhase> phases;
  @override
  State<PorcinoSiloPanel> createState() => _PorcinoSiloPanelState();
}

class _PorcinoSiloPanelState extends State<PorcinoSiloPanel> {
  final animals = TextEditingController();
  final days = TextEditingController();
  late final consumption = TextEditingController(
    text: _fmt(widget.phases.first.kgPerHeadDay, 1),
  );
  int phase = 0;
  SiloSizing? result;
  String? error;

  @override
  void dispose() {
    animals.dispose();
    days.dispose();
    consumption.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    result = null;
    error = null;
  });

  void calculate() {
    setState(() {
      result = null;
      error = null;
      try {
        result = SiloSizing(
          animals: _whole(animals, 'Animales'),
          kgPerHeadDay: _decimal(consumption, 'Consumo diario'),
          inventoryDays: _whole(days, 'Días de inventario'),
        );
      } on FormatException catch (e) {
        error = e.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    return VetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.inventory_2_outlined,
            title: widget.title,
            subtitle:
                'Animales × consumo diario × días de inventario deseado.',
          ),
          if (widget.phases.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, p) in widget.phases.indexed)
                    ChoiceChip(
                      label: Text(p.name),
                      selected: phase == i,
                      onSelected: (_) => setState(() {
                        phase = i;
                        consumption.text = _fmt(p.kgPerHeadDay, 1);
                        result = null;
                        error = null;
                      }),
                    ),
                ],
              ),
            ),
          _Field(controller: animals, label: 'Animales', onChanged: reset),
          _Field(
            controller: consumption,
            label: 'Consumo diario (kg/cabeza/día)',
            decimal: true,
            helper:
                'Referencia de clase para ${widget.phases[phase].name.toLowerCase()}: ${_fmt(widget.phases[phase].kgPerHeadDay, 1)}. Edítalo con el dato de tu granja.',
            onChanged: reset,
          ),
          _Field(
            controller: days,
            label: 'Días de inventario deseado',
            onChanged: reset,
          ),
          const SizedBox(height: 8),
          VetActionButton(
            icon: Icons.calculate_outlined,
            label: 'Calcular silo',
            onPressed: calculate,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: VetNotice(
                text: error!,
                icon: Icons.error_outline,
                kind: VetBadgeKind.danger,
              ),
            ),
          if (r != null)
            _Results([
              ('Alimento por día', '${_fmt(r.dailyKg, 1)} kg'),
              ('Capacidad requerida', '${_fmt(r.totalKg, 0)} kg'),
              ('Equivale a', '${_fmt(r.totalTons, 2)} t'),
            ]),
        ],
      ),
    );
  }
}

/// Superficie por animal según peso y tipo de piso (tabla de clase, Gonyou 2006).
class PorcinoSpacePanel extends StatefulWidget {
  const PorcinoSpacePanel({
    super.key,
    required this.title,
    required this.weights,
    required this.icon,
  });
  final String title;
  final List<int> weights;
  final IconData icon;
  @override
  State<PorcinoSpacePanel> createState() => _PorcinoSpacePanelState();
}

class _PorcinoSpacePanelState extends State<PorcinoSpacePanel> {
  final animals = TextEditingController();
  int weightIndex = 0;
  PorcinoFloor floor = PorcinoFloor.partial;
  SpaceEstimate? result;
  String? error;

  @override
  void dispose() {
    animals.dispose();
    super.dispose();
  }

  double get density =>
      porcinoSpaceM2[widget.weights[weightIndex]]![floor]!;

  void reset() => setState(() {
    result = null;
    error = null;
  });

  void calculate() {
    setState(() {
      result = null;
      error = null;
      try {
        result = SpaceEstimate(
          animals: _whole(animals, 'Animales'),
          m2PerAnimal: density,
        );
      } on FormatException catch (e) {
        error = e.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final textTheme = Theme.of(context).textTheme;
    return VetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: widget.icon,
            title: widget.title,
            subtitle: 'Superficie según peso del animal y tipo de piso.',
          ),
          Text('Peso del animal', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, w) in widget.weights.indexed)
                ChoiceChip(
                  label: Text('$w kg'),
                  selected: weightIndex == i,
                  onSelected: (_) => setState(() {
                    weightIndex = i;
                    result = null;
                    error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tipo de piso', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in PorcinoFloor.values)
                ChoiceChip(
                  label: Text('${f.label} (k=${f.k})'),
                  selected: floor == f,
                  onSelected: (_) => setState(() {
                    floor = f;
                    result = null;
                    error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _Field(
            controller: animals,
            label: 'Animales en el corral o sala',
            helper: 'Densidad de clase: ${_fmt(density)} m² por animal',
            onChanged: reset,
          ),
          const SizedBox(height: 4),
          VetActionButton(
            icon: Icons.calculate_outlined,
            label: 'Calcular superficie',
            onPressed: calculate,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: VetNotice(
                text: error!,
                icon: Icons.error_outline,
                kind: VetBadgeKind.danger,
              ),
            ),
          if (r != null)
            _Results([
              ('Densidad usada', '${_fmt(r.m2PerAnimal)} m²/animal'),
              ('Superficie total', '${_fmt(r.totalM2, 1)} m²'),
            ]),
        ],
      ),
    );
  }
}

/// Referencias de clase, con la cita pegada a cada dato.
///
/// Usa el componente compartido VetReferenceCard para que esta tarjeta se vea
/// y se lea igual que las de cualquier otro modulo. Una fila con varias
/// referencias las muestra todas con su fuente; una fila con una sola hereda
/// la cita del bloque.
class PorcinoReferenceCard extends StatelessWidget {
  const PorcinoReferenceCard({
    super.key,
    required this.title,
    required this.rows,
  });
  final String title;
  final List<PorcinoReferenceRow> rows;
  @override
  Widget build(BuildContext context) => VetReferenceCard(
    title: title,
    badge: 'Referencia de clase',
    rows: [
      for (final row in rows)
        VetReferenceRow(
          label: row.label,
          note: row.note,
          values:
              row.referencias ??
              [VetReferenceValue(row.value, source: porcinoReferenceSource)],
        ),
    ],
  );
}
