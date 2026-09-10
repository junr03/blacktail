{ lib }:
{
  select =
    {
      profile,
      entries,
    }:
    map (entry: entry.name) (
      lib.filter (entry: !(entry ? profiles) || lib.elem profile entry.profiles) entries
    );
}
