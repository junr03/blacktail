{ lib }:
{
  select =
    {
      profiles,
      entries,
    }:
    map (entry: entry.name) (
      lib.filter (
        entry: !(entry ? profiles) || lib.any (profile: lib.elem profile entry.profiles) profiles
      ) entries
    );
}
