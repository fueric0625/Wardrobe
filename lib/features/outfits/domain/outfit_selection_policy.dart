/// One clothing item appears once in an outfit. Skipping the step clears the selection.
List<String> toggleOutfitClothing(List<String> ids, String id) {
  if (ids.contains(id)) {
    return [
      for (final existing in ids)
        if (existing != id) existing,
    ];
  }
  return [...ids, id];
}

List<String> clearOutfitClothing() => const [];
