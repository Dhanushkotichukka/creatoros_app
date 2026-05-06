import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  String _selectedToggle = "All";
  String _selectedFilter = "All";

  // Search logic variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Mock list of storage files mapping to filter categories
  final List<Map<String, dynamic>> _storageFiles = [
    {"name": "app_design_vfinal.fig", "type": "Images", "date": "Oct 28, 2023", "size": "45.2 MB", "location": "Cloud"},
    {"name": "nature_broll.mp4", "type": "Videos", "date": "Oct 26, 2023", "size": "450 MB", "location": "Local"},
    {"name": "profile_pic.png", "type": "Images", "date": "Oct 25, 2023", "size": "1.2 MB", "location": "Local"},
    {"name": "interview_audio.wav", "type": "Sounds", "date": "Oct 22, 2023", "size": "15 MB", "location": "Cloud"},
    {"name": "presentation_draft.pptx", "type": "Notes", "date": "Oct 20, 2023", "size": "12.4 MB", "location": "Cloud"},
    {"name": "workspace_tour.mp4", "type": "Videos", "date": "Oct 18, 2023", "size": "1.2 GB", "location": "Local"},
  ];

  // Dynamic filter getter combining the toggle and row filters
  List<Map<String, dynamic>> get _filteredFiles {
    return _storageFiles.where((f) {
      final matchesToggle = _selectedToggle == "All" || f["location"] == _selectedToggle;
      final matchesFilter = _selectedFilter == "All" || f["type"] == _selectedFilter;
      // Add text matching over the file name string
      final matchesSearch = _searchQuery.isEmpty || f["name"].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesToggle && matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            _buildToggleButtons(c),
            _buildStorageUsageBar(c),
            _buildCategoryTiles(c),
            _buildFilterRow(c),
            Expanded(child: _buildFileList(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 8.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Swap between standard Text title and active TextField based on boolean
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search files...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: c.textSecondary, fontSize: 24, fontWeight: FontWeight.normal),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            )
          else
            Text(
              "Storage",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: c.textPrimary,
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _searchController.clear();
                      _searchQuery = "";
                    } else {
                      _isSearching = true;
                    }
                  });
                },
                color: c.textPrimary,
              ),
              if (!_isSearching) ...[
                IconButton(
                  icon: const Icon(Icons.cloud_sync_outlined),
                  onPressed: () {},
                  color: c.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view_rounded),
                  onPressed: () {},
                  color: c.textPrimary,
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToggleButtons(AppColors c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggles = ["All", "Cloud", "Local"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: toggles.map((toggle) {
            final isSelected = toggle == _selectedToggle;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedToggle = toggle);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isSelected ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      toggle,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? c.textPrimary : c.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStorageUsageBar(AppColors c) {
    final isCloud = _selectedToggle == "Cloud";
    final isLocal = _selectedToggle == "Local";
    final tagText = _selectedToggle == "All" ? "cloud/local" : _selectedToggle;

    // Dynamic static stats
    final usedGb = isCloud ? 15.0 : isLocal ? 10.0 : 25.0;
    final totalGb = isCloud ? 50.0 : isLocal ? 30.0 : 80.0;
    final freeGb = totalGb - usedGb;
    final ratio = usedGb / totalGb;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The floating 'cloud/local' tag from the sketch
            Text(
              tagText,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.textPrimary),
            ),
            const SizedBox(height: 4),
            // The striped bar representation
            Container(
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: c.textPrimary, width: 2),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: (ratio * 100).toInt(),
                      child: Container(
                        // Base gradient, simplified for performance over stripes
                        decoration: BoxDecoration(
                          color: c.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - ratio) * 100).toInt(),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // The precise label from the sketch text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${usedGb.toInt()} gb full",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c.textPrimary),
                ),
                Text(
                  "${freeGb.toInt()} free",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTiles(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCategoryCard("Videos", Icons.play_circle_fill, Colors.orangeAccent, c),
          _buildCategoryCard("Images", Icons.photo_library, Colors.blueAccent, c),
          _buildCategoryCard("Voices", Icons.mic, Colors.green, c),
          _buildCategoryCard("Notes", Icons.description, Colors.purpleAccent, c),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color badgeColor, AppColors c) {
    final bool isActive = _selectedFilter == title || (_selectedFilter == "Sounds" && title == "Voices");
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final target = title == "Voices" ? "Sounds" : title;
          setState(() => _selectedFilter = target);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isActive ? c.primary : c.border, 
              width: 1.5,
            ),
          ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? c.primary : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildFilterRow(AppColors c) {
    final filters = ["All", "Videos", "Images", "Sounds"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : c.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              backgroundColor: c.surface,
              selectedColor: c.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
                side: BorderSide(
                  color: isSelected ? c.primary : c.border,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileList(AppColors c) {
    final filtered = _filteredFiles;

    if (filtered.isEmpty) {
      return Center(child: Text("No files found.", style: TextStyle(color: c.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildFileItem(index, filtered[index], c);
      },
    );
  }

  Widget _buildFileItem(int index, Map<String, dynamic> file, AppColors c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Index Number
          SizedBox(
            width: 28,
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: c.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? c.primary.withOpacity(0.2) : const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              switch (file["type"]) {
                "Videos" => Icons.play_circle_fill,
                "Images" => Icons.photo_library,
                "Sounds" => Icons.mic,
                _ => Icons.insert_drive_file_rounded,
              },
              color: c.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // File Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file["name"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "${file["date"]} • ${file["size"]}",
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                )
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                color: c.textSecondary,
                iconSize: 22,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Downloading '${file["name"]}'..."),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                splashRadius: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: c.textSecondary,
                iconSize: 22,
                onPressed: () {
                  setState(() {
                    _storageFiles.remove(file); 
                  });
                },
                padding: EdgeInsets.zero,
                splashRadius: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: c.textSecondary,
                iconSize: 22,
                onPressed: () {},
                padding: EdgeInsets.zero,
                splashRadius: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          )
        ],
      ),
    );
  }
}
