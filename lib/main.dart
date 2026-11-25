import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await db.load();
  runApp(const CampApp());
}

// ================= APNI DETAILS YAHAN BADLO =================
const campName = 'Cliff Camps, Barot';
const tagline = 'Experience Riverside Bliss';
const siteUrl = 'https://cliff-camps-barot.vercel.app/';
const whatsapp = '918219850117'; // booking messages is number par aayenge
const phoneAshwani = '+918219850117';
const phoneAnit = '+917018955920';
const email = 'cliffcampsbarot@gmail.com';
const address = 'Old Hatchery, Barot - Lohardi Road, Himachal Pradesh';
const maxPerTent = 3; // ek tent mein maximum guests

// Tents - SAMPLE hain (naam, description, price/night, facilities, photo numbers, tag). Asli bharo.
const tents = [
  Tent('Riverside Swiss Tent', 'Sleep to the sound of the river in a cozy Swiss tent right on the bank.', 2500,
      ['River view', 'Comfy bedding', 'Bonfire on request'], [0, 1, 2], tag: 'Most loved'),
  Tent('Cliff View Swiss Tent', 'Wake up to snow views and wild goats on the hills around the camp.', 3000,
      ['Snow view', 'Private sit-out', 'Bonfire on request'], [2, 3, 0], tag: 'Best views'),
  Tent('Garden Swiss Tent', 'A quiet tent away from the path, perfect for a calm and private stay.', 2200,
      ['Quiet corner', 'Comfy bedding', 'Tea on request'], [3, 4, 1]),
];

// Add-ons (naam, price, unit: 'person' = har guest, 'night' = har raat, 'stay' = ek baar). SAMPLE prices.
const addonList = [
  Addon('Bonfire & music', 500, 'night', Icons.local_fire_department),
  Addon('Trout dinner', 450, 'person', Icons.restaurant),
  Addon('Breakfast', 200, 'person', Icons.free_breakfast),
  Addon('Guided nature walk', 300, 'person', Icons.hiking),
];

// Photos. Apni photo ka link ya 'assets/images/tent1.jpg' likh sakte ho
String px(int id) => 'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=900';
final photos = <String>[px(31705302), px(31705293), px(31705292), px(31705291), px(31666058)];

// Coupons: DIRECT5 = 5% off, CAMP10 = 10% off (2+ nights)
int couponPct(String code, int nights) {
  switch (code.trim().toUpperCase()) {
    case 'DIRECT5':
      return 5;
    case 'CAMP10':
      return nights >= 2 ? 10 : 0;
  }
  return 0;
}

// Reviews - SAMPLE hain. Jab asli guests ke reviews mil jaye to inhe badal do.
const reviews = [
  ('Neha & Rahul', 5, 'Fell asleep to the river and woke up to snow views. Pure peace!'),
  ('Aman S.', 5, 'The trout dinner was the highlight. Warm hosts, super clean tents.'),
  ('Priya K.', 4, 'Beautiful spot. Carry warm clothes. Will come back with family.'),
];

const faqs = [
  ('Check-in & check-out time?', 'Check-in 12 PM, check-out 11 AM (sample - apna time likho).'),
  ('How many people in one tent?', 'Maximum $maxPerTent guests per tent. For more guests, book more tents.'),
  ('Is food available?', 'Yes, our in-house chef cooks fresh meals and a trout treat on request.'),
  ('Cancellation policy?', 'Free date change up to 3 days before arrival (sample - apni policy likho).'),
];

const experiences = [
  ('River white noise', 'Fall asleep to the sound of the river.', Icons.waves),
  ('Snow views', 'Wake up to snow-capped mountains.', Icons.ac_unit),
  ('Wild goats', 'Spot wild goats on the hillsides.', Icons.pets),
  ('Trout treat', 'Fresh trout cooked by our in-house chef.', Icons.restaurant),
];
// =============================================================

const green = Color(0xFF0B2A1E);
const leaf = Color(0xFF1F5C3F);
const gold = Color(0xFFE8B04B);
const cream = Color(0xFFF7F3EA);
const soft = [BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 8))];

class Tent {
  final String name, desc, tag;
  final int price;
  final List<String> perks;
  final List<int> pics;
  const Tent(this.name, this.desc, this.price, this.perks, this.pics, {this.tag = ''});
}

