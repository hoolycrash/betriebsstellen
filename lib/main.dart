import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // For compute

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final _defaultLightColorScheme =
  ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'Dynamic Color',
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _csvData = [];
  List<Map<String, String>> _filteredData = [];
  Timer? _debounce;

  // Filter options for the specific filter chip
  final List<String> _filterOptions = ['ABZ', 'ABZW', 'ANST', 'AWAN', 'BFT', 'BK', 'BK A', 'BK H', 'BUSH', 'BZ', 'CEST', 'DKST', 'DUW', 'EMST', 'ES', 'EST', 'FBKA', 'FUW', 'FWST', 'GKS', 'GP', 'GUW', 'GW', 'KS', 'LGR', 'MUSE', 'NLZ', 'PARK', 'SBK', 'SLST', 'SP', 'ST', 'TP', 'TS', 'UW', 'WERK', 'ÜST', ];
  String? _selectedFilter; // Variable to store the selected filter
  List<String> _types = ['HP', 'BF', 'HST']; // Example types for other filter chips
  String? _selectedType; // Variable to store the selected type

  @override
  void initState() {
    super.initState();
    _loadCSV(); // Load CSV on start
  }

  Future<void> _loadCSV() async {
    final data = await rootBundle.loadString('assets/stations.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter(fieldDelimiter: ';').convert(data);

    final structuredData = await compute(_processCSVData, csvTable);

    setState(() {
      _csvData = structuredData;
      _filteredData = structuredData;
    });
  }

  static List<Map<String, String>> _processCSVData(List<List<dynamic>> csvTable) {
    List<Map<String, String>> structuredData = [];
    for (var i = 1; i < csvTable.length; i++) {
      var row = csvTable[i];
      structuredData.add({
        "RL100-Code": row[1].toString(),
        "RL100-Langname": row[2].toString(),
        "Typ Kurz": row[4].toString(),
        "Niederlassung": row[9].toString(),
        "Betriebszustand": row[6].toString(),
      });
    }
    return structuredData;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        // Standardmäßig zeigen wir alle Daten an
        _filteredData = _csvData;

        // Filter nur anwenden, wenn die Suchanfrage mindestens 2 Zeichen hat oder ein Filter aktiv ist
        if (query.length >= 0 || _selectedFilter != null) {
          final lowerCaseQuery = query.toLowerCase();

          // Filtern nach der Suchanfrage und dem ausgewählten Filter
          _filteredData = _filteredData.where((row) {
            final matchesQuery = row["RL100-Code"]!.toLowerCase().contains(lowerCaseQuery) || row["RL100-Langname"]!.toLowerCase().contains(lowerCaseQuery);
            final matchesFilter = _selectedFilter == null || row["Typ Kurz"] == _selectedFilter; // Filter anwenden
            final matchesType = _selectedType == null || row["Typ Kurz"] == _selectedType; // Typ anwenden

            return matchesQuery && matchesFilter && matchesType; // Nur Zeilen, die alle Bedingungen erfüllen
          }).toList();

          final exactMatches = _filteredData.where((row) =>
          row["RL100-Code"]!.toLowerCase() == lowerCaseQuery ||
              row["RL100-Langname"]!.toLowerCase() == lowerCaseQuery).toList();

          final startMatches = _filteredData.where((row) =>
          !exactMatches.contains(row) &&
              row["RL100-Code"]!.toLowerCase().startsWith(lowerCaseQuery) &&
              row["RL100-Langname"]!.toLowerCase() != lowerCaseQuery).toList();

          final otherMatches = _filteredData.where((row) =>
          !exactMatches.contains(row) &&
              !startMatches.contains(row) &&
              row["RL100-Code"]!.toLowerCase() != lowerCaseQuery &&
              !row["RL100-Code"]!.toLowerCase().startsWith(lowerCaseQuery) &&
              row["RL100-Langname"]!.toLowerCase() != lowerCaseQuery).toList();

          // Kombinieren der exakten Übereinstimmungen und der anderen Übereinstimmungen
          _filteredData = [
            ...exactMatches,
            ...startMatches,
            ...otherMatches,
          ];
        }
      });
    });
  }


  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(  // Hier hinzufügen
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                ..._filterOptions.map((option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      setState(() {
                        _selectedFilter = option; // Update the selected filter
                        _selectedType = null; // Reset the selected type
                        _filterData(); // Filter data by selected filter
                      });
                      Navigator.of(context).pop(); // Close the modal
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }



  void _onDropdownChipSelected(String? selectedType) {
    setState(() {
      _selectedType = selectedType; // Setze den ausgewählten Typ aus dem Dropdown
      _onSearchChanged(_searchController.text); // Trigger für die Suche
    });
  }






  void _filterData() {
    final lowerCaseQuery = _searchController.text.toLowerCase();

    setState(() {
      List<Map<String, String>> exactMatches = [];
      List<Map<String, String>> matchingStart = [];
      List<Map<String, String>> otherMatches = [];

      for (var row in _csvData) {
        final matchesQuery = row["RL100-Code"]!.toLowerCase().contains(lowerCaseQuery) ||
            row["RL100-Langname"]!.toLowerCase().contains(lowerCaseQuery);
        final matchesFilter = _selectedFilter == null || row["Typ Kurz"] == _selectedFilter;
        final matchesType = _selectedType == null || row["Typ Kurz"] == _selectedType;

        if (matchesQuery && matchesFilter && matchesType) {
          if (row["RL100-Langname"]!.toLowerCase() == lowerCaseQuery) {
            exactMatches.add(row);
          } else if (row["RL100-Langname"]!.toLowerCase().startsWith(lowerCaseQuery)) {
            matchingStart.add(row);
          } else {
            otherMatches.add(row);
          }
        }
      }

      // Combine results: exact matches first, then starting matches, then other matches
      _filteredData = [...exactMatches, ...matchingStart, ...otherMatches];
    });
  }





  void _showBottomSheet(Map<String, String> row) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row["RL100-Langname"]!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide.none,
                  verticalInside: BorderSide.none,
                ),
                children: [
                  TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.code),
                          SizedBox(width: 8.0),
                          Text('RIL100-Code:', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(row["RL100-Code"]!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ]),
                  TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.train),
                          SizedBox(width: 8.0),
                          Text('Typ:', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(row["Typ Kurz"]!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ]),
                  TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.apartment),
                          SizedBox(width: 8.0),
                          Text('Niederlassung:', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(row["Niederlassung"]!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ]),
                  TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.build),
                          SizedBox(width: 8.0),
                          Text('Betriebszustand:', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(row["Betriebszustand"]!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: _isSearching ? 120 : kToolbarHeight, // Dynamic height
        title: _isSearching
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true, // Automatically focus and show keyboard
              decoration: InputDecoration(
                hintText: 'Suche...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8.0,
                children: [
                  ..._types.map((type) {
                    return FilterChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedType = type; // Only one chip selected
                            _selectedFilter = null; // Reset dropdown chip
                          } else {
                            _selectedType = null; // Deselect if clicked again
                          }
                          _filterData(); // Filter data based on chip
                        });
                      },
                    );
                  }).toList(),
                  FilterChip(
                    label: Text(_selectedFilter ?? 'Mehr...'),
                    selected: _selectedFilter != null,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          // Nur öffnen, wenn kein Filter gesetzt ist, oder ein neuer Filter ausgewählt werden soll
                          _showFilterOptions(); // Open modal to select a specific filter
                        } else {
                          // Filter abwählen, wenn der Nutzer den Chip abklickt
                          _selectedFilter = null;
                          _filterData(); // Daten erneut filtern
                        }
                      });
                    },
                  ),


                ],
              ),
            ),
          ],
        )
            : const Text('Betriebsstellen'),
      ),
      body: _filteredData.isNotEmpty
          ? ListView.builder(
        itemCount: _filteredData.length,
        itemBuilder: (context, index) {
          final row = _filteredData[index];
          return Card(
            color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.5),
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
            child: ListTile(
              title: Text(
                row["RL100-Langname"]!,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              subtitle: Text(
                row["RL100-Code"]!,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              onTap: () => _showBottomSheet(row),
            ),
          );
        },
      )
          : Center(
        child: Text(
          'Keine Ergebnisse gefunden',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isSearching) {
              _isSearching = false;
              _searchController.clear();
              _filteredData = _csvData; // Reset data to original
              _selectedFilter = null; // Reset the selected filter
              _selectedType = null; // Reset the selected type
            } else {
              _isSearching = true;
            }
          });
        },
        child: Icon(_isSearching ? Icons.close : Icons.search),
      ),
    );
  }
}
