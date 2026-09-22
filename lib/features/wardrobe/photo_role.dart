/// `garment` is clothing; `tag` is a hangtag photo (never used as cover).
enum ItemPhotoRole {
  garment,
  tag;

  static ItemPhotoRole parse(String raw) {
    return raw == ItemPhotoRole.tag.name ? ItemPhotoRole.tag : ItemPhotoRole.garment;
  }
}
