import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CampApp());
}

// ================= APNI DETAILS YAHAN BADLO =================
const campName = 'Cliff Camps, Barot';
const tagline = 'Experience Riverside Bliss';
const whatsapp = '918219850117'; // booking messages is number par aayenge
const phoneAshwani = '+918219850117';
const phoneAnit = '+917018955920';
const email = 'cliffcampsbarot@gmail.com';
const address = 'Old Hatchery, Barot - Lohardi Road, Himachal Pradesh';

// Tents (naam, description, price per night, kitne log, facilities) - SAMPLE hain, asli bharo
const tents = [
  Tent('Riverside Swiss Tent', 'Sleep to the sound of the river in a cozy Swiss tent on the bank.', 2500, 2, 'River view • Comfy bedding • Bonfire on request'),
  Tent('Family Swiss Tent', 'Spacious tent for families and small groups, with mountain and snow views.', 4000, 4, 'Mountain view • Extra bedding • Bonfire on request'),
  Tent('Cliff View Swiss Tent', 'Wake up to snow views and wild goats on the hills around the camp.', 3000, 2, 'Snow view • Private sit-out • Bonfire on request'),
];

// Photos (abhi placeholder hain). Apni photo ka link ya 'assets/images/tent1.jpg' likh sakte ho
String px(int id) => 'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=900';
final photos = <String>[px(31705302), px(31705293), px(31705292), px(31705291), px(31666058)];
// =============================================================

const green = Color(0xFF0B2A1E);
const leaf = Color(0xFF1F5C3F);
const gold = Color(0xFFE8B04B);
const cream = Color(0xFFF7F3EA);

const experiences = [
  ('River white noise', 'Fall asleep to the sound of the river.', Icons.waves),
  ('Snow views', 'Wake up to snow-capped mountains.', Icons.ac_unit),
  ('Wild goats', 'Spot wild goats on the hillsides.', Icons.pets),
  ('Trout treat', 'Fresh trout cooked by our in-house chef.', Icons.restaurant),
];

class Tent {
  final String name;
  final String desc;
  final int price;
  final int guests;
  final String perks;
  const Tent(this.name, this.desc, this.price, this.guests, this.perks);
}

final ValueNotifier<int> tab = ValueNotifier<int>(0);
final ValueNotifier<int> chosen = ValueNotifier<int>(0);

Future<void> open(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

String waLink(String msg) => 'https://wa.me/$whatsapp?text=${Uri.encodeComponent(msg)}';

Widget heading(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: green)),
    );

// ---------- Photo with fallback ----------

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

// ---------- App ----------

class CampApp extends StatelessWidget {
  const CampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: campName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
        scaffoldBackgroundColor: cream,
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
    const pages = <Widget>[HomePage(), StayPage(), GalleryPage(), BookPage(), ContactPage()];
    return ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, i, _) => Scaffold(
        body: SafeArea(top: i != 0, child: pages[i]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          backgroundColor: Colors.white,
          onDestinationSelected: (v) => tab.value = v,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.holiday_village_outlined), selectedIcon: Icon(Icons.holiday_village), label: 'Stay'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Gallery'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Book'),
            NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Contact'),
          ],
        ),
      ),
    );
  }
}