class Addon {
  final String name, unit;
  final int price;
  final IconData icon;
  const Addon(this.name, this.price, this.unit, this.icon);
  String get label => unit == 'person' ? '${rs(price)} / guest' : unit == 'night' ? '${rs(price)} / night' : rs(price);
}

// ---------- Saved data (favourites, name, enquiries) ----------

class Db extends ChangeNotifier {
  final Set<int> fav = {};
  String name = '';
  String phone = '';
  final List<Map<String, dynamic>> trips = [];

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('camp_data');
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      fav
        ..clear()
        ..addAll(List<int>.from((m['fav'] ?? []) as List));
      name = (m['name'] ?? '') as String;
      phone = (m['phone'] ?? '') as String;
      trips
        ..clear()
        ..addAll(((m['trips'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('camp_data', jsonEncode({'fav': fav.toList(), 'name': name, 'phone': phone, 'trips': trips}));
    } catch (_) {}
  }

  void toggleFav(int i) {
    if (!fav.remove(i)) fav.add(i);
    notifyListeners();
    _save();
  }

  void remember(String n, String p) {
    name = n;
    phone = p;
    _save();
  }

  void addTrip(Map<String, dynamic> t) {
    trips.insert(0, t);
    notifyListeners();
    _save();
  }

  void removeTrip(int i) {
    trips.removeAt(i);
    notifyListeners();
    _save();
  }
}

final Db db = Db();

final ValueNotifier<int> tab = ValueNotifier<int>(0);
final ValueNotifier<int> chosen = ValueNotifier<int>(0);
final ValueNotifier<String> stayQuery = ValueNotifier<String>('');

// ---------- Helpers ----------

Future<void> open(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

String waLink(String msg) => 'https://wa.me/$whatsapp?text=${Uri.encodeComponent(msg)}';
String waShare(String msg) => 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
String d(DateTime x) => '${x.day}/${x.month}/${x.year}';

String rs(int n) {
  var s = n.toString();
  if (s.length <= 3) return '₹$s';
  var out = s.substring(s.length - 3);
  s = s.substring(0, s.length - 3);
  while (s.length > 2) {
    out = '${s.substring(s.length - 2)},$out';
    s = s.substring(0, s.length - 2);
  }
  if (s.isNotEmpty) out = '$s,$out';
  return '₹$out';
}

(String, IconData) wx(int c) {
  if (c == 0) return ('Clear sky', Icons.wb_sunny);
  if (c <= 3) return ('Partly cloudy', Icons.wb_cloudy);
  if (c == 45 || c == 48) return ('Foggy', Icons.cloud);
  if (c >= 51 && c <= 67) return ('Rain', Icons.grain);
  if (c >= 71 && c <= 77) return ('Snow', Icons.ac_unit);
  if (c >= 80 && c <= 82) return ('Showers', Icons.grain);
  if (c >= 95) return ('Thunderstorm', Icons.flash_on);
  return ('Cloudy', Icons.cloud);
}

InputDecoration deco(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );

void info(BuildContext context, String title, String text) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}

// ---------- Small widgets ----------

class Pic extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const Pic(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [leaf, green], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.landscape, color: Colors.white54, size: 48),
    );
    if (!url.startsWith('http')) {
      return Image.asset(url, fit: fit, errorBuilder: (c, e, s) => fallback);
    }
    return Image.network(
      url,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (c, child, p) => p == null ? child : fallback,
      errorBuilder: (c, e, s) => fallback,
    );
  }
}

String tentPhoto(Tent t, [int k = 0]) => photos[t.pics[k % t.pics.length] % photos.length];

class Brand extends StatelessWidget {
  final double size;
  final bool light;
  const Brand({super.key, this.size = 40, this.light = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: SizedBox(
            width: size,
            height: size,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: gold,
                child: Icon(Icons.holiday_village, color: green, size: size * 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CLIFF CAMPS',
                style: TextStyle(
                    color: light ? Colors.white : green, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: size * 0.34)),
            Text('BAROT · HIMACHAL', style: TextStyle(color: gold, letterSpacing: 1.5, fontSize: size * 0.22)),
          ],
        ),
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? bottom;
  const PageHeader(this.title, {super.key, this.subtitle, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: const BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                const Brand(size: 36),
                const Spacer(),
                IconButton(onPressed: () => open('tel:$phoneAshwani'), icon: const Icon(Icons.call, color: gold)),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.white70)),
            if (bottom != null) ...[const SizedBox(height: 14), bottom!],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: green))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

