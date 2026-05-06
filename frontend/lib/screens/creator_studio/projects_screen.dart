import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedPrimaryFilter = "All";
  String _selectedSecondaryFilter = "Projects";

  // Search logic
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Selection mode
  bool _isSelectionMode = false;
  final Set<int> _selectedProjects = {};

  // Mutable list of projects with explicit 'type' mapping to our filter options
  List<Map<String, dynamic>> _allProjects = [
    {"id": 1, "title": "Travel Vlog", "type": "Cloud", "date": "Oct 24, 2023", "size": "450 MB", "duration": "12:30", "edited": "2 hours ago"},
    {"id": 2, "title": "Workspace Tour", "type": "Local", "date": "Oct 22, 2023", "size": "1.2 GB", "duration": "08:15", "edited": "1 day ago"},
    {"id": 3, "title": "Client Presentation", "type": "Draft", "date": "Oct 20, 2023", "size": "250 MB", "duration": "05:00", "edited": "3 days ago"},
    {"id": 4, "title": "Nature B-Roll", "type": "Cloud", "date": "Oct 18, 2023", "size": "3.5 GB", "duration": "25:40", "edited": "1 week ago"},
    {"id": 5, "title": "Short Film Intro", "type": "Local", "date": "Oct 15, 2023", "size": "800 MB", "duration": "02:30", "edited": "2 weeks ago"},
    {"id": 6, "title": "Podcast Ep 12", "type": "Draft", "date": "Oct 10, 2023", "size": "150 MB", "duration": "45:00", "edited": "3 weeks ago"},
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // Load items securely from SharedPreferences on Boot
  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedProjects = prefs.getString('saved_projects');
    if (savedProjects != null) {
      final List<dynamic> decodedList = jsonDecode(savedProjects);
      setState(() {
        _allProjects = List<Map<String, dynamic>>.from(decodedList);
      });
    }
  }

  // Backup our local list stringified anytime a mutation occurs
  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_allProjects);
    await prefs.setString('saved_projects', encodedList);
  }

  // Dynamic getter that computes the currently filtered list of projects based on active state
  List<Map<String, dynamic>> get _filteredProjects {
    return _allProjects.where((p) {
      final matchesPrimary = _selectedPrimaryFilter == "All" || p["type"] == _selectedPrimaryFilter;
      final matchesSearch = _searchQuery.isEmpty || p["title"].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesPrimary && matchesSearch;
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
            _buildPrimaryFilters(c),
            _buildSecondaryFilters(c),
            _buildStatsRow(c),
            Expanded(
              child: _buildProjectList(c),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: _showNewProjectDialog,
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          "New",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomSheet: _isSelectionMode ? _buildSelectionActionBar(c) : null,
    );
  }

  Widget _buildSelectionActionBar(AppColors c) {
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${_selectedProjects.length} Selected", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c.textPrimary.withOpacity(0.8))),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.cloud_upload_outlined, color: c.primary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading selected projects...")));
                    setState(() { _isSelectionMode = false; _selectedProjects.clear(); });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.drive_file_move_outline, color: c.primary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Moving selected projects...")));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                     setState(() {
                       _allProjects.removeWhere((p) => _selectedProjects.contains(p["id"]));
                       _isSelectionMode = false;
                       _selectedProjects.clear();
                       _saveProjects();
                     });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: c.textPrimary),
                  onPressed: () => setState(() { _isSelectionMode = false; _selectedProjects.clear(); }),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showNewProjectDialog() {
    final c = Theme.of(context).extension<AppColors>()!;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController sizeController = TextEditingController();
    String selectedType = "Video";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: c.surface,
              title: Text("Create New Project", style: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: TextStyle(color: c.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Project Name",
                        hintText: "Enter name",
                        labelStyle: TextStyle(color: c.textSecondary),
                        hintStyle: TextStyle(color: c.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: c.surface,
                      style: TextStyle(color: c.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Project Type",
                        labelStyle: TextStyle(color: c.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      items: ["Video", "Image", "Template"].map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sizeController,
                      style: TextStyle(color: c.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Size (Optional)",
                        hintText: "e.g., 250 MB",
                        labelStyle: TextStyle(color: c.textSecondary),
                        hintStyle: TextStyle(color: c.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: c.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final size = sizeController.text.trim().isEmpty ? "0 KB" : sizeController.text.trim();
                    if (name.isNotEmpty) {
                      _addNewProject(name, selectedType, size);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  void _addNewProject(String title, String editorType, String size) {
    setState(() {
      _allProjects.insert(0, {
        "id": DateTime.now().millisecondsSinceEpoch,
        "title": title,
        "type": "Draft",
        "date": _getCurrentDateString(),
        "size": size,
        "duration": "00:00",
        "edited": "Just now",
      });
      _selectedPrimaryFilter = "All";
      _saveProjects();
    });
  }

  void _confirmDelete(Map<String, dynamic> project) {
    final c = Theme.of(context).extension<AppColors>()!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: c.surface,
          title: Text("Delete Project", style: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary)),
          content: Text("Are you sure you want to delete '${project["title"]}'?", style: TextStyle(color: c.textPrimary)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _allProjects.removeWhere((p) => p["id"] == project["id"]);
                  _saveProjects();
                });
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 8.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search projects...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: c.textSecondary, fontSize: 24, fontWeight: FontWeight.normal),
                ),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            )
          else
            Expanded(
              child: Text(
                "projects",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: c.textPrimary),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing projects with cloud...")));
                  },
                  color: c.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening settings menu...")));
                  },
                  color: c.textPrimary,
                ),
              ],
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPrimaryFilters(AppColors c) {
    final filters = ["All", "Cloud", "Local", "Draft"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == _selectedPrimaryFilter;
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
                  setState(() => _selectedPrimaryFilter = filter);
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

  Widget _buildSecondaryFilters(AppColors c) {
    final filters = ["Projects", "Video", "Images", "Templates"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = filter == _selectedSecondaryFilter;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSecondaryFilter = filter);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12.0),
                      padding: const EdgeInsets.only(bottom: 4.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? c.primary : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? c.primary : c.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add Custom Category dialog...")));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.add, size: 20, color: c.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${_filteredProjects.length} Projects",
            style: TextStyle(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sort by Date/Size options...")));
                },
                icon: Icon(Icons.filter_list, size: 18, color: c.textPrimary),
                label: Text("Filter", style: TextStyle(color: c.textPrimary)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) _selectedProjects.clear();
                  });
                },
                icon: Icon(
                  _isSelectionMode ? Icons.close : Icons.check_circle_outline, 
                  size: 18, 
                  color: c.textPrimary
                ),
                label: Text(_isSelectionMode ? "Cancel" : "Select", style: TextStyle(color: c.textPrimary)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProjectList(AppColors c) {
    final filtered = _filteredProjects;

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "No projects found.", 
          style: TextStyle(color: c.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildProjectCard(filtered[index], c);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, AppColors c) {
    final isSelected = _selectedProjects.contains(project["id"]);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedProjects.add(project["id"]);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedProjects.remove(project["id"]);
              if (_selectedProjects.isEmpty) _isSelectionMode = false;
            } else {
              _selectedProjects.add(project["id"]);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening '${project["title"]}' in Editor...")));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? c.primary.withOpacity(0.2) : c.secondary) : c.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
              color: isSelected ? c.primary : c.border, 
              width: isSelected ? 2.0 : 1.0
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Thumbnail
          Container(
            width: 100,
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    'https://picsum.photos/seed/${project["id"] + 100}/200',
                    width: 100,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.landscape, color: c.textSecondary, size: 40);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  project["title"],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6.0),
                Text(
                  "Date: ${project["date"]}",
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                const SizedBox(height: 2.0),
                Text(
                  "Last Edited: ${project["edited"]}",
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _buildSubTag(project["size"], c),
                    const SizedBox(width: 8),
                    _buildSubTag(project["duration"], c),
                  ],
                )
              ],
            ),
          ),
          // Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: c.textSecondary),
            padding: EdgeInsets.zero,
            color: c.surface,
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(project);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Action '$value' clicked")));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Open',
                child: Text("Open", style: TextStyle(color: c.textPrimary)),
              ),
              PopupMenuItem(
                value: 'Rename',
                child: Text("Rename", style: TextStyle(color: c.textPrimary)),
              ),
              PopupMenuItem(
                value: 'Move to Cloud',
                child: Text("Move to Cloud", style: TextStyle(color: c.textPrimary)),
              ),
              PopupMenuItem(
                value: 'Share',
                child: Text("Share", style: TextStyle(color: c.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSubTag(String text, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
