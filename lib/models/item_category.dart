/// Categories a reported item can belong to.
///
/// [dbValue] must stay in sync with the `item_category` enum in
/// `supabase/migrations`.
enum ItemCategory {
  electronics('electronics', 'Electronics'),
  bags('bags', 'Bags'),
  keys('keys', 'Keys'),
  walletsCards('wallets_cards', 'Wallets & cards'),
  idDocuments('id_documents', 'ID & documents'),
  clothing('clothing', 'Clothing'),
  accessories('accessories', 'Accessories'),
  booksStationery('books_stationery', 'Books & stationery'),
  bottles('bottles', 'Bottles & flasks'),
  other('other', 'Other');

  const ItemCategory(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ItemCategory fromDb(String value) => ItemCategory.values.firstWhere(
    (category) => category.dbValue == value,
    orElse: () => ItemCategory.other,
  );
}
