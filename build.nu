def optimizations [] { ["none", "minimal", "size", "speed", "aggresive"] }

export def run [
  --entry_dir     (-D): string = "examples"                  # Base folder
  --entry         (-E): string = "full.odin"           # Entry for the build
  --bin_name      (-n): string                               # Name of the binary that will be generated
  --out           (-O): string                               # Output for the build
  --exec          (-e)                                       # Should be executed after the build
  --release       (-r)                                       # Build relese
  --flags         (-F): string                               # Additional flags
  --lint          (-l)                                       # Enable vet flag
  --optimizations (-o): string@optimizations                 # Sets the optimization mode for compilation.
] {
  let distro = (sys host | get name)

  let args = []

  let args = if $exec {
    $args | append "run"
  } else {
    $args | append "build"
  }

  let full_entry_path = $entry_dir | path join $entry
  let args = $args | append $full_entry_path
  let args = if ($full_entry_path | path type) == "file" {
    $args | append "-file"
  } else {
    $args
  }

  let args = if not ($out | is-empty) {
    $args | append $"-out:($out)"
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
    $args | append $"-out:($path)"
  }
  
  let args = if $release {
    $args
  } else {
    $args | append "-debug"
  }
  let args = if $lint {
    $args | append "-vet"
  } else {
    $args
  }
  let args = $args | append (nopen ./collections.json | each { |c| $"-collection:($c.name)=($c.path | path expand)" })
  let args = if not ($flags | is-empty) {
    $args | append $flags
  } else {
    $args
  }

  run-external odin ...$args
}
export alias r = run

export def clean [] {
  rm -r build
}
export alias c = clean

