def optimizations [] { ["none", "minimal", "size", "speed", "aggresive"] }
def examples [] { ls --short-names ./examples | each { |e| $e.name } }

export def run-example [
  --entry_dir     (-D): string          = "examples"         # Base folder
  --entry         (-E): string@examples = "full.odin"        # Entry for the build
  --bin_name      (-n): string                               # Name of the binary that will be generated
  --out           (-O): string                               # Output for the build
  --exec          (-e)                                       # Should be executed after the build
  --release       (-r)                                       # Build relese
  --flags         (-F): list<string>                         # Additional flags
  --defines       (-d): list<string>                         # Define boolean flags
  --lint          (-l)                                       # Enable vet flag
  --optimizations (-o): string@optimizations                 # Sets the optimization mode for compilation.
] {
  let distro = (sys host | get name)

  mut args = []

  let cmd = if $exec {
     "run"
  } else {
    "build"
  }
  $args = $args | append $cmd

  let full_entry_path = $entry_dir | path join $entry
  $args = $args | append $full_entry_path
  if ($full_entry_path | path type) == "file" {
    $args = $args | append "-file"
  }

  if not ($out | is-empty) {
    $args = $args | append $"-out:($out)"
  } else {
    mkdir "build"
    let name = if not ($bin_name | is-empty) {
      $bin_name
    } else {
      pwd | path split | last
    }
    let file_ext = match $distro {
      "Windows" => ".exe",
      _ => ".bin",
    }
    let path = $"./build/($name)($file_ext)" | path expand
    $args = $args | append $"-out:($path)"
  }
  
  if not $release {
    $args = $args | append "-debug"
  }
  if $lint {
    $args = $args | append "-vet"
  }
  $args = $args | append (open ./collections.json | each { |c| $"-collection:($c.name)=($c.path | path expand)" })
  if not ($defines | is-empty) {
    $args = $args | append ($defines | each { |d| $"-define:($d)=true"})
  }
  if not ($flags | is-empty) {
    $args = $args | append $flags
  }

  run-external odin ...$args
}
export alias r = run-example

export def clean [] {
  rm -r build
}
export alias c = clean

