import 'dart:io';

class Search {
  Search(String pathToFile) : file = File(pathToFile);

  File file;

  bool search(String searchTerm) {
    final lines = file.readAsLinesSync();

    return searchLines(searchTerm, lines);
  }

  bool searchLines(String searchTerm, List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(searchTerm)) {
        return true;
      }
    }
    return false;
  }
}
