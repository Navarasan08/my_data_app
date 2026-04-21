import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:my_data_app/src/land/model/land_model.dart';
import 'package:my_data_app/src/land/cubit/land_cubit.dart';
import 'package:my_data_app/src/land/cubit/land_state.dart';
import 'package:my_data_app/src/land/land_photo_service.dart';

// ─── 1. LandListPage ─────────────────────────────────────────────────────────

class LandListPage extends StatelessWidget {
  const LandListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandCubit, LandState>(
      builder: (context, state) {
        final cubit = context.read<LandCubit>();
        final records = cubit.sortedByFavorite;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Lands'),
            centerTitle: true,
            elevation: 0,
          ),
          body: records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.landscape_rounded,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No land records yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first land',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) => _LandCard(record: records[i]),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newRec = await Navigator.push<LandRecord>(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const AddLandPage(),
                  ),
                ),
              );
              if (newRec != null) cubit.addRecord(newRec);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Land'),
          ),
        );
      },
    );
  }
}

// ─── 2. Land Card ────────────────────────────────────────────────────────────

class _LandCard extends StatelessWidget {
  final LandRecord record;
  const _LandCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandCubit>();
    final color = record.type.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: LandDetailPage(landId: record.id),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Thumbnail: first photo if available, else icon tile
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: record.photoUrls.isNotEmpty
                      ? Image.network(
                          record.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withValues(alpha: 0.15),
                            child:
                                Icon(record.type.icon, size: 22, color: color),
                          ),
                        )
                      : Container(
                          color: color.withValues(alpha: 0.15),
                          child:
                              Icon(record.type.icon, size: 28, color: color),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (record.isFavorite)
                          Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber[700]),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.type.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (record.locationShort.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.locationShort,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (record.areaDisplay.isNotEmpty)
                          Text(
                            record.areaDisplay,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        if (record.askingPrice != null) ...[
                          if (record.areaDisplay.isNotEmpty)
                            Text('  ·  ',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400])),
                          Text(
                            '₹${NumberFormat.compact().format(record.askingPrice)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                        if (record.photoUrls.isNotEmpty) ...[
                          const Spacer(),
                          Icon(Icons.photo_library_rounded,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 2),
                          Text(
                            '${record.photoUrls.length}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 18),
                onPressed: () => SharePlus.instance
                    .share(ShareParams(text: record.toShareableText())),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3. Land Detail Page ─────────────────────────────────────────────────────

class LandDetailPage extends StatelessWidget {
  final String landId;
  const LandDetailPage({Key? key, required this.landId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandCubit, LandState>(
      builder: (context, state) {
        final cubit = context.read<LandCubit>();
        final record = cubit.getById(landId);
        if (record == null) {
          return const Scaffold(
            body: Center(child: Text('Land not found')),
          );
        }

        final sections = record.asShareSections();

        return Scaffold(
          appBar: AppBar(
            title: Text(record.name),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  record.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: record.isFavorite ? Colors.amber[700] : null,
                ),
                tooltip: 'Favorite',
                onPressed: () => cubit.toggleFavorite(record.id),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share all',
                onPressed: () => SharePlus.instance
                    .share(ShareParams(text: record.toShareableText())),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () async {
                  final edited = await Navigator.push<LandRecord>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: AddLandPage(existing: record),
                      ),
                    ),
                  );
                  if (edited != null) cubit.updateRecord(edited);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Land'),
                      content: Text('Delete "${record.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    cubit.deleteRecord(record.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                children: [
                  // Hero photo carousel
                  _PhotoCarousel(record: record),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type + area chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              icon: record.type.icon,
                              label: record.type.label,
                              color: record.type.color,
                            ),
                            if (record.areaDisplay.isNotEmpty)
                              _Chip(
                                icon: Icons.square_foot_rounded,
                                label: record.areaDisplay,
                                color: Colors.blueGrey,
                              ),
                            if (record.locationShort.isNotEmpty)
                              _Chip(
                                icon: Icons.location_on_rounded,
                                label: record.locationShort,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        if (record.askingPrice != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sell_rounded,
                                    size: 18, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Asking Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[800],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(record.askingPrice)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (record.description != null &&
                            record.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            record.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (record.mapsUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: record.mapsUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Maps link copied'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Icon(Icons.map_rounded,
                                    size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'Open in Maps',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // Sections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: sections.map((s) => _DetailSection(
                            title: s.key,
                            fields: s.value,
                          )).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Share selected fields
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share selected fields'),
                    onPressed: () =>
                        _shareSelected(context, record, sections),
                  ),
                  const SizedBox(height: 8),

                  // Timestamps
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Updated ${DateFormat('MMM d, yyyy').format(record.updatedAt)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareSelected(
    BuildContext context,
    LandRecord record,
    List<MapEntry<String, Map<String, String>>> sections,
  ) {
    final Set<String> selected = {};
    for (final s in sections) {
      for (final k in s.value.keys) {
        selected.add('${s.key} : $k');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scroll) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select fields to share',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: sections.expand((s) {
                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            s.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...s.value.entries.map((e) {
                          final flatKey = '${s.key} : ${e.key}';
                          final checked = selected.contains(flatKey);
                          return CheckboxListTile(
                            dense: true,
                            value: checked,
                            title: Text(e.key),
                            subtitle: Text(
                              e.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600]),
                            ),
                            onChanged: (v) {
                              setSt(() {
                                if (v == true) {
                                  selected.add(flatKey);
                                } else {
                                  selected.remove(flatKey);
                                }
                              });
                            },
                          );
                        }),
                      ];
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selected.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  SharePlus.instance.share(
                                    ShareParams(
                                      text: record.toShareableText(
                                          selectedKeys: selected),
                                    ),
                                  );
                                },
                          icon:
                              const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Map<String, String> fields;

  const _DetailSection({required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...fields.entries.map((e) => _FieldRow(label: e.key, value: e.value)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $label'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      onLongPress: () =>
          SharePlus.instance.share(ShareParams(text: '$label: $value')),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.content_copy_rounded,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Carousel ──────────────────────────────────────────────────────────

class _PhotoCarousel extends StatefulWidget {
  final LandRecord record;
  const _PhotoCarousel({required this.record});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.record.photoUrls;
    final color = widget.record.type.color;

    if (urls.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Center(
          child: Icon(widget.record.type.icon,
              size: 56, color: color.withValues(alpha: 0.6)),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: urls.length,
            itemBuilder: (ctx, i) {
              return GestureDetector(
                onTap: () => _openFullscreen(context, urls, i),
                child: Image.network(
                  urls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image_rounded,
                        size: 40, color: Colors.grey[400]),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              );
            },
          ),
          // Page indicator
          if (urls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = _index == i;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          // Counter badge
          if (urls.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_index + 1}/${urls.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openFullscreen(
      BuildContext context, List<String> urls, int initial) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenGallery(urls: urls, initialIndex: initial),
    ));
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullscreenGallery({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (ctx, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Small Chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4. Add/Edit Land Page ───────────────────────────────────────────────────

class AddLandPage extends StatefulWidget {
  final LandRecord? existing;

  const AddLandPage({Key? key, this.existing}) : super(key: key);

  @override
  State<AddLandPage> createState() => _AddLandPageState();
}

class _AddLandPageState extends State<AddLandPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _askingPrice = TextEditingController();
  final _surveyNumber = TextEditingController();
  final _subDivision = TextEditingController();
  final _pattaNumber = TextEditingController();
  final _area = TextEditingController();

  // Photos
  late final String _landId;
  late final LandPhotoService _photoService;
  List<String> _photoUrls = [];
  bool _uploadingPhotos = false;

  final _addressLine = TextEditingController();
  final _village = TextEditingController();
  final _taluka = TextEditingController();
  final _district = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _landmark = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  final _ownerName = TextEditingController();
  final _ownerContact = TextEditingController();
  final _coOwners = TextEditingController();

  final _purchasePrice = TextEditingController();
  final _sellerName = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _registrarOffice = TextEditingController();
  final _stampDuty = TextEditingController();
  final _registrationFee = TextEditingController();

  final _currentMarketValue = TextEditingController();
  final _guidelineValue = TextEditingController();

  final _boundaryNorth = TextEditingController();
  final _boundarySouth = TextEditingController();
  final _boundaryEast = TextEditingController();
  final _boundaryWest = TextEditingController();

  final _propertyTaxNumber = TextEditingController();
  final _encumbranceStatus = TextEditingController();
  final _ecNumber = TextEditingController();
  final _documentsAvailable = TextEditingController();
  final _notes = TextEditingController();

  LandType _type = LandType.residentialPlot;
  AreaUnit _areaUnit = AreaUnit.sqft;
  DateTime? _purchaseDate;
  DateTime? _registrationDate;
  DateTime? _lastTaxPaidDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _landId = widget.existing?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    // Use a shared uid from FirebaseAuth for photo storage paths
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    _photoService = LandPhotoService(uid: uid);

    final e = widget.existing;
    if (e == null) return;
    _name.text = e.name;
    _description.text = e.description ?? '';
    _askingPrice.text = e.askingPrice?.toString() ?? '';
    _photoUrls = List<String>.from(e.photoUrls);
    _type = e.type;
    _surveyNumber.text = e.surveyNumber ?? '';
    _subDivision.text = e.subDivision ?? '';
    _pattaNumber.text = e.pattaNumber ?? '';
    _area.text = e.areaValue?.toString() ?? '';
    _areaUnit = e.areaUnit;

    _addressLine.text = e.addressLine ?? '';
    _village.text = e.village ?? '';
    _taluka.text = e.taluka ?? '';
    _district.text = e.district ?? '';
    _state.text = e.state ?? '';
    _pincode.text = e.pincode ?? '';
    _country.text = e.country ?? 'India';
    _landmark.text = e.landmark ?? '';
    _latitude.text = e.latitude ?? '';
    _longitude.text = e.longitude ?? '';

    _ownerName.text = e.ownerName ?? '';
    _ownerContact.text = e.ownerContact ?? '';
    _coOwners.text = e.coOwners ?? '';

    _purchaseDate = e.purchaseDate;
    _purchasePrice.text = e.purchasePrice?.toString() ?? '';
    _sellerName.text = e.sellerName ?? '';
    _registrationNumber.text = e.registrationNumber ?? '';
    _registrationDate = e.registrationDate;
    _registrarOffice.text = e.registrarOffice ?? '';
    _stampDuty.text = e.stampDuty?.toString() ?? '';
    _registrationFee.text = e.registrationFee?.toString() ?? '';

    _currentMarketValue.text = e.currentMarketValue?.toString() ?? '';
    _guidelineValue.text = e.guidelineValue?.toString() ?? '';

    _boundaryNorth.text = e.boundaryNorth ?? '';
    _boundarySouth.text = e.boundarySouth ?? '';
    _boundaryEast.text = e.boundaryEast ?? '';
    _boundaryWest.text = e.boundaryWest ?? '';

    _propertyTaxNumber.text = e.propertyTaxNumber ?? '';
    _lastTaxPaidDate = e.lastTaxPaidDate;
    _encumbranceStatus.text = e.encumbranceStatus ?? '';
    _ecNumber.text = e.ecNumber ?? '';
    _documentsAvailable.text = e.documentsAvailable ?? '';
    _notes.text = e.notes ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _askingPrice,
      _surveyNumber, _subDivision, _pattaNumber, _area,
      _addressLine, _village, _taluka, _district, _state, _pincode,
      _country, _landmark, _latitude, _longitude,
      _ownerName, _ownerContact, _coOwners,
      _purchasePrice, _sellerName, _registrationNumber, _registrarOffice,
      _stampDuty, _registrationFee,
      _currentMarketValue, _guidelineValue,
      _boundaryNorth, _boundarySouth, _boundaryEast, _boundaryWest,
      _propertyTaxNumber, _encumbranceStatus, _ecNumber,
      _documentsAvailable, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _s(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  double? _d(TextEditingController c) => double.tryParse(c.text.trim());

  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pickPhotos() async {
    setState(() => _uploadingPhotos = true);
    try {
      final urls = await _photoService.pickAndUpload(_landId);
      if (urls.isNotEmpty) {
        setState(() => _photoUrls = [..._photoUrls, ...urls]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhotos = false);
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _uploadingPhotos = true);
    try {
      final url = await _photoService.pickFromCameraAndUpload(_landId);
      if (url != null) {
        setState(() => _photoUrls = [..._photoUrls, url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhotos = false);
    }
  }

  Future<void> _removePhoto(String url) async {
    setState(() => _photoUrls = _photoUrls.where((u) => u != url).toList());
    // Best-effort removal from storage
    _photoService.deleteByUrl(url);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final record = LandRecord(
      id: _landId,
      name: _name.text.trim(),
      type: _type,
      isFavorite: widget.existing?.isFavorite ?? false,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      description: _s(_description),
      askingPrice: _d(_askingPrice),
      photoUrls: _photoUrls,
      surveyNumber: _s(_surveyNumber),
      subDivision: _s(_subDivision),
      pattaNumber: _s(_pattaNumber),
      areaValue: _d(_area),
      areaUnit: _areaUnit,
      addressLine: _s(_addressLine),
      village: _s(_village),
      taluka: _s(_taluka),
      district: _s(_district),
      state: _s(_state),
      pincode: _s(_pincode),
      country: _s(_country),
      landmark: _s(_landmark),
      latitude: _s(_latitude),
      longitude: _s(_longitude),
      ownerName: _s(_ownerName),
      ownerContact: _s(_ownerContact),
      coOwners: _s(_coOwners),
      purchaseDate: _purchaseDate,
      purchasePrice: _d(_purchasePrice),
      sellerName: _s(_sellerName),
      registrationNumber: _s(_registrationNumber),
      registrationDate: _registrationDate,
      registrarOffice: _s(_registrarOffice),
      stampDuty: _d(_stampDuty),
      registrationFee: _d(_registrationFee),
      currentMarketValue: _d(_currentMarketValue),
      guidelineValue: _d(_guidelineValue),
      boundaryNorth: _s(_boundaryNorth),
      boundarySouth: _s(_boundarySouth),
      boundaryEast: _s(_boundaryEast),
      boundaryWest: _s(_boundaryWest),
      propertyTaxNumber: _s(_propertyTaxNumber),
      lastTaxPaidDate: _lastTaxPaidDate,
      encumbranceStatus: _s(_encumbranceStatus),
      ecNumber: _s(_ecNumber),
      documentsAvailable: _s(_documentsAvailable),
      notes: _s(_notes),
    );
    Navigator.pop(context, record);
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(t,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            )),
      );

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPhotosPicker() {
    final thumbs = <Widget>[];
    for (final url in _photoUrls) {
      thumbs.add(Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.grey[400]),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Photo'),
                    content: const Text(
                        'Remove this photo? It will also be deleted from storage.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  _removePhoto(url);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ));
    }

    thumbs.add(
      InkWell(
        onTap: _uploadingPhotos ? null : _pickPhotos,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[400]!,
              style: BorderStyle.solid,
            ),
          ),
          child: _uploadingPhotos
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 22, color: Colors.grey[600]),
                    const SizedBox(height: 2),
                    Text(
                      'Gallery',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
        ),
      ),
    );

    thumbs.add(
      InkWell(
        onTap: _uploadingPhotos ? null : _pickFromCamera,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_rounded,
                  size: 22, color: Colors.grey[600]),
              const SizedBox(height: 2),
              Text(
                'Camera',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: thumbs
            .map((w) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: w,
                ))
            .toList(),
      ),
    );
  }

  Widget _dateField(
      String label, DateTime? value, ValueChanged<DateTime?> onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final picked = await _pickDate(value);
          if (picked != null) onPicked(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            suffixIcon: value != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => onPicked(null),
                  )
                : const Icon(Icons.calendar_today_rounded, size: 18),
          ),
          child: Text(
            value != null
                ? DateFormat('EEE, MMM d, yyyy').format(value)
                : 'Not set',
            style: TextStyle(
              fontSize: 14,
              color: value != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Land' : 'Add Land'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('PHOTOS'),
                _buildPhotosPicker(),
                const SizedBox(height: 8),

                _sectionTitle('BASIC'),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name / Label *',
                    hintText: 'e.g. Grandfather\'s farm',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Tell people about this land — what makes it special?',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                _field('Asking Price (₹)', _askingPrice,
                    keyboard: TextInputType.number),
                DropdownButtonFormField<LandType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: LandType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 18, color: t.color),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 10),
                _field('Survey Number', _surveyNumber),
                _field('Sub-division', _subDivision),
                _field('Patta Number', _pattaNumber),
                Row(
                  children: [
                    Expanded(
                      child: _field('Area', _area,
                          keyboard: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField<AreaUnit>(
                          initialValue: _areaUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          items: AreaUnit.values.map((u) {
                            return DropdownMenuItem(
                                value: u, child: Text(u.label));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _areaUnit = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                _sectionTitle('LOCATION'),
                _field('Address Line', _addressLine),
                _field('Village / Area', _village),
                _field('Taluka / Mandal', _taluka),
                _field('District', _district),
                _field('State', _state),
                Row(children: [
                  Expanded(child: _field('PIN Code', _pincode)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('Country', _country)),
                ]),
                _field('Landmark', _landmark),
                Row(children: [
                  Expanded(
                    child: _field('Latitude', _latitude,
                        keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field('Longitude', _longitude,
                        keyboard: TextInputType.number),
                  ),
                ]),

                _sectionTitle('OWNER'),
                _field('Owner Name', _ownerName),
                _field('Owner Contact', _ownerContact,
                    keyboard: TextInputType.phone),
                _field('Co-owners', _coOwners, maxLines: 2),

                _sectionTitle('PURCHASE & REGISTRATION'),
                _dateField('Purchase Date', _purchaseDate,
                    (v) => setState(() => _purchaseDate = v)),
                _field('Purchase Price', _purchasePrice,
                    keyboard: TextInputType.number),
                _field('Seller Name', _sellerName),
                _field('Registration No', _registrationNumber),
                _dateField('Registration Date', _registrationDate,
                    (v) => setState(() => _registrationDate = v)),
                _field('Registrar Office', _registrarOffice),
                Row(children: [
                  Expanded(
                    child: _field('Stamp Duty', _stampDuty,
                        keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field('Registration Fee', _registrationFee,
                        keyboard: TextInputType.number),
                  ),
                ]),

                _sectionTitle('VALUATION'),
                _field('Current Market Value', _currentMarketValue,
                    keyboard: TextInputType.number),
                _field('Guideline Value', _guidelineValue,
                    keyboard: TextInputType.number),

                _sectionTitle('BOUNDARIES'),
                _field('North', _boundaryNorth),
                _field('South', _boundarySouth),
                _field('East', _boundaryEast),
                _field('West', _boundaryWest),

                _sectionTitle('TAX & LEGAL'),
                _field('Property Tax Number', _propertyTaxNumber),
                _dateField('Last Tax Paid Date', _lastTaxPaidDate,
                    (v) => setState(() => _lastTaxPaidDate = v)),
                _field('Encumbrance Status', _encumbranceStatus),
                _field('EC Number', _ecNumber),
                _field('Documents Available', _documentsAvailable,
                    maxLines: 2),

                _sectionTitle('NOTES'),
                _field('Notes', _notes, maxLines: 4),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isEditing ? 'Update Land' : 'Save Land',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