Widget label(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: green)),
    );

class FavButton extends StatelessWidget {
  final int i;
  const FavButton(this.i, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final on = db.fav.contains(i);
        return GestureDetector(
          onTap: () => db.toggleFav(i),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(on ? Icons.favorite : Icons.favorite_border, color: on ? Colors.red : Colors.grey, size: 20),
          ),
        );
      },
    );
  }
}

class PerkChip extends StatelessWidget {
  final String text;
  const PerkChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 11, color: leaf, fontWeight: FontWeight.w600)),
    );
  }
}

void bookTent(BuildContext context, int i) {
  chosen.value = i;
  tab.value = 3;
  Navigator.of(context).popUntil((r) => r.isFirst);
}

void shareTent(int i) {
  final t = tents[i];
  open(waShare('${t.name} at $campName - ${rs(t.price)}/night, max $maxPerTent guests per tent.\n$siteUrl'));
}

class TentCard extends StatelessWidget {
  final int i;
  const TentCard(this.i, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = tents[i];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TentPage(i))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: soft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(height: 200, width: double.infinity, child: Pic(tentPhoto(t))),
                if (t.tag.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                      child: Text(t.tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                Positioned(top: 8, right: 8, child: FavButton(i)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final p in t.perks) PerkChip(p)]),
                  const SizedBox(height: 10),
                  Text(t.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(rs(t.price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text(' / night', style: TextStyle(color: Colors.black54)),
                      const Spacer(),
                      const Icon(Icons.people_outline, size: 18, color: leaf),
                      const Text(' Max $maxPerTent guests', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 46)),
                        onPressed: () => shareTent(i),
                        child: const Icon(Icons.share, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size(48, 46)),
                          onPressed: () => bookTent(context, i),
                          child: const Text('Enquire / Book'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- App ----------

class CampApp extends StatelessWidget {
  const CampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: campName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: leaf, primary: green, secondary: gold),
        scaffoldBackgroundColor: cream,
        navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Color(0x44E8B04B)),
      ),
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFDDDDDD),
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child),
        ),
      ),
      home: const Root(),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[HomePage(), StayPage(), GalleryPage(), BookPage(), MorePage()];
    return ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, i, _) => Scaffold(
        body: IndexedStack(index: i, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => tab.value = v,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.holiday_village_outlined), selectedIcon: Icon(Icons.holiday_village), label: 'Stay'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Gallery'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Book'),
            NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu_open), label: 'More'),
          ],
        ),
      ),
    );
  }
}

