import Lake
open Lake DSL

package LdhHttp where
  -- ld64 in the pinned toolchain emits a __DATA_CONST segment that dyld on macOS 26 and later refuses to load
  -- ("missing SG_READ_ONLY flag"); not creating the segment sidesteps it. GNU ld knows no such flag
  moreLinkArgs := if System.Platform.isOSX then #["-Wl,-no_data_const"] else #[]

@[default_target]
lean_lib LdhHttp

/-- The graph store's answer over a live instance's datasets: see `Main.lean`. -/
@[default_target]
lean_exe «ldh-http» where
  root := `Main
