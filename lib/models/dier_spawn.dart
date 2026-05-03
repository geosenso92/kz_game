enum DierZeldzaamheid { normaal, zeldzaam, legendarisch }

class DierSpawn {
  final String id;
  final String naam;
  final DierZeldzaamheid zeldzaamheid;
  final double x;
  final double y;
  bool gevangen;

  DierSpawn({
    required this.id,
    required this.naam,
    required this.zeldzaamheid,
    required this.x,
    required this.y,
    this.gevangen = false,
  });
}