// ---------- Home ----------

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final pc = PageController();
  final q = TextEditingController();
  Timer? t;
  int i = 0;

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!pc.hasClients) return;
      pc.animateToPage((i + 1) % photos.length, duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    t?.cancel();
    pc.dispose();
    q.dispose();
    super.dispose();
  }

  void go() {
    stayQuery.value = q.text.trim();
    tab.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: pc,
              itemCount: photos.length,
              onPageChanged: (v) => setState(() => i = v),
              itemBuilder: (c, k) => Pic(photos[k]),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA0B2A1E), Color(0x220B2A1E), Color(0xF20B2A1E)],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Brand(size: 42),
                    const Spacer(),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                      onPressed: () => open('tel:$phoneAshwani'),
                      icon: const Icon(Icons.call, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(tagline, style: TextStyle(color: Colors.white, fontSize: 34, height: 1.1, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Riverside camping in Swiss tents. Fall asleep to the river, wake to snow views.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                TextField(
                  controller: q,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => go(),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search tents, views, trout...',
                    prefixIcon: const Icon(Icons.search, color: leaf),
                    suffixIcon: IconButton(onPressed: go, icon: const Icon(Icons.arrow_forward, color: leaf)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, minimumSize: const Size(120, 48)),
                      onPressed: () => tab.value = 3,
                      child: const Text('Book now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), minimumSize: const Size(100, 48)),
                      onPressed: () => open(waLink('Hello Cliff Camps, I want to know about availability.')),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key});

  Widget item(IconData icon, String a, String b) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: leaf),
            const SizedBox(height: 4),
            Text(a, style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
            Text(b, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: soft),
      child: Row(
        children: [
          item(Icons.groups_outlined, '$maxPerTent guests', 'per tent'),
          item(Icons.restaurant, 'Trout', 'treat'),
          item(Icons.verified_outlined, 'Book', 'direct'),
        ],
      ),
    );
  }
}

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  String temp = '--';
  String text = 'Loading weather...';
  IconData icon = Icons.cloud_outlined;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      // Barot ke aas-paas ka location (approx)
      final r = await http
          .get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=32.05&longitude=76.80&current=temperature_2m,weather_code'))
          .timeout(const Duration(seconds: 8));
      final c = (jsonDecode(r.body) as Map)['current'] as Map;
      final w = wx((c['weather_code'] as num).toInt());
      if (!mounted) return;
      setState(() {
        temp = '${(c['temperature_2m'] as num).round()}°C';
        text = w.$1;
        icon = w.$2;
      });
    } catch (_) {
      if (mounted) setState(() => text = 'Weather abhi available nahi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [leaf, green]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: soft,
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 38),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Barot right now', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(temp, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Flexible(child: Text(text, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const HeroBanner(),
        Transform.translate(offset: const Offset(0, -28), child: const InfoStrip()),
        const SectionTitle('What makes it special'),
        SizedBox(
          height: 156,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final e in experiences)
                Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [leaf, green], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(backgroundColor: gold, child: Icon(e.$3, color: green)),
                      const Spacer(),
                      Text(e.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(e.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 0), child: WeatherCard()),
        SectionTitle('Our tents', action: 'See all', onAction: () => tab.value = 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [TentCard(0), TentCard(1)]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Book direct & save', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green)),
              const SizedBox(height: 4),
              const Text('Use code DIRECT5 for 5% off, or CAMP10 for 10% off on 2+ nights.', style: TextStyle(color: green)),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => tab.value = 3, child: const Text('Plan my stay')),
            ],
          ),
        ),
        const SectionTitle('Guests say'),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final r in reviews)
                Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: soft),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [for (int s = 0; s < 5; s++) Icon(s < r.$2 ? Icons.star : Icons.star_border, color: gold, size: 18)]),
                      const SizedBox(height: 8),
                      Expanded(child: Text(r.$3, maxLines: 3, overflow: TextOverflow.ellipsis)),
                      Text('- ${r.$1}', style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionTitle('Good to know'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: soft),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final f in faqs)
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedAlignment: Alignment.centerLeft,
                  children: [Text(f.$2, style: const TextStyle(color: Colors.black54))],
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ---------- Stay (search + filters) ----------

class StayPage extends StatefulWidget {
  const StayPage({super.key});

  @override
  State<StayPage> createState() => _StayPageState();
}

class _StayPageState extends State<StayPage> {
  final ctrl = TextEditingController();
  String sort = 'Recommended';
  bool savedOnly = false;

  void _sync() {
    if (ctrl.text != stayQuery.value) {
      ctrl.text = stayQuery.value;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    stayQuery.addListener(_sync);
  }

  @override
  void dispose() {
    stayQuery.removeListener(_sync);
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final q = ctrl.text.trim().toLowerCase();
        final idx = [for (int i = 0; i < tents.length; i++) i].where((i) {
          final t = tents[i];
          final hay = '${t.name} ${t.desc} ${t.perks.join(' ')} ${t.tag}'.toLowerCase();
          return hay.contains(q) && (!savedOnly || db.fav.contains(i));
        }).toList();
        if (sort == 'Price: low to high') idx.sort((a, b) => tents[a].price - tents[b].price);
        if (sort == 'Price: high to low') idx.sort((a, b) => tents[b].price - tents[a].price);
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            PageHeader(
              'Stay with us',
              subtitle: 'Swiss tents by the river - max $maxPerTent guests each',
              bottom: TextField(
                controller: ctrl,
                onChanged: (v) => stayQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search tents, views, perks...',
                  prefixIcon: const Icon(Icons.search, color: leaf),
                  suffixIcon: ctrl.text.isEmpty
                      ? null
                      : IconButton(onPressed: () => stayQuery.value = '', icon: const Icon(Icons.close, color: Colors.grey)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  for (final s in ['Recommended', 'Price: low to high', 'Price: high to low'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: sort == s,
                        showCheckmark: false,
                        selectedColor: gold,
                        onSelected: (_) => setState(() => sort = s),
                      ),
                    ),
                  FilterChip(
                    avatar: const Icon(Icons.favorite, size: 16, color: Colors.red),
                    label: const Text('Saved'),
                    selected: savedOnly,
                    showCheckmark: false,
                    selectedColor: gold,
                    onSelected: (v) => setState(() => savedOnly = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: idx.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Koi tent nahi mila. Doosra word try karo.')),
                    )
                  : Column(children: [for (final i in idx) TentCard(i)]),
            ),
          ],
        );
      },
    );
  }
}