// ---------- Home ----------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 420,
          child: Stack(
            children: [
              Positioned.fill(child: Pic(photos[0])),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x330B2A1E), Color(0xEE0B2A1E)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('CLIFF CAMPS · BAROT', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Text(tagline, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Riverside camping in Swiss tents at Barot, Himachal Pradesh. Fall asleep to the river, wake to snow views.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
                          onPressed: () => tab.value = 3,
                          child: const Text('Book now'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                          onPressed: () => open('tel:$phoneAshwani'),
                          child: const Text('Call us'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        heading('What makes it special'),
        for (final e in experiences)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: leaf, child: Icon(e.$3, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(e.$2, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        heading('Our tents'),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: TentCard(0)),
        Center(child: TextButton(onPressed: () => tab.value = 1, child: const Text('See all tents'))),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Book direct', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Message us on WhatsApp for dates and best price.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
                onPressed: () => open(waLink('Hello Cliff Camps, I want to know about availability.')),
                icon: const Icon(Icons.chat),
                label: const Text('Chat on WhatsApp'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TentCard extends StatelessWidget {
  final int i;
  const TentCard(this.i, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = tents[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 180, width: double.infinity, child: Pic(photos[i % photos.length])),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green)),
                const SizedBox(height: 4),
                Text(t.perks, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 8),
                Text(t.desc),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('₹${t.price}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text(' / night', style: TextStyle(color: Colors.black54)),
                    const Spacer(),
                    const Icon(Icons.people_outline, size: 18),
                    Text(' Up to ${t.guests}'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      chosen.value = i;
                      tab.value = 3;
                    },
                    child: const Text('Enquire / Book'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Stay ----------

class StayPage extends StatelessWidget {
  const StayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        heading('Stay with us'),
        for (int i = 0; i < tents.length; i++) TentCard(i),
      ],
    );
  }
}

// ---------- Gallery ----------

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        heading('Gallery'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < photos.length; i++)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Viewer(i))),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Pic(photos[i])),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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

// ---------- Booking enquiry (WhatsApp) ----------

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final note = TextEditingController();
  int tentIdx = chosen.value;
  int guests = 2;
  DateTime? from;
  DateTime? to;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    note.dispose();
    super.dispose();
  }

  String d(DateTime? x) => x == null ? 'Select' : '${x.day}/${x.month}/${x.year}';

  Future<void> pick(bool isFrom) async {
    final now = DateTime.now();
    final first = isFrom ? now : (from ?? now).add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: isFrom ? (from ?? first) : (to ?? first),
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      if (isFrom) {
        from = date;
        if (to != null && !to!.isAfter(date)) to = null;
      } else {
        to = date;
      }
    });
  }

  void send() {
    if (name.text.trim().isEmpty || from == null || to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naam, check-in aur check-out tareekh bharo')),
      );
      return;
    }
    final t = tents[tentIdx];
    final msg = 'Hello Cliff Camps, I would like to book.\n'
        'Name: ${name.text.trim()}\n'
        'Phone: ${phone.text.trim()}\n'
        'Tent: ${t.name}\n'
        'Check-in: ${d(from)}\n'
        'Check-out: ${d(to)}\n'
        'Guests: $guests\n'
        'Note: ${note.text.trim()}';
    open(waLink(msg));
  }

  @override
  Widget build(BuildContext context) {
    final nights = (from != null && to != null) ? to!.difference(from!).inDays : 0;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        heading('Book your stay'),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name', filled: true, fillColor: Colors.white)),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', filled: true, fillColor: Colors.white)),
        const SizedBox(height: 14),
        const Text('Choose tent', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < tents.length; i++)
              ChoiceChip(
                label: Text(tents[i].name),
                selected: tentIdx == i,
                showCheckmark: false,
                selectedColor: gold,
                onSelected: (_) => setState(() => tentIdx = i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => pick(true), child: Text('Check-in: ${d(from)}'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => pick(false), child: Text('Check-out: ${d(to)}'))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Guests', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: () => setState(() => guests = guests > 1 ? guests - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
            Text('$guests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => setState(() => guests++), icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
        TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Any request (optional)', filled: true, fillColor: Colors.white)),
        const SizedBox(height: 12),
        if (nights > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Estimate: ₹${tents[tentIdx].price * nights} for $nights night${nights > 1 ? 's' : ''}. Final price WhatsApp par confirm hoga.',
            ),
          ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: send,
          icon: const Icon(Icons.chat),
          label: const Text('Send enquiry on WhatsApp'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ---------- Contact ----------

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Widget row(IconData icon, String title, String sub, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: leaf, child: Icon(icon, color: Colors.white)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sub),
          onTap: onTap,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        heading('Contact us'),
        row(Icons.call, 'Call Ashwani', phoneAshwani, () => open('tel:$phoneAshwani')),
        row(Icons.call, 'Call Anit', phoneAnit, () => open('tel:$phoneAnit')),
        row(Icons.chat, 'WhatsApp', 'Chat with us', () => open(waLink('Hello Cliff Camps'))),
        row(Icons.mail_outline, 'Email', email, () => open('mailto:$email?subject=Booking%20enquiry')),
        row(
          Icons.location_on_outlined,
          'Find us',
          address,
          () => open('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('Cliff Camps Barot')}'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