// ---------- Tent detail ----------

class TentPage extends StatelessWidget {
  final int i;
  const TentPage(this.i, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = tents[i];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: green,
            foregroundColor: Colors.white,
            title: Text(t.name),
            actions: [IconButton(onPressed: () => shareTent(i), icon: const Icon(Icons.share))],
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: t.pics.length,
                itemBuilder: (c, k) => Pic(tentPhoto(t, k)),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(t.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: green))),
                        FavButton(i),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(t.desc, style: const TextStyle(color: Colors.black54, height: 1.4)),
                    label('Highlights'),
                    Wrap(spacing: 8, runSpacing: 8, children: [for (final p in t.perks) PerkChip(p)]),
                    label('Capacity'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        children: [
                          Icon(Icons.groups_outlined, color: leaf),
                          SizedBox(width: 12),
                          Expanded(child: Text('Maximum $maxPerTent guests per tent. For more guests, book additional tents.')),
                        ],
                      ),
                    ),
                    label('Add-ons you can pick'),
                    for (final a in addonList)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: leaf, child: Icon(a.icon, color: Colors.white, size: 20)),
                        title: Text(a.name),
                        trailing: Text(a.label, style: const TextStyle(color: Colors.black54)),
                      ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: soft),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rs(t.price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('per night', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(160, 50)),
                onPressed: () => bookTent(context, i),
                child: const Text('Book this tent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Gallery ----------

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const PageHeader('Gallery', subtitle: 'Tap a photo to zoom'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < photos.length; i++)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Viewer(i))),
                  child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Pic(photos[i])),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class Viewer extends StatelessWidget {
  final int start;
  const Viewer(this.start, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: PageController(initialPage: start),
        itemCount: photos.length,
        itemBuilder: (c, i) => InteractiveViewer(child: Center(child: Pic(photos[i], fit: BoxFit.contain))),
      ),
    );
  }
}

// ---------- Booking ----------

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final name = TextEditingController(text: db.name);
  final phone = TextEditingController(text: db.phone);
  final note = TextEditingController();
  final coupon = TextEditingController();
  String applied = '';
  int tentIdx = chosen.value;
  int guests = 2;
  DateTimeRange? range;
  final Set<int> addons = {};

  void _chosenChanged() => setState(() => tentIdx = chosen.value);

  @override
  void initState() {
    super.initState();
    chosen.addListener(_chosenChanged);
  }

  @override
  void dispose() {
    chosen.removeListener(_chosenChanged);
    name.dispose();
    phone.dispose();
    note.dispose();
    coupon.dispose();
    super.dispose();
  }

  int get nights => range == null ? 0 : range!.end.difference(range!.start).inDays;
  int get tentsNeeded => (guests + maxPerTent - 1) ~/ maxPerTent;

  int get addonTotal {
    var s = 0;
    for (final k in addons) {
      final a = addonList[k];
      s += a.unit == 'person' ? a.price * guests : a.unit == 'night' ? a.price * nights : a.price;
    }
    return s;
  }

  int get base => tents[tentIdx].price * nights * tentsNeeded;
  int get discount => (base + addonTotal) * couponPct(applied, nights) ~/ 100;
  int get total => base + addonTotal - discount;

  Future<void> pickRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final r = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: range,
      helpText: 'Select check-in and check-out',
    );
    if (r != null) setState(() => range = r);
  }

  void applyCoupon() {
    final c = coupon.text.trim().toUpperCase();
    if (couponPct(c, nights == 0 ? 2 : nights) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid coupon code')));
      return;
    }
    setState(() => applied = c);
  }

  void send() {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    if (name.text.trim().isEmpty || digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam aur 10 digit phone number bharo')));
      return;
    }
    if (range == null || nights < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in aur check-out tareekh chuno (kam se kam 1 raat)')));
      return;
    }
    final t = tents[tentIdx];
    final extra = addons.isEmpty ? 'None' : addons.map((k) => addonList[k].name).join(', ');
    final msg = 'Hello Cliff Camps, I would like to book.\n'
        'Name: ${name.text.trim()}\n'
        'Phone: ${phone.text.trim()}\n'
        'Tent: ${t.name} x$tentsNeeded\n'
        'Check-in: ${d(range!.start)}\n'
        'Check-out: ${d(range!.end)} ($nights night${nights > 1 ? 's' : ''})\n'
        'Guests: $guests (max $maxPerTent per tent)\n'
        'Add-ons: $extra\n'
        '${applied.isEmpty ? '' : 'Coupon: $applied\n'}'
        'Estimated total: ${rs(total)}\n'
        'Note: ${note.text.trim()}';
    db.remember(name.text.trim(), phone.text.trim());
    db.addTrip({
      'tent': t.name,
      'from': d(range!.start),
      'to': d(range!.end),
      'nights': nights,
      'guests': guests,
      'tents': tentsNeeded,
      'total': total,
      'msg': msg,
    });
    open(waLink(msg));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry WhatsApp par bhej di. More > My enquiries mein save hai.')));
  }

  Widget kv(String a, String b, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(a, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color))),
            Text(b, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14, color: color)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = tents[tentIdx];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const PageHeader('Book your stay', subtitle: 'Enquiry goes straight to our WhatsApp'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Your details'),
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: deco('Your name', icon: Icons.person_outline)),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: deco('Phone number', icon: Icons.phone_outlined)),
              label('Choose tent'),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int k = 0; k < tents.length; k++)
                      GestureDetector(
                        onTap: () => setState(() => tentIdx = k),
                        child: Container(
                          width: 170,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tentIdx == k ? green : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: tentIdx == k ? gold : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tents[k].name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: tentIdx == k ? Colors.white : green)),
                              const Spacer(),
                              Text('${rs(tents[k].price)} / night', style: TextStyle(color: tentIdx == k ? gold : Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              label('Dates'),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: pickRange,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: leaf),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          range == null ? 'Select check-in & check-out' : '${d(range!.start)}  →  ${d(range!.end)}  ·  $nights night${nights > 1 ? 's' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              label('Guests'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.groups_outlined, color: leaf),
                    const SizedBox(width: 10),
                    const Text('Total guests', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(onPressed: () => setState(() => guests = guests > 1 ? guests - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                    Text('$guests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => setState(() => guests = guests < 15 ? guests + 1 : 15), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tentsNeeded > 1 ? const Color(0x33E8B04B) : const Color(0x221F5C3F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(tentsNeeded > 1 ? Icons.info_outline : Icons.check_circle_outline, color: leaf, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tentsNeeded > 1
                            ? 'Ek tent mein max $maxPerTent guests. $guests guests ke liye $tentsNeeded tents lagenge.'
                            : '1 tent (max $maxPerTent guests per tent).',
                      ),
                    ),
                  ],
                ),
              ),
              label('Add-ons'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int k = 0; k < addonList.length; k++)
                    FilterChip(
                      avatar: Icon(addonList[k].icon, size: 16, color: leaf),
                      label: Text('${addonList[k].name} · ${addonList[k].label}'),
                      selected: addons.contains(k),
                      selectedColor: const Color(0x55E8B04B),
                      onSelected: (v) => setState(() => v ? addons.add(k) : addons.remove(k)),
                    ),
                ],
              ),
              label('Coupon'),
              Row(
                children: [
                  Expanded(child: TextField(controller: coupon, textCapitalization: TextCapitalization.characters, decoration: deco('DIRECT5 / CAMP10', icon: Icons.local_offer_outlined))),
                  const SizedBox(width: 10),
                  FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(80, 54)), onPressed: applyCoupon, child: const Text('Apply')),
                ],
              ),
              if (applied.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('$applied applied', style: const TextStyle(color: leaf, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              TextField(controller: note, maxLines: 2, decoration: deco('Any request (optional)', icon: Icons.edit_note)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: soft),
                child: nights < 1
                    ? const Text('Dates chuno, phir yahan price estimate dikhega.', style: TextStyle(color: Colors.black54))
                    : Column(
                        children: [
                          kv('${rs(t.price)} × $nights night${nights > 1 ? 's' : ''} × $tentsNeeded tent${tentsNeeded > 1 ? 's' : ''}', rs(base)),
                          if (addonTotal > 0) kv('Add-ons', rs(addonTotal)),
                          if (discount > 0) kv('Discount ($applied)', '- ${rs(discount)}', color: leaf),
                          const Divider(),
                          kv('Estimated total', rs(total), bold: true),
                          const Text('Final price WhatsApp par confirm hoga.', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                onPressed: send,
                icon: const Icon(Icons.chat),
                label: const Text('Send enquiry on WhatsApp'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => open('tel:$phoneAshwani'),
                icon: const Icon(Icons.call),
                label: const Text('Call instead'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- More ----------

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Widget tile(IconData icon, String title, String sub, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: soft),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: leaf, child: Icon(icon, color: Colors.white, size: 20)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const PageHeader('More', subtitle: 'Contact, saved tents and your enquiries'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: db,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: green)),
                const SizedBox(height: 10),
                tile(Icons.call, 'Call Ashwani', phoneAshwani, () => open('tel:$phoneAshwani')),
                tile(Icons.call, 'Call Anit', phoneAnit, () => open('tel:$phoneAnit')),
                tile(Icons.chat, 'WhatsApp', 'Chat with us', () => open(waLink('Hello Cliff Camps'))),
                tile(Icons.mail_outline, 'Email', email, () => open('mailto:$email?subject=Booking%20enquiry')),
                tile(Icons.location_on_outlined, 'Find us', address,
                    () => open('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('Cliff Camps Barot')}')),
                const SizedBox(height: 10),
                const Text('Your stuff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: green)),
                const SizedBox(height: 10),
                tile(Icons.favorite_border, 'Saved tents', '${db.fav.length} saved',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPage()))),
                tile(Icons.receipt_long_outlined, 'My enquiries', '${db.trips.length} sent',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsPage()))),
                const SizedBox(height: 10),
                const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: green)),
                const SizedBox(height: 10),
                tile(Icons.rule, 'House rules', 'Please read before you come',
                    () => info(context, 'House rules', 'Quiet hours after 10 PM.\nNo littering - keep the river clean.\nBonfire only in the camp fire area.\nMax $maxPerTent guests per tent.\n(Sample - apne rules likho.)')),
                tile(Icons.policy_outlined, 'Cancellation policy', 'Dates & refunds',
                    () => info(context, 'Cancellation policy', 'Free date change up to 3 days before arrival.\nAdvance is adjusted in your next stay.\n(Sample - apni policy likho.)')),
                tile(Icons.language, 'Our website', siteUrl, () => open(siteUrl)),
                tile(Icons.share, 'Share this app', 'Send to friends on WhatsApp',
                    () => open(waShare('Stay at $campName - riverside Swiss tents. $siteUrl'))),
                const SizedBox(height: 16),
                const Center(child: Text('$campName · Made with love in Himachal', style: TextStyle(color: Colors.black45, fontSize: 12))),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved tents'), backgroundColor: green, foregroundColor: Colors.white),
      body: ListenableBuilder(
        listenable: db,
        builder: (context, _) {
          final ids = db.fav.toList()..sort();
          if (ids.isEmpty) return const Center(child: Text('Heart dabake tent save karo'));
          return ListView(padding: const EdgeInsets.all(16), children: [for (final i in ids) TentCard(i)]);
        },
      ),
    );
  }
}

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My enquiries'), backgroundColor: green, foregroundColor: Colors.white),
      body: ListenableBuilder(
        listenable: db,
        builder: (context, _) {
          if (db.trips.isEmpty) return const Center(child: Text('Abhi koi enquiry nahi bheji'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (int k = 0; k < db.trips.length; k++)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: soft),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${db.trips[k]['tent']} × ${db.trips[k]['tents']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: green)),
                      const SizedBox(height: 4),
                      Text('${db.trips[k]['from']} → ${db.trips[k]['to']} · ${db.trips[k]['nights']} night(s) · ${db.trips[k]['guests']} guests'),
                      const SizedBox(height: 4),
                      Text('Estimate: ${rs(db.trips[k]['total'] as int)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => open(waLink(db.trips[k]['msg'] as String)),
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Send again'),
                          ),
                          TextButton.icon(
                            onPressed: () => db.removeTrip(k),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
